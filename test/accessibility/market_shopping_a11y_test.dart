// 市場買菜（market_shopping）無障礙檢查：走完整個遊戲，在每個不同的畫面/狀態
// 用 Flutter 內建 guideline（點擊區 48dp/44pt、點擊元件標籤、文字對比）檢查一次。
//
// 預設不會因為違規而失敗，只印出報告並寫到 build/a11y_report/market_shopping.txt；
// 要讓違規直接失敗：flutter test test/accessibility/market_shopping_a11y_test.dart --dart-define=A11Y_STRICT=true
//
// 假後端、plugin 假實作與操作工具是從 test/playthrough/market_shopping_playthrough_test.dart 複製的。
import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_checkout_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_game_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_memorize_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_play_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_result_page.dart';
import 'package:light_memory/features/game/market_shopping/widgets/market_shopping_tutorial_dialog.dart';
import 'package:light_memory/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'a11y_check.dart';

// ---------------------------------------------------------------------------
// 音效 plugin 假實作：audioplayers 在測試環境沒有原生端。
// AudioCache.loadPath 永遠不完成，play() 就停在那裡（不會有 timer、不會丟錯）。
// ---------------------------------------------------------------------------
class _FakeAudioPlatform extends AudioplayersPlatformInterface {
  final _events = StreamController<AudioEvent>.broadcast();

  @override
  Stream<AudioEvent> getEventStream(String playerId) => _events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Null>.value();
}

class _FakeGlobalAudioPlatform implements GlobalAudioplayersPlatformInterface {
  final _events = StreamController<GlobalAudioEvent>.broadcast();

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => _events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Null>.value();
}

final List<String> playedSounds = [];

class _FakeAudioCache extends AudioCache {
  @override
  Future<String> loadPath(String fileName) {
    playedSounds.add(fileName);
    return Completer<String>().future; // 永不完成
  }
}

// ---------------------------------------------------------------------------
// 假後端
// ---------------------------------------------------------------------------
const Map<String, String> kFoods = {
  'cabbage': '高麗菜',
  'cucumber': '小黃瓜',
  'egg': '雞蛋',
  'onion': '洋蔥',
  'pork': '豬肉',
  'spinach': '菠菜',
  'tofu': '豆腐',
  'tomato': '番茄',
};
const Map<String, int> kPrices = {
  'cabbage': 35,
  'cucumber': 15,
  'egg': 40,
  'onion': 20,
  'pork': 120,
  'spinach': 25,
  'tofu': 18,
  'tomato': 30,
};

class FakeQuestion {
  final int n;
  final int total;
  FakeQuestion(this.n, this.total);

  String get difficulty => n <= 4 ? 'easy' : (n <= 7 ? 'medium' : 'hard');
  int get itemCount => difficulty == 'easy' ? 2 : (difficulty == 'medium' ? 3 : 4);
  int get optionCount => difficulty == 'hard' ? 8 : 6;

  List<String> get list {
    final codes = kFoods.keys.toList();
    return List.generate(itemCount, (i) => codes[(n * 3 + i) % codes.length]);
  }

  List<String> get options {
    final codes = kFoods.keys.toList();
    final distractors = codes.where((c) => !list.contains(c)).toList();
    final all = [...list, ...distractors.take(optionCount - itemCount)];
    all.sort(); // 打散：依字母序，正確答案不會都在前面
    return all;
  }

  /// 不在購物清單上的第一個選項（拿來答錯用）
  String get wrongCode => options.firstWhere((c) => !list.contains(c));

  int get budget => difficulty == 'easy' ? 200 : (difficulty == 'medium' ? 300 : 500);
  int get spent => list.fold(0, (s, c) => s + kPrices[c]!);
  int get change => budget - spent;
  List<int> get changeOptions {
    final opts = [change, change + 10, change - 5, change + 20];
    final r = n % opts.length;
    return [...opts.sublist(r), ...opts.sublist(0, r)];
  }

  int get wrongChange => change + 10;

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'current_question': n,
    'total_questions': total,
    'shopping_list': list.map((c) => {'food_code': c, 'food_name': kFoods[c]}).toList(),
    'selection_options': options.map((c) => {'food_code': c, 'food_name': kFoods[c]}).toList(),
  };
}

enum FailMode { none, http500, htmlBadGateway, network, notLoggedIn401 }

