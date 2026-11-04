// 冰箱盤點（fridge_inventory）無障礙檢查
//
// 沿用 playthrough 測試的假後端 / plugin stub，走過每個不同的畫面，
// 在每個畫面上跑 Flutter 內建的 accessibility guideline（見 a11y_check.dart）。
// 預設不會因違規而失敗；加 --dart-define=A11Y_STRICT=true 才會失敗。
// 報告輸出到 build/a11y_report/冰箱盤點.txt

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/core/constants/api_constants.dart';
import 'package:light_memory/features/game/fridge_inventory/pages/fridge_game_page.dart';
import 'package:light_memory/features/game/fridge_inventory/pages/fridge_result_page.dart';
import 'package:light_memory/features/game/fridge_inventory/pages/fridge_tutorial_page.dart';
import 'package:light_memory/screens/game_home_screen.dart';

import 'a11y_check.dart';

// ====================================================================
// 假後端
// ====================================================================

const String kBase = '${ApiConstants.serverUrl}/api/games/fridge-check';

class FakeFridgeBackend {
  FakeFridgeBackend({this.startQ = 1});

  /// 開新 session 時從第幾題開始（用來快速跳到中等 / 困難 / 最後一題）
  int startQ;
  final int total = 10;

  int q = 1;
  int score = 0;
  int attempts = 3;
  bool completed = false;
  int sessionCount = 0;

  Duration latency = const Duration(milliseconds: 200);

  // 失敗注入
  int startStatus = 200;
  String? startBodyOverride;
  bool startThrows = false;
  Duration? startHang; // 模擬伺服器很慢
  int answerStatus = 200;
  bool omitNextQuestion = false;
  int historyStatus = 200;

  final List<http.Request> requests = [];

  List<http.Request> get answerRequests =>
      requests.where((r) => r.url.path.endsWith('/answers/')).toList();
  List<http.Request> get sessionRequests => requests
      .where((r) => r.method == 'POST' && r.url.path.endsWith('/sessions/'))
      .toList();

  String get sessionId =>
      '7d6635ab-eef8-458b-9c1a-${sessionCount.toString().padLeft(12, '0')}';

  static String diffOf(int i) => i <= 4 ? 'easy' : (i <= 7 ? 'medium' : 'hard');

  static Map<String, dynamic> cell(String pos, String? code, String? name) => {
    'position': pos,
    'food_code': code,
    'food_name': name,
  };

  Map<String, dynamic> question(int i) {
    final d = diffOf(i);
    if (d == 'easy') {
      return {
        'question_id': 100 + i,
        'question_type': 'identify_food',
        'prompt': '請找出牛奶右邊的是什麼？',
        'board': [
          cell('r1c1', 'egg', '雞蛋'),
          cell('r1c2', 'milk', '牛奶'),
          cell('r1c3', 'tofu', '豆腐'),
          cell('r2c1', 'tomato', '番茄'),
          cell('r2c2', 'cabbage', '高麗菜'),
          cell('r2c3', 'pepper', '青椒'),
          cell('r3c1', 'carrot', '胡蘿蔔'),
          cell('r3c2', 'apple', '蘋果'),
          cell('r3c3', 'banana', '香蕉'),
        ],
      };
    }
    if (d == 'medium') {
      return {
        'question_id': 100 + i,
        'question_type': 'find_position',
        'prompt': '請找出第二排中間的雞蛋',
        'board': [
          for (final r in [1, 2, 3])
            for (final c in [1, 2, 3]) cell('r${r}c$c', 'egg', '雞蛋'),
        ],
      };
    }
    return {
      'question_id': 100 + i,
      'question_type': 'place_item',
      'prompt': '把番茄移到第二排中間',
      'board': [
        cell('r1c1', 'tofu', '豆腐'),
        cell('r1c2', null, null),
        cell('r1c3', 'apple', '蘋果'),
        cell('r2c1', 'egg', '雞蛋'),
        cell('r2c2', null, null),
        cell('r2c3', 'milk', '牛奶'),
        cell('r3c1', 'carrot', '胡蘿蔔'),
        cell('r3c2', null, null),
        cell('r3c3', 'banana', '香蕉'),
      ],
      'source_food': {'food_code': 'tomato', 'food_name': '番茄'},
    };
  }

