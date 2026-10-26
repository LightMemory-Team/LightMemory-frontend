// App shell（非遊戲畫面）無障礙檢查：登入流程、AuthGate、主畫面導覽、首頁、
// 遊戲首頁、設定、通知、社群貼文卡片。
//
// 用 Flutter 內建的四項 guideline（見 a11y_check.dart）檢查每個畫面，
// 預設只收集違規、印出報告、寫到 build/a11y_report/app_shell.txt，不會讓測試失敗。
// 要讓違規直接失敗：flutter test test/accessibility/app_shell_a11y_test.dart --dart-define=A11Y_STRICT=true
//
// 不在這份檢查範圍：_widget_gallery_screen、儀表板、聲影日記、各遊戲的遊玩畫面。
//
// 檢查矩陣：
// - 設定／遊戲首頁／首頁／通知：淺色、深色、高對比、深色＋高對比
// - 設定／遊戲首頁：另外各跑「系統字級 1.3 倍」與「App 內字級最大（level 5）」
// - 手機尺寸 360x780 直向

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/app_settings.dart';
import 'package:light_memory/features/auth/pages/auth_gate.dart';
import 'package:light_memory/features/auth/pages/identity_select_page.dart';
import 'package:light_memory/features/auth/pages/login_page.dart';
import 'package:light_memory/features/auth/pages/register_page.dart';
import 'package:light_memory/features/auth/pages/tutorial_intro_page.dart';
import 'package:light_memory/features/auth/pages/welcome_page.dart';
import 'package:light_memory/features/social/models/post_model.dart';
import 'package:light_memory/features/social/widgets/post_card.dart';
import 'package:light_memory/screens/game_home_screen.dart';
import 'package:light_memory/screens/home_screen.dart';
import 'package:light_memory/screens/main_screen.dart';
import 'package:light_memory/screens/notification_screen.dart';
import 'package:light_memory/screens/settings_screen.dart';
import 'package:light_memory/theme/app_theme.dart';

import 'a11y_check.dart';

// ───────────────────────── 共用工具 ─────────────────────────

final a11y = A11yReport('app_shell');

/// 主題變體：淺色／深色／高對比／深色＋高對比
const _themeVariants = <(String, bool, bool)>[
  ('淺色', false, false),
  ('深色', true, false),
  ('高對比', false, true),
  ('深色+高對比', true, true),
];

void _applySettings({bool dark = false, bool highContrast = false, int level = 2}) {
  AppSettings.isDarkMode.value = dark;
  AppSettings.isHighContrast.value = highContrast;
  AppSettings.fontSizeLevel.value = level;
  AppSettings.unreadNotificationCount.value = 3;
}

void _resetSettings() => _applySettings();

/// 手機尺寸 360x780 直向（dpr 3）
void _setPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360, 780) * 3;
  addTearDown(tester.view.reset);
}

/// 系統字級縮放（等同使用者在手機「顯示大小與文字」調整）
void _setSystemTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// audioplayers 的 platform channel 全部回成功（null），避免 plugin 沒註冊而丟例外
void _installPluginStubs() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();
  messenger.allMessagesHandler = (channel, handler, message) {
    if (channel.startsWith('xyz.luan/audioplayers')) {
      return Future.value(codec.encodeSuccessEnvelope(null));
    }
    if (handler != null) return handler(message);
    return null;
  };
}

/// 後端一律回 404（外殼畫面不該打 API；底層日記／儀表板頁若有打，也不會真的連網）
MockClient _fakeBackend() => MockClient(
  (req) async => http.Response(
    jsonEncode({
      'success': false,
      'data': null,
      'error': {'code': 'NOT_FOUND', 'message': 'not found'},
    }),
    404,
    headers: {'content-type': 'application/json; charset=utf-8'},
  ),
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.lightTheme,
  debugShowCheckedModeBanner: false,
  home: home,
);