class FakeBackend {
  int total;
  FakeBackend({this.total = 10});

  int sessionCounter = 0;
  String? sessionId;
  late FakeQuestion current;
  int itemWrong = 0;
  int changeWrong = 0;
  bool firstTry = true;
  int points = 0;
  int totalCorrect = 0;
  int firstTryCorrect = 0;
  int consecutive = 0;
  bool completed = false;

  // 可調整的失敗/延遲
  final List<FailMode> startFailures = [];
  Duration startDelay = Duration.zero;
  final List<FailMode> itemFailures = [];
  final List<FailMode> changeFailures = [];
  Duration Function(int callIndex)? itemDelay;
  FailMode historyFailure = FailMode.none;

  final List<http.Request> requests = [];
  int itemCalls = 0;

  /// 假後端發現的請求內容問題（不能在 handler 裡用 flutter_test 的 expect，會跟 pump 的 guard 衝突）
  final List<String> violations = [];
  void _check(bool ok, String msg) {
    if (!ok) violations.add(msg);
  }

  final List<Map<String, dynamic>> history = [
    {'score': 55, 'accuracy': 40.0, 'played_at': '2026-10-20T09:00:00Z'},
    {'score': 70, 'accuracy': 60.0, 'played_at': '2026-10-21T09:00:00Z'},
    {'score': 82, 'accuracy': 66.67, 'played_at': '2026-10-22T09:00:00Z'},
  ];

  MockClient client() => MockClient(_handle);

  http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  http.Response _ok(Map<String, dynamic> data) => _json({'success': true, 'data': data, 'error': null});

  Future<http.Response> _fail(FailMode m) async {
    switch (m) {
      case FailMode.http500:
        return _json({
          'success': false,
          'data': null,
          'error': {'code': 'INTERNAL_ERROR', 'message': '伺服器錯誤'},
        }, 500);
      case FailMode.htmlBadGateway:
        return http.Response('<html><body>502 Bad Gateway</body></html>', 502);
      case FailMode.network:
        throw http.ClientException('Failed host lookup');
      case FailMode.notLoggedIn401:
        return _json({'detail': '身分認證資訊未提供。'}, 401);
      case FailMode.none:
        throw StateError('unreachable');
    }
  }

  void _advance() {
    current = FakeQuestion(current.n + 1, total);
    itemWrong = 0;
    changeWrong = 0;
    firstTry = true;
  }

  Map<String, dynamic> _completion(bool lastCorrect) {
    completed = true;
    final accuracy = double.parse((firstTryCorrect / total * 100).toStringAsFixed(2));
    history.add({
      'score': points,
      'accuracy': accuracy,
      'played_at': DateTime.utc(2026, 10, 26, 10, sessionCounter).toIso8601String(),
    });
    return {
      'is_correct': lastCorrect,
      'retry': false,
      'is_completed': true,
      'accuracy': accuracy,
      'raw_score': points,
      'total_correct': totalCorrect,
      'first_try_correct_count': firstTryCorrect,
      'consecutive_correct': consecutive,
      'difficulty_upgraded': false,
    };
  }