  bool _judge(Map answer) {
    switch (diffOf(q)) {
      case 'easy':
        return answer['food_code'] == 'tofu' && !answer.containsKey('position');
      case 'medium':
        return answer['position'] == 'r2c2' && !answer.containsKey('food_code');
      default:
        return answer['food_code'] == 'tomato' && answer['position'] == 'r2c2';
    }
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Map<String, dynamic> _advance(Map<String, dynamic> base) {
    if (q >= total) {
      completed = true;
      return {
        ...base,
        'is_completed': true,
        'current_score': score,
        'final_score': score,
      };
    }
    q++;
    attempts = 3;
    return {
      ...base,
      'is_completed': false,
      'current_score': score,
      'current_question': q,
      'difficulty': diffOf(q),
      if (!omitNextQuestion) 'next_question': question(q),
    };
  }

  Future<http.Response> handle(http.Request req) async {
    requests.add(req);

    final path = req.url.toString();

    if (req.method == 'POST' && path == '$kBase/sessions/') {
      if (startHang != null) await Future.delayed(startHang!);
      await Future.delayed(latency);
      if (startThrows) throw http.ClientException('Connection refused');
      if (startBodyOverride != null) {
        return http.Response(startBodyOverride!, startStatus);
      }
      if (startStatus != 200 && startStatus != 201) {
        return _json({'detail': 'Internal Server Error'}, startStatus);
      }
      sessionCount++;
      q = startQ;
      score = 0;
      attempts = 3;
      completed = false;
      return _json({
        'success': true,
        'data': {
          'session_id': sessionId,
          'total_questions': total,
          'current_question': q,
          'difficulty': diffOf(q),
          'question': question(q),
        },
      }, 201);
    }

    if (req.method == 'POST' && path.endsWith('/answers/')) {
      await Future.delayed(latency);
      if (answerStatus != 200) {
        return _json({'detail': 'boom'}, answerStatus);
      }
      if (completed) {
        return _json({'detail': 'SESSION_COMPLETED'}, 409);
      }
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final answer = body['answer'] as Map;
      if (_judge(answer)) {
        score += 10;
        return _json({
          'data': _advance({'is_correct': true, 'remaining_attempts': 3}),
        });
      }
      attempts--;
      if (attempts > 0) {
        return _json({
          'data': {
            'is_correct': false,
            'retry': true,
            'is_completed': false,
            'remaining_attempts': attempts,
            'current_score': score,
          },
        });
      }
      return _json({
        'data': _advance({
          'is_correct': false,
          'retry': false,
          'remaining_attempts': 0,
        }),
      });
    }

    if (req.method == 'GET' && path == '$kBase/history/') {
      await Future.delayed(latency);
      if (historyStatus != 200) return _json({'detail': 'boom'}, historyStatus);
      return _json({
        'data': {
          'history': [
            {'final_score': 40, 'created_at': '2026-10-20T10:00:00'},
            {'final_score': 95, 'created_at': '2026-10-21T10:00:00'},
            {'final_score': 60, 'created_at': '2026-10-22T10:00:00'},
            if (completed)
              {'final_score': score, 'created_at': '2026-10-26T10:00:00'},
          ],
        },
      });
    }

    return _json({'detail': 'not found: ${req.method} $path'}, 404);
  }

  MockClient client() => MockClient(handle);
}

// ====================================================================
// 測試工具（從 playthrough 測試複製）
// ====================================================================

Widget buildApp() {
  return MaterialApp(
    home: Builder(
      builder: (rootCtx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              rootCtx,
              MaterialPageRoute(builder: (_) => const _GameHomeStub()),
            ),
            child: const Text('ROOT_HOME'),
          ),
        ),
      ),
    ),
  );
}

class _GameHomeStub extends StatelessWidget {
  const _GameHomeStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME_HOME'),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FridgeTutorialPage()),
              ),
              child: const Text('OPEN_FRIDGE'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FridgeGamePage()),
              ),
              child: const Text('OPEN_FRIDGE_GAME'),
            ),
          ],
        ),
      ),
    );
  }
}

const int kNav = 1200;

Future<void> wait(WidgetTester t, int ms) async {
  var left = ms;
  while (left > 0) {
    final step = left > 50 ? 50 : left;
    await t.pump(Duration(milliseconds: step));
    left -= step;
  }
  await t.pump();
}

Future<void> waitApi(WidgetTester t) => wait(t, 260);

/// 手機 360x780 邏輯像素（直向）
Future<void> setPhone(WidgetTester t) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> openGame(WidgetTester t) async {
  await t.pumpWidget(buildApp());
  await t.tap(find.text('ROOT_HOME'));
  await wait(t, kNav);
  await t.tap(find.text('OPEN_FRIDGE_GAME'));
  await wait(t, kNav);
  await waitApi(t);
  await wait(t, 300);
}

Future<void> openTutorial(WidgetTester t) async {
  await t.pumpWidget(buildApp());
  await t.tap(find.text('ROOT_HOME'));
  await wait(t, kNav);
  await t.tap(find.text('OPEN_FRIDGE'));
  await wait(t, kNav);
}