Future<void> _settle(WidgetTester tester) async {
  // 不用 pumpAndSettle：AuthGate 的轉圈圈等動畫永遠不會 settle
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _pumpScreen(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(_app(home));
  await _settle(tester);
}

/// 收集 pump 期間 FlutterError（RenderFlex overflow、debug 檢查警告等）。
/// 不讓第一個錯誤就讓測試失敗，改成記進報告。
final List<String> _pendingErrors = [];

String _summarize(FlutterErrorDetails d) {
  final lines = d.exceptionAsString().split('\n').where((l) => l.trim().isNotEmpty);
  return lines.take(1).join(' ');
}

/// 檢查目前畫面。先把 pump 期間丟出的例外（RenderFlex overflow 等）記成 layout 違規，
/// 再跑四項 guideline。
List<String> _drainErrors() {
  final out = _pendingErrors.toSet().toList();
  _pendingErrors.clear();
  return out;
}

Future<void> _snap(WidgetTester tester, String screen) async {
  for (final msg in _drainErrors()) {
    a11y.violations.add(A11yViolation(screen, '框架例外(非 guideline)', '畫面拋出例外：$msg'));
  }
  await a11y.check(tester, screen);
}

/// 在 http zone + 手機尺寸 + 全程開啟 semantics 的環境下跑測試本體。
/// 自己先 ensureSemantics，確保 semantics tree 在 guideline 執行前就已經建好
/// （a11y_check 的 check() 內部才開 semantics，第一次可能還沒有 root node）。
Future<void> _run(
  WidgetTester tester,
  Future<void> Function() body, {
  double textScale = 1.0,
}) async {
  _setPhone(tester);
  if (textScale != 1.0) _setSystemTextScale(tester, textScale);
  final handle = tester.ensureSemantics();
  final origOnError = FlutterError.onError;
  _pendingErrors.clear();
  FlutterError.onError = (d) => _pendingErrors.add(_summarize(d));
  try {
    await http.runWithClient(body, _fakeBackend);
  } finally {
    FlutterError.onError = origOnError;
    handle.dispose();
  }
}

PostModel _fakePost({bool liked = false}) => PostModel(
  postId: 1,
  diaryId: 1,
  title: '早晨散步',
  photoUrl: 'https://example.invalid/photo.jpg',
  postText: '今天天氣很好，和老朋友一起去公園走走。',
  hashtags: const ['#散步', '#朋友', '#早晨'],
  category: '日常',
  date: '2026-10-26',
  postedAt: DateTime(2026, 10, 26, 8),
  likeCount: 3,
  isLiked: liked,
  voiceReplyCount: 2,
  shareUrl: 'https://example.invalid/share/1',
  inviteText: '',
  suggestedReplies: const [],
);

// ───────────────────────── 測試本體 ─────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    _installPluginStubs();
    _resetSettings();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
    _resetSettings();
  });

  // ── 登入／註冊流程（這些頁面都是固定淺色，不吃 AppSettings 主題） ──

  testWidgets('身分選擇頁 IdentitySelectPage', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const IdentitySelectPage());
      await _snap(tester, '身分選擇頁');
    });
  });

  testWidgets('登入頁 LoginPage', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const LoginPage());
      await _snap(tester, '登入頁');

      // 點眼睛圖示顯示密碼後的狀態（圖示換了，語意不該變差）
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      await _snap(tester, '登入頁（顯示密碼）');
    });
  });

  testWidgets('登入頁（系統字級 1.3 倍）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      await _pumpScreen(tester, const LoginPage());
      await _snap(tester, '登入頁（系統字級1.3）');
    });
  });

  testWidgets('註冊頁 RegisterPage', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const RegisterPage());
      await _snap(tester, '註冊頁（上半）');

      // 整頁一次看完：把視窗拉高到 360x1500，避免捲動時被裁掉一半的節點造成誤判
      tester.view.physicalSize = const Size(360, 1500) * 3;
      await _settle(tester);
      await _snap(tester, '註冊頁（整頁，視窗 360x1500）');

      // 選一個興趣後的選取狀態（選取色與未選取色不同）
      await tester.tap(find.text('健康講座'));
      await tester.pump();
      await _snap(tester, '註冊頁（整頁，已選興趣）');
    });
  });

  testWidgets('歡迎頁 WelcomePage', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const WelcomePage(userName: '玉蘭'));
      await _snap(tester, '歡迎頁');
    });
  });

  testWidgets('新手教學引導頁 TutorialIntroPage', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const TutorialIntroPage());
      await _snap(tester, '新手教學引導頁');
    });
  });

  // ── AuthGate 三種狀態 ──

  testWidgets('AuthGate：載入中 → 無 token → 身分選擇頁', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _run(tester, () async {
      await tester.pumpWidget(_app(const AuthGate()));
      // 剛 build 完、token 檢查的 future 還沒讓路由切換前的畫面
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await _snap(tester, 'AuthGate（載入中）');

      await _settle(tester);
      expect(find.byType(IdentitySelectPage), findsOneWidget);
      await _snap(tester, 'AuthGate（無 token → 身分選擇頁）');
    });
  });

  testWidgets('AuthGate：有 token → 主畫面', (tester) async {
    SharedPreferences.setMockInitialValues({'access_token': 'abc'});
    await _run(tester, () async {
      await tester.pumpWidget(_app(const AuthGate()));
      await _settle(tester);
      expect(find.byType(MainScreen), findsOneWidget);
      await _snap(tester, 'AuthGate（有 token → 主畫面首頁）');
    });
  });

  // ── 主畫面（底部導覽）、首頁 ──

  for (final (name, dark, hc) in _themeVariants) {
    testWidgets('主畫面 MainScreen + 首頁（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(tester, const MainScreen());
        await _snap(tester, '主畫面/首頁分頁（$name）');

        if (name == '淺色') {
          // 切到兩個純文字佔位分頁（聲影日記／儀表板屬於其他檢查範圍，這裡不切）
          await tester.tap(find.text('資訊站'));
          await _settle(tester);
          await _snap(tester, '主畫面/資訊站分頁（$name）');
          await tester.tap(find.text('會員'));
          await _settle(tester);
          await _snap(tester, '主畫面/會員分頁（$name）');
        }
      });
    });

    testWidgets('首頁 HomeScreen 單獨（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(tester, const HomeScreen());
        await _snap(tester, '首頁 HomeScreen（$name）');
      });
    });
  }

  testWidgets('主畫面 / 首頁（系統字級 1.3 倍）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      await _pumpScreen(tester, const MainScreen());
      await _snap(tester, '主畫面/首頁（系統字級1.3）');
    });
  });

  // ── 新手教學疊加層 ──

  testWidgets('新手教學疊加層 TutorialOverlay（MainScreen startTutorial）', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const MainScreen(startTutorial: true));
      expect(find.text('這裡是首頁，隨時都能回到這裡！'), findsOneWidget);
      await _snap(tester, '教學疊加層 步驟1（首頁）');

      // 步驟 2（聲影日記）與 4（儀表板）底下是其他 agent 負責的頁面，
      // 只前進、不檢查；它們丟的例外也不算在這份報告裡。
      await tester.tap(find.text('下一步'));
      await _settle(tester);
      _drainErrors();

      await tester.tap(find.text('下一步'));
      await _settle(tester);
      _drainErrors();
      expect(find.text('資訊站'), findsWidgets);
      await _snap(tester, '教學疊加層 步驟3（資訊站）');

      await tester.tap(find.text('下一步'));
      await _settle(tester);
      _drainErrors();

      await tester.tap(find.text('下一步'));
      await _settle(tester);
      _drainErrors();
      expect(find.text('完成教學'), findsOneWidget);
      await _snap(tester, '教學疊加層 步驟5（會員，最後一步）');
    });
  });

  testWidgets('新手教學疊加層（系統字級 1.3 倍）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      await _pumpScreen(tester, const MainScreen(startTutorial: true));
      await _snap(tester, '教學疊加層 步驟1（系統字級1.3）');
    });
  });

  // ── 遊戲首頁：六張能力卡片＋頂部列＋底部按鈕 ──

  for (final (name, dark, hc) in _themeVariants) {
    testWidgets('遊戲首頁 GameHomeScreen（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(tester, const GameHomeScreen());
        await _snap(tester, '遊戲首頁（$name）');
      });
    });
  }

  testWidgets('遊戲首頁（無未讀通知）', (tester) async {
    await _run(tester, () async {
      AppSettings.unreadNotificationCount.value = 0;
      await _pumpScreen(tester, const GameHomeScreen());
      await _snap(tester, '遊戲首頁（無未讀）');
    });
  });

  testWidgets('遊戲首頁（系統字級 1.3 倍）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      await _pumpScreen(tester, const GameHomeScreen());
      await _snap(tester, '遊戲首頁（淺色，系統字級1.3）');
    });
  });

  for (final (name, dark, hc) in _themeVariants.where((v) => v.$1 != '淺色')) {
    testWidgets('遊戲首頁（$name，系統字級 1.3 倍）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(textScale: 1.3, tester, () async {
        await _pumpScreen(tester, const GameHomeScreen());
        await _snap(tester, '遊戲首頁（$name，系統字級1.3）');
      });
    });
  }

  testWidgets('遊戲首頁（App 內字級最大 level 5）', (tester) async {
    _applySettings(level: 5);
    await _run(tester, () async {
      await _pumpScreen(tester, const GameHomeScreen());
      await _snap(tester, '遊戲首頁（App字級level5=145%）');
    });
  });

  // ── 設定頁 ──

  for (final (name, dark, hc) in _themeVariants) {
    testWidgets('設定頁 SettingsScreen（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(tester, const SettingsScreen());
        await _snap(tester, '設定頁（$name）');
      });
    });
  }

  testWidgets('設定頁：字級邊界（level 1、level 5 時 −/＋ 為 disabled）', (tester) async {
    await _run(tester, () async {
      _applySettings(level: 1);
      await _pumpScreen(tester, const SettingsScreen());
      await _snap(tester, '設定頁（App字級level1=85%，− disabled）');

      _applySettings(level: 5);
      await _pumpScreen(tester, const SettingsScreen());
      await _snap(tester, '設定頁（App字級level5=145%，＋ disabled）');
    });
  });

  testWidgets('設定頁（系統字級 1.3 倍，淺色／深色／高對比）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      for (final (name, dark, hc) in _themeVariants) {
        _applySettings(dark: dark, highContrast: hc);
        await _pumpScreen(tester, const SettingsScreen());
        await _snap(tester, '設定頁（$name，系統字級1.3）');
      }
    });
  });

  testWidgets('設定頁：登出確認對話框', (tester) async {
    await _run(tester, () async {
      await _pumpScreen(tester, const SettingsScreen());
      await tester.tap(find.text('登出'));
      await _settle(tester);
      expect(find.text('確定要登出目前的帳號嗎？'), findsOneWidget);
      await _snap(tester, '設定頁/登出確認對話框');
    });
  });

  // ── 通知頁 ──

  for (final (name, dark, hc) in _themeVariants) {
    testWidgets('通知頁 NotificationScreen（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(tester, const NotificationScreen());
        await _snap(tester, '通知頁（$name）');
      });
    });
  }

  testWidgets('通知頁：全部已讀後（按鈕 disabled）／系統字級 1.3 倍', (tester) async {
    await _run(tester, () async {
      AppSettings.unreadNotificationCount.value = 0;
      await _pumpScreen(tester, const NotificationScreen());
      await _snap(tester, '通知頁（全部已讀，按鈕disabled）');
    });
  });

  testWidgets('通知頁（系統字級 1.3 倍）', (tester) async {
    await _run(textScale: 1.3, tester, () async {
      await _pumpScreen(tester, const NotificationScreen());
      await _snap(tester, '通知頁（系統字級1.3）');
    });
  });

  // ── 社群：目前只有 PostCard 元件，沒有任何頁面使用它（SocialService 也沒人呼叫）──

  for (final (name, dark, hc) in _themeVariants) {
    testWidgets('社群貼文卡片 PostCard（$name）', (tester) async {
      _applySettings(dark: dark, highContrast: hc);
      await _run(tester, () async {
        await _pumpScreen(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PostCard(
                post: _fakePost(liked: name == '深色'),
                onLikeTap: () {},
                onVoiceReplyTap: () {},
                onSubmitComment: (_) {},
              ),
            ),
          ),
        );
        // 測試環境的 Image.network 一律回 400，圖片載入失敗會丟例外、並畫出錯誤訊息文字；
        // 那是測試環境造成的，不算 PostCard 的違規：吃掉例外，並濾掉錯誤文字造成的對比紀錄。
        // （App 本身沒給 Image.network errorBuilder，離線時長輩會看到錯誤畫面，是另一個問題。）
        _drainErrors();
        final before = a11y.violations.length;
        await a11y.check(tester, '社群貼文卡片 PostCard（$name）');
        final added = a11y.violations.sublist(before);
        a11y.violations.removeRange(before, a11y.violations.length);
        a11y.violations.addAll(
          added.where(
            (v) => !(v.guideline == 'textContrast' && v.reason.contains('HTTP request failed')),
          ),
        );
      });
    });
  }

  // ── 最後輸出報告 ──

  testWidgets('輸出無障礙報告', (tester) async {
    a11y.finish();
  });
}