  Future<http.Response> _handle(http.Request req) async {
    requests.add(req);
    final path = req.url.path;
    _check(
      req.headers['Authorization'] == 'Bearer test-token',
      'Authorization header 錯誤：${req.headers['Authorization']}',
    );

    if (req.method == 'POST' && path.endsWith('/api/games/market-shopping/sessions/')) {
      if (startDelay > Duration.zero) await Future.delayed(startDelay);
      if (startFailures.isNotEmpty) {
        final m = startFailures.removeAt(0);
        if (m != FailMode.none) return _fail(m);
      }
      sessionCounter++;
      sessionId = '48b8015b-c982-4311-0000-00000000000$sessionCounter';
      current = FakeQuestion(1, total);
      itemWrong = changeWrong = points = totalCorrect = firstTryCorrect = consecutive = 0;
      firstTry = true;
      completed = false;
      return _ok({'session_id': sessionId, ...current.toJson()});
    }

    if (req.method == 'POST' && path.contains('/item-answers/')) {
      final callIndex = itemCalls++;
      _check(path.contains('/sessions/$sessionId/'), '送到錯的 session：$path（目前 $sessionId）');
      // 先依「送出當下」的狀態算好回應，再模擬網路延遲
      final Future<http.Response> Function() respond;
      if (itemFailures.isNotEmpty && itemFailures.first != FailMode.none) {
        final m = itemFailures.removeAt(0);
        respond = () => _fail(m);
      } else {
        if (itemFailures.isNotEmpty) itemFailures.removeAt(0);
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        _check(body['reaction_time_ms'] is int, 'reaction_time_ms 不是 int');
        final selected = (body['selected_food_codes'] as List).cast<String>().toSet();
        final q = current;
        final Map<String, dynamic> data;
        if (selected.length == q.list.length && selected.containsAll(q.list)) {
          data = {
            'is_correct': true,
            'is_completed': false,
            'budget': q.budget,
            if (q.difficulty != 'hard') 'spent_amount': q.spent,
            if (q.difficulty == 'hard')
              'purchased_items': q.list.map((c) => {'food_name': kFoods[c], 'price': kPrices[c]}).toList(),
            'change_options': q.changeOptions,
          };
        } else {
          itemWrong++;
          firstTry = false;
          consecutive = 0;
          if (itemWrong < 3) {
            data = {
              'is_correct': false,
              'retry': true,
              'wrong_count': itemWrong,
              'remaining_attempts': 3 - itemWrong,
              'error_type': 'mixed_item_error',
            };
          } else if (q.n >= total) {
            // 最後一題選菜錯滿3次：整場結束（model 註解描述的情境）
            data = {..._completion(false), 'wrong_count': 3, 'remaining_attempts': 0};
          } else {
            _advance();
            data = {
              'is_correct': false,
              'retry': false,
              'wrong_count': 3,
              'remaining_attempts': 0,
              'error_type': 'mixed_item_error',
              'next_question': current.toJson(),
            };
          }
        }
        final resp = _ok(data);
        respond = () async => resp;
      }
      final d = itemDelay?.call(callIndex) ?? Duration.zero;
      if (d > Duration.zero) await Future.delayed(d);
      return respond();
    }

    if (req.method == 'POST' && path.contains('/change-answers/')) {
      _check(path.contains('/sessions/$sessionId/'), '送到錯的 session：$path（目前 $sessionId）');
      if (changeFailures.isNotEmpty) {
        final m = changeFailures.removeAt(0);
        if (m != FailMode.none) return _fail(m);
      }
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final amount = body['selected_amount'] as int;
      final q = current;
      Map<String, dynamic> data;
      if (amount == q.change) {
        totalCorrect++;
        consecutive++;
        if (firstTry) firstTryCorrect++;
        points += firstTry ? 10 : 6;
        if (q.n >= total) {
          data = _completion(true);
        } else {
          _advance();
          data = {'is_correct': true, 'retry': false, 'is_completed': false, 'next_question': current.toJson()};
        }
      } else {
        changeWrong++;
        firstTry = false;
        consecutive = 0;
        if (changeWrong < 3) {
          data = {
            'is_correct': false,
            'retry': true,
            'is_completed': false,
            'wrong_count': changeWrong,
            'remaining_attempts': 3 - changeWrong,
            'error_type': 'change_too_low',
          };
        } else if (q.n >= total) {
          data = _completion(false);
        } else {
          _advance();
          data = {'is_correct': false, 'retry': false, 'is_completed': false, 'next_question': current.toJson()};
        }
      }
      return _ok(data);
    }

    if (req.method == 'GET' && path.endsWith('/api/games/market-shopping/history/')) {
      if (historyFailure != FailMode.none) return _fail(historyFailure);
      return _json({'success': true, 'data': history, 'error': null});
    }

    // 其他（例如退出後首頁/通知頁）一律回空資料
    return _json({'success': true, 'data': [], 'error': null});
  }
}
// ---------------------------------------------------------------------------
// 測試工具
// ---------------------------------------------------------------------------
class ErrorLog {
  final List<String> errors = [];
  final List<String> details = [];
  final List<String> unreachable = [];
  String stage = '';
  List<String> get overflows => errors.where((e) => e.contains('overflowed')).toList();
  @override
  String toString() => errors.join('\n-----\n');
}