Future<void> disposeApp(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await wait(t, 100);
}

/// 在困難題把番茄放到 r2c2（雞蛋 r2c1 與 牛奶 r2c3 中間）
Future<void> placeTomatoAt(WidgetTester t, {bool correct = true}) async {
  await t.tap(find.text('番茄'));
  await t.pump();
  if (correct) {
    final a = t.getCenter(find.text('雞蛋'));
    final b = t.getCenter(find.text('牛奶'));
    await t.tapAt(Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
  } else {
    await t.tap(find.text('豆腐'));
  }
}

Future<void> tapAnswer(
  WidgetTester t,
  String diff, {
  bool correct = true,
}) async {
  if (diff == 'easy') {
    await t.tap(find.text(correct ? '豆腐' : '雞蛋'));
  } else if (diff == 'medium') {
    await t.tap(find.text('雞蛋').at(correct ? 4 : 0));
  } else {
    await placeTomatoAt(t, correct: correct);
  }
}

// ====================================================================
// 測試
// ====================================================================

void main() {
  late TestDefaultBinaryMessenger messenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel.startsWith('xyz.luan/audioplayers') ||
          channel.contains('path_provider')) {
        return Future.value(
          const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      if (handler != null) return handler(message);
      return messenger.delegate.send(channel, message);
    };
  });

  tearDown(() {
    messenger.allMessagesHandler = null;
  });

  /// 走過所有畫面並檢查。[tag] 會加在畫面名稱後面（用來區分字體倍率）。
  Future<void> flow(WidgetTester t, A11yReport a11y, String tag) async {
    String n(String s) => tag.isEmpty ? s : '$s $tag';
    final errors = <String>[];
    final origOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      final loc = RegExp(
        r'(lib/[^\s:]+\.dart:\d+:\d+)',
      ).firstMatch(d.toString())?.group(1);
      errors.add('${d.exceptionAsString().split('\n').first}  @ ${loc ?? '?'}');
    };

    try {
      // ---------------- 遊戲首頁（入口）----------------
      await http.runWithClient(() async {
        await t.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => const GameHomeScreen()),
                  ),
                  child: const Text('ROOT_HOME'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('ROOT_HOME'));
        await wait(t, kNav);
        await a11y.check(t, n('遊戲首頁（入口）'));
        await t.tap(find.text('視覺空間'));
        await wait(t, kNav);
        expect(find.byType(FridgeTutorialPage), findsOneWidget);
      }, FakeFridgeBackend().client);
      await wait(t, 1500);
      await disposeApp(t);

      // ---------------- 教學 6 頁 + 完成視窗 ----------------
      final backend = FakeFridgeBackend();
      await http.runWithClient(() async {
        await openTutorial(t);
        expect(find.text('簡單難度玩法教學'), findsOneWidget);
        await a11y.check(t, n('教學：簡單難度提示浮層'));
        await wait(t, 1500);
        expect(find.text('1 / 6'), findsOneWidget);
        await a11y.check(t, n('教學 第1頁'));
        for (var i = 2; i <= 6; i++) {
          await t.tap(find.text('下一步'));
          await wait(t, 400);
          if (i == 3 || i == 5) {
            expect(find.textContaining('難度玩法教學'), findsOneWidget);
            await a11y.check(t, n('教學：${i == 3 ? '中等' : '困難'}難度提示浮層'));
            await wait(t, 1500);
          } else {
            await wait(t, 300);
          }
          expect(find.text('$i / 6'), findsOneWidget);
          await a11y.check(t, n('教學 第$i頁'));
        }
        await t.tap(find.text('下一步'));
        await t.pump();
        expect(find.text('所有難度教學已完成'), findsOneWidget);
        await a11y.check(t, n('教學完成視窗'));

        // 開始遊戲 → 完整 10 題
        await t.tap(find.text('開始遊戲'));
        await wait(t, kNav);
        await waitApi(t);
        await wait(t, 300);

        // ---------------- 遊戲：簡單 ----------------
        expect(find.text('1/10'), findsOneWidget);
        await a11y.check(t, n('作答 簡單題'));

        // 答錯回饋
        await tapAnswer(t, 'easy', correct: false);
        await waitApi(t);
        await a11y.check(t, n('作答 答錯回饋（簡單題）'));
        await wait(t, 700);

        // 答對回饋
        await tapAnswer(t, 'easy');
        await waitApi(t);
        expect(find.byIcon(Icons.check), findsOneWidget);
        await a11y.check(t, n('作答 答對回饋（簡單題）'));
        await wait(t, 900);
        expect(find.text('2/10'), findsOneWidget);

        // Q2-Q4 簡單題
        for (var i = 0; i < 3; i++) {
          await tapAnswer(t, 'easy');
          await waitApi(t);
          await wait(t, 900);
        }

        // ---------------- 遊戲：中等 ----------------
        expect(find.text('5/10'), findsOneWidget);
        expect(find.text('中等難度'), findsOneWidget);
        await a11y.check(t, n('作答 中等題'));
        await tapAnswer(t, 'medium', correct: false);
        await waitApi(t);
        await a11y.check(t, n('作答 答錯回饋（中等題）'));
        await wait(t, 700);
        await tapAnswer(t, 'medium');
        await waitApi(t);
        await a11y.check(t, n('作答 答對回饋（中等題）'));
        await wait(t, 900);
        for (var i = 0; i < 2; i++) {
          await tapAnswer(t, 'medium');
          await waitApi(t);
          await wait(t, 900);
        }

        // ---------------- 遊戲：困難 ----------------
        expect(find.text('8/10'), findsOneWidget);
        expect(find.text('困難難度'), findsOneWidget);
        await a11y.check(t, n('作答 困難題'));

        // 沒選食材先點格子 → SnackBar 提示
        await t.tap(find.text('豆腐'));
        await t.pump();
        expect(find.text('請先點擊下方待放入的食材！'), findsOneWidget);
        await a11y.check(t, n('作答 困難題 提示 SnackBar'));
        await wait(t, 1500);

        // 選取食材後
        await t.tap(find.text('番茄'));
        await t.pump();
        await a11y.check(t, n('作答 困難題 已選取食材'));

        // 放錯 / 放對
        await t.tap(find.text('豆腐'));
        await waitApi(t);
        await a11y.check(t, n('作答 答錯回饋（困難題）'));
        await wait(t, 700);
        await placeTomatoAt(t);
        await waitApi(t);
        await a11y.check(t, n('作答 答對回饋（困難題）'));
        await wait(t, 900);

        // ---------------- 暫停選單 ----------------
        await t.tap(find.text('選單'));
        await wait(t, 300);
        expect(find.text('遊戲暫停'), findsOneWidget);
        await a11y.check(t, n('暫停選單'));
        await t.tap(find.text('繼續遊戲'));
        await wait(t, 300);

        // Q9、Q10
        await tapAnswer(t, 'hard');
        await waitApi(t);
        await wait(t, 900);
        expect(find.text('10/10'), findsOneWidget);
        await tapAnswer(t, 'hard');
        await waitApi(t);
        await wait(t, kNav);
        await waitApi(t);

        // ---------------- 結算頁（含歷史圖表）----------------
        expect(find.byType(FridgeResultPage), findsOneWidget);
        expect(find.text('成績結算'), findsOneWidget);
        await a11y.check(t, n('成績結算頁（含歷史成績圖表）'));
      }, backend.client);
      await disposeApp(t);

      // ---------------- 成績頁：歷史成績載入失敗 ----------------
      final histBackend = FakeFridgeBackend(startQ: 10)..historyStatus = 500;
      await http.runWithClient(() async {
        await openGame(t);
        await tapAnswer(t, 'hard');
        await waitApi(t);
        await wait(t, kNav);
        await waitApi(t);
        expect(find.text('目前無法取得歷史成績'), findsOneWidget);
        await a11y.check(t, n('成績結算頁（歷史成績載入失敗）'));
      }, histBackend.client);
      await disposeApp(t);

      // ---------------- 錯誤 / 重新連線（500）----------------
      final errBackend = FakeFridgeBackend()..startStatus = 500;
      await http.runWithClient(() async {
        await openGame(t);
        expect(find.text('重新連線'), findsOneWidget);
        await a11y.check(t, n('錯誤畫面（建立 session 500）'));
      }, errBackend.client);
      await disposeApp(t);
    } finally {
      FlutterError.onError = origOnError;
    }
    final uniq = errors.toSet().toList();
    // ignore: avoid_print
    print(
      '[FlutterError ${tag.isEmpty ? '字體1.0' : tag}] ${uniq.isEmpty ? '無' : '\n${uniq.join('\n')}'}',
    );
    // 字體 1.0 不該有任何框架錯誤；放大字體的版面溢出只印出來（屬版面問題，不是無障礙 guideline）
    if (tag.isEmpty) expect(errors, isEmpty, reason: errors.join('\n'));
  }

  testWidgets('冰箱盤點 無障礙檢查：每個畫面（字體 1.0 與 1.3）', (t) async {
    await setPhone(t);
    final a11y = A11yReport('冰箱盤點');

    t.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await flow(t, a11y, '');

    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    await flow(t, a11y, '[字體1.3x]');

    a11y.finish();
  });
}