/// 收集 FlutterError（例如 RenderFlex overflow）跟未捕捉的非同步錯誤，
/// 不讓第一個錯誤就中斷整場遊玩。
Future<ErrorLog> runGame(WidgetTester tester, FakeBackend fake, Future<void> Function(ErrorLog log) body) async {
  final log = ErrorLog();
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    log.errors.add('[${log.stage}] ${d.exceptionAsString()}');
    final full = d.toString().split('\n');
    log.details.add(
      '[${log.stage}]\n${full.where((l) => l.contains('relevant error-causing') || l.contains('.dart:') || l.contains('overflowed')).take(4).join('\n')}',
    );
  };
  final done = Completer<void>();
  // App 程式裡沒被接住的非同步錯誤（例如 setState after dispose）會落到這個 zone，
  // 記錄下來而不是直接讓測試中斷；測試本身的失敗則透過 done 往外丟。
  runZonedGuarded(
    () {
      http
          .runWithClient(() => body(log), fake.client)
          .then(
            (_) {
              if (!done.isCompleted) done.complete();
            },
            onError: (Object e, StackTrace s) {
              // ignore: avoid_print
              print(
                '測試中斷於 [${log.stage}]\n錯誤：${log.errors.join('\n')}\n點不到：${log.unreachable.join('\n')}\n${log.details.toSet().join('\n')}',
              );
              if (!done.isCompleted) done.completeError(e, s);
            },
          );
    },
    (e, s) {
      log.errors.add('[uncaught async] $e');
    },
  );
  try {
    await done.future;
  } finally {
    FlutterError.onError = original;
  }
  expect(fake.violations, isEmpty, reason: '假後端收到的請求有問題');
  return log;
}
void drain(WidgetTester tester, ErrorLog log) {
  Object? e;
  while ((e = tester.takeException()) != null) {
    log.errors.add(e.toString());
  }
}

void setScreen(WidgetTester tester, Size logical) {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget harness() => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketShoppingGamePage())),
          child: const Text('進入市場買菜'),
        ),
      ),
    ),
  ),
);

Future<void> enterGame(WidgetTester tester) async {
  await tester.pumpWidget(harness());
  await tester.tap(find.text('進入市場買菜'));
  await tester.pump(); // initState → startGame
  await tester.pump(const Duration(milliseconds: 400)); // route 動畫 + http
  await tester.pump(const Duration(milliseconds: 400)); // 教學 dialog 動畫
}

Future<void> settle(WidgetTester tester, [int ms = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// 走完教學三頁（「下一頁 →」×2、「開始遊戲 →」）
Future<void> walkTutorial(WidgetTester tester) async {
  expect(find.byType(MarketShoppingTutorialDialog), findsOneWidget);
  expect(find.text('第一步'), findsOneWidget);
  await tester.tap(find.text('下一頁 →'));
  await settle(tester);
  expect(find.text('第二步'), findsOneWidget);
  // 測試「上一頁」箭頭
  await tester.tap(find.byIcon(Icons.arrow_back));
  await settle(tester);
  expect(find.text('第一步'), findsOneWidget);
  await tester.tap(find.text('下一頁 →'));
  await settle(tester);
  await tester.tap(find.text('下一頁 →'));
  await settle(tester);
  expect(find.text('第三步'), findsOneWidget);
  await tester.tap(find.text('開始遊戲 →'));
  await settle(tester);
  expect(find.byType(MarketShoppingTutorialDialog), findsNothing);
}

Future<void> closeTutorialWithX(WidgetTester tester) async {
  expect(find.byType(MarketShoppingTutorialDialog), findsOneWidget);
  await tester.tap(find.descendant(of: find.byType(MarketShoppingTutorialDialog), matching: find.byIcon(Icons.close)));
  await settle(tester);
  expect(find.byType(MarketShoppingTutorialDialog), findsNothing);
}

Finder optionCard(String code) => find.descendant(of: find.byType(GridView), matching: find.text(kFoods[code]!));

Future<void> selectFoods(WidgetTester tester, Iterable<String> codes) async {
  final grid = find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)).first;
  for (final c in codes) {
    tester.state<ScrollableState>(grid).position.jumpTo(0); // 先回到最上面
    await tester.pump();
    await tester.scrollUntilVisible(optionCard(c), 80, scrollable: grid);
    await tester.pump();
    await tester.tap(optionCard(c));
    await tester.pump();
  }
}

Future<void> confirmSelection(WidgetTester tester) async {
  await tester.tap(find.text('確認選好了'));
  await tester.pump(); // 送出
  await tester.pump(); // http microtasks
  await tester.pump(const Duration(milliseconds: 50));
}

bool isHittable(WidgetTester tester, Finder f) {
  final center = tester.getCenter(f);
  final result = HitTestResult();
  tester.binding.hitTestInView(result, center, tester.view.viewId);
  final ro = tester.renderObject(f);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  return center.dy < size.height && result.path.any((e) => e.target == ro);
}

/// 點找零選項。選項若被擠出畫面（點不到），記錄下來後直接呼叫 onTap 讓遊玩繼續。
Future<void> chooseChange(WidgetTester tester, int amount, [ErrorLog? log]) async {
  final f = find.text('$amount 元').last; // 選項在資訊卡下方，取最後一個
  if (isHittable(tester, f)) {
    await tester.tap(f);
  } else {
    log?.unreachable.add('${log.stage}：「$amount 元」選項點不到（y=${tester.getCenter(f).dy.toStringAsFixed(0)}）');
    final gd = find.ancestor(of: f, matching: find.byType(GestureDetector)).first;
    tester.widget<GestureDetector>(gd).onTap!();
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> dismissSnack(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600)); // 進場動畫
  await tester.pump(const Duration(milliseconds: 4100)); // 顯示 4 秒
  await tester.pump(const Duration(milliseconds: 600)); // 退場動畫
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.byType(SnackBar), findsNothing);
}
// ---------------------------------------------------------------------------
// 無障礙檢查流程
// ---------------------------------------------------------------------------
const Size kPhone = Size(360, 780);
const Size kSmallPhone = Size(360, 640);

Future<void> openPause(WidgetTester tester) async {
  await tester.tap(find.text('選單'));
  await settle(tester);
  expect(find.text('遊戲暫停'), findsOneWidget);
}

/// 沒有檢查的快速玩一題（記憶 → 選菜 → 找零，全部答對）
Future<void> quickPlay(WidgetTester tester, FakeBackend fake, ErrorLog log) async {
  final q = fake.current;
  log.stage = 'Q${q.n}/快速';
  await tester.tap(find.text('我記住了！'));
  await tester.pump();
  await selectFoods(tester, q.list);
  await confirmSelection(tester);
  await tester.pump(const Duration(milliseconds: 1600));
  await chooseChange(tester, q.change, log);
  await tester.pump(const Duration(milliseconds: 1900));
  await tester.pump(const Duration(milliseconds: 400));
  drain(tester, log);
}

void main() {
  setUpAll(() {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    GlobalAudioplayersPlatformInterface.instance = _FakeGlobalAudioPlatform();
    AudioCache.instance = _FakeAudioCache();
  });

  setUp(() {
    playedSounds.clear();
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  testWidgets('市場買菜：每個畫面跑無障礙 guideline', (tester) async {
    final a11y = A11yReport('market_shopping');
    // 整場測試都開著 semantics，確保每次檢查時語意樹都跟畫面同步
    // （A11yReport.check 自己只在檢查當下臨時 ensureSemantics）。
    final semanticsHandle = tester.ensureSemantics();
    setScreen(tester, kPhone);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fake = FakeBackend();
    late ErrorLog theLog;

    Future<void> chk(String name) async {
      await a11y.check(tester, name);
      drain(tester, theLog);
    }

    /// 暫時換螢幕尺寸檢查，再換回來
    Future<void> chkAt(Size size, String name) async {
      setScreen(tester, size);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await chk(name);
      setScreen(tester, kPhone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// 暫時把系統字體放大 1.3 倍檢查
    Future<void> chkScaled(String name) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await chk(name);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    final log = await runGame(tester, fake, (log) async {
      theLog = log;

      // ---- 1. 開局失敗 → 錯誤/重試畫面 → 載入中 → 教學 ----
      log.stage = '錯誤畫面';
      fake.startFailures.add(FailMode.http500);
      await tester.pumpWidget(harness());
      await tester.tap(find.text('進入市場買菜'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('重試'), findsOneWidget);
      await chk('錯誤/重試畫面（API 500）');
      await chkScaled('錯誤/重試畫面（字體130%）');

      log.stage = '載入中';
      fake.startDelay = const Duration(seconds: 2);
      await tester.tap(find.text('重試'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await chk('載入中畫面');
      fake.startDelay = Duration.zero;
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));

      // ---- 2. 教學三頁 ----
      log.stage = '教學';
      expect(find.byType(MarketShoppingTutorialDialog), findsOneWidget);
      await chk('教學 第1頁（360x780）');
      await chkAt(kSmallPhone, '教學 第1頁（360x640）');
      await chkScaled('教學 第1頁（字體130%）');
      await tester.tap(find.text('下一頁 →'));
      await settle(tester);
      expect(find.text('第二步'), findsOneWidget);
      await chk('教學 第2頁（有「上一頁」箭頭）');
      await tester.tap(find.text('下一頁 →'));
      await settle(tester);
      expect(find.text('第三步'), findsOneWidget);
      await chk('教學 第3頁（開始遊戲）');
      await tester.tap(find.text('開始遊戲 →'));
      await settle(tester);
      expect(find.byType(MarketShoppingTutorialDialog), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));

      // ---- 3. Q1 easy ----
      var q = fake.current;
      log.stage = 'Q1/easy/記憶頁';
      expect(find.byType(MarketShoppingMemorizePage), findsOneWidget);
      await chk('記憶頁 easy');
      await chkScaled('記憶頁 easy（字體130%）');
      await openPause(tester);
      await chk('暫停選單（直向）');
      await tester.tap(find.text('繼續遊戲'));
      await settle(tester);

      await tester.tap(find.text('我記住了！'));
      await tester.pump();
      log.stage = 'Q1/easy/選菜頁';
      expect(find.byType(MarketShoppingPlayPage), findsOneWidget);
      await chk('選菜頁 easy（空菜籃）');
      await chkScaled('選菜頁 easy（字體130%）');
      await selectFoods(tester, [q.list.first, q.wrongCode]);
      await chk('選菜頁 easy（已選品項，菜籃有 Chip）');
      await confirmSelection(tester);
      expect(find.text('請稍候...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300)); // 等卡片顏色動畫跑完，不然會量到轉場中的顏色
      await chk('選菜頁 easy（答錯回饋，橘/綠卡片加圖示）');
      await tester.pump(const Duration(milliseconds: 2100));

      // 送出失敗 → SnackBar
      fake.itemFailures.add(FailMode.http500);
      await selectFoods(tester, q.list);
      await confirmSelection(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SnackBar), findsOneWidget);
      await chk('選菜頁 SnackBar（送出失敗）');
      await dismissSnack(tester);
      await confirmSelection(tester);
      expect(find.text('請稍候...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300)); // 等卡片顏色動畫跑完，不然會量到轉場中的顏色
      await chk('選菜頁 easy（答對回饋）');
      log.stage = 'Q1/easy/找零頁';
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(MarketShoppingCheckoutPage), findsOneWidget);
      await chk('找零頁 easy（360x780）');
      await chkAt(kSmallPhone, '找零頁 easy（360x640）');
      await chkScaled('找零頁 easy（字體130%）');
      await openPause(tester);
      await chkAt(kSmallPhone, '暫停選單（360x640）');
      await tester.tap(find.text('繼續遊戲'));
      await settle(tester);

      fake.changeFailures.add(FailMode.htmlBadGateway);
      await chooseChange(tester, q.change, log);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SnackBar), findsOneWidget);
      await chk('找零頁 SnackBar（送出失敗）');
      await dismissSnack(tester);
      await chooseChange(tester, q.wrongChange, log);
      expect(find.text('再試一次看看！'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300)); // 等卡片顏色動畫跑完，不然會量到轉場中的顏色
      await chk('找零頁 easy（答錯回饋「再試一次看看！」）');
      await tester.pump(const Duration(milliseconds: 1900));
      await chooseChange(tester, q.change, log);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300)); // 等卡片顏色動畫跑完，不然會量到轉場中的顏色
      await chk('找零頁 easy（答對回饋）');
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 400));
      drain(tester, log);

      // ---- Q2~Q4 快速帶過 ----
      for (var i = 0; i < 3; i++) {
        await quickPlay(tester, fake, log);
      }

      // ---- 4. Q5 medium ----
      q = fake.current;
      expect(q.difficulty, 'medium');
      log.stage = 'Q${q.n}/medium/記憶頁';
      expect(find.text('第 ${q.n} / ${q.total} 題'), findsOneWidget);
      await chk('記憶頁 medium');
      await tester.tap(find.text('我記住了！'));
      await tester.pump();
      log.stage = 'Q${q.n}/medium/選菜頁';
      await chk('選菜頁 medium（空菜籃）');
      await selectFoods(tester, q.list);
      await chk('選菜頁 medium（已選3項）');
      await confirmSelection(tester);
      log.stage = 'Q${q.n}/medium/找零頁';
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(MarketShoppingCheckoutPage), findsOneWidget);
      await chk('找零頁 medium（360x780）');
      await chkAt(kSmallPhone, '找零頁 medium（360x640）');
      await chooseChange(tester, q.change, log);
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 400));
      drain(tester, log);

      // ---- Q6~Q7 快速帶過 ----
      for (var i = 0; i < 2; i++) {
        await quickPlay(tester, fake, log);
      }

      // ---- 5. Q8 hard ----
      q = fake.current;
      expect(q.difficulty, 'hard');
      log.stage = 'Q${q.n}/hard/記憶頁';
      await chk('記憶頁 hard（4項）');
      await tester.tap(find.text('我記住了！'));
      await tester.pump();
      log.stage = 'Q${q.n}/hard/選菜頁';
      await chk('選菜頁 hard（8個選項，頂部）');
      final grid = find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)).first;
      final pos = tester.state<ScrollableState>(grid).position;
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await chk('選菜頁 hard（選項捲到底）');
      await selectFoods(tester, q.list);
      await chk('選菜頁 hard（已選4項）');
      await confirmSelection(tester);
      log.stage = 'Q${q.n}/hard/找零頁';
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(MarketShoppingCheckoutPage), findsOneWidget);
      await chk('找零頁 hard（360x780，含購買明細）');
      await chkAt(kSmallPhone, '找零頁 hard（360x640）');
      await chooseChange(tester, q.change, log);
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 400));
      drain(tester, log);

      // ---- Q9~Q10 快速帶過 → 結算頁 ----
      await quickPlay(tester, fake, log);
      q = fake.current;
      expect(q.n, 10);
      await quickPlay(tester, fake, log);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));

      // ---- 6. 結算頁 ----
      log.stage = '結算頁';
      expect(find.byType(MarketShoppingResultPage), findsOneWidget);
      expect(find.text('成績結算'), findsOneWidget);
      await chk('結算頁（有歷史折線圖，360x780 頂部）');
      await chkScaled('結算頁（字體130%）');
      await chkAt(kSmallPhone, '結算頁（360x640）');
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await chk('結算頁（捲到歷史折線圖）');

      // ---- 7. 再玩一次（1 題的短局）→ 歷史成績載入失敗的結算頁 ----
      fake.total = 1;
      fake.historyFailure = FailMode.http500;
      await tester.ensureVisible(find.text('再玩一次'));
      await tester.tap(find.text('再玩一次'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await closeTutorialWithX(tester);
      // 只有 1 題：答錯 1 次選菜 → 之後全對，分數 6 → 「沒關係再加油」等級
      q = fake.current;
      await quickPlay(tester, fake, log);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MarketShoppingResultPage), findsOneWidget);
      expect(find.text('無法載入歷史成績'), findsOneWidget);
      log.stage = '結算頁（歷史失敗）';
      await chk('結算頁（歷史成績載入失敗訊息）');
      drain(tester, log);
    });

    // 報告之外的資訊：收集到的框架錯誤（例如 overflow）與點不到的元件
    // ignore: avoid_print
    print('[a11y] 流程中收集到的框架錯誤 ${log.errors.length} 筆：\n${log.details.toSet().join('\n')}');
    // ignore: avoid_print
    print('[a11y] 點不到的元件：\n${log.unreachable.join('\n')}');
    final broken = a11y.violations.where((v) => v.reason.startsWith('檢查本身出錯'));
    // ignore: avoid_print
    if (broken.isNotEmpty) print('[a11y] 以下檢查本身出錯（該畫面沒有被完整檢查）：\n${broken.map((v) => '${v.screen}/${v.guideline}: ${v.reason}').join('\n')}');
    semanticsHandle.dispose();
    a11y.finish();
  });
}
