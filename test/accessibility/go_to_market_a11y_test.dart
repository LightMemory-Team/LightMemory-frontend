// 來去菜市場（go_to_market）無障礙檢查
//
// 用 test/accessibility/a11y_check.dart 對遊戲的每個不同畫面／狀態各跑一次
// Flutter 內建 guideline（androidTapTarget / iOSTapTarget / labeledTapTarget /
// textContrast）。遊玩流程與假後端複製自 test/playthrough/go_to_market_playthrough_test.dart。
//
// 預設只收集違規、印出報告（build/a11y_report/來去菜市場.txt），測試不會失敗；
// 加上 --dart-define=A11Y_STRICT=true 才會因違規而失敗。
//
// 檢查三輪：
//   1. 一般手機橫向 780x360（遊戲實機的方向與尺寸）
//   2. 小手機橫向 640x360
//   3. 780x360 + 文字放大 1.3 倍
// 每輪都走：教學（每階段橫幅 + 每一步 + 完成對話框）→ 遊戲（閃現 / 作答 / 答錯可重看 /
// 答對 / 逾時 / 連錯三次 / 兩次升階對話框 / 高階含干擾物 / 暫停選單 / 結算視窗）
// → 登入過期（401）對話框 → 後端無回應的載入畫面。
// GoToMarketEntryPage 沒有 UI，不檢查。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/features/game/go_to_market/pages/go_to_market_game_page.dart';
import 'package:light_memory/features/game/go_to_market/pages/go_to_market_tutorial_page.dart';

import 'a11y_check.dart';

// ───────────────────────── 畫面文字 ─────────────────────────
const kExposeText = '注意看！記住魚出現的位置！';
const kAnswerText = '請點擊剛剛魚出現的位置！';
const kRetryBtn = '重看題目';
const kNextQBtn = '進入下一題';
const kScoreLabel = '本次分數';

const quadrants = ['q1', 'q2', 'q3', 'q4'];

// ───────────────────────── 假後端（複製自 playthrough） ─────────────────────────
class FakeMarketBackend {
  int? failStatus; // 所有請求回這個 status
  bool hang = false; // 永遠不回應（觸發 4 秒 timeout）

  int _sessionSeq = 0;
  String? session;
  int q = 1;
  String stage = 'basic';
  int correctStreak = 0;
  int wrongInQ = 0;
  int score = 0;

  String targetFor(int q, String stage) =>
      stage == 'basic' ? 'center' : quadrants[q % 4];

  String get currentTarget => targetFor(q, stage);

  http.Response _ok(Object? data) => http.Response(
    jsonEncode({'success': true, 'data': data, 'error': null}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path;
    if (hang) return Completer<http.Response>().future;
    if (failStatus != null) {
      return http.Response(
        jsonEncode({
          'success': false,
          'data': null,
          'error': {'code': 'SERVER_ERROR', 'message': 'boom'},
        }),
        failStatus!,
      );
    }
    if (req.headers['Authorization'] == null) {
      return http.Response('{"detail":"no auth"}', 401);
    }

    if (path.endsWith('/start/')) {
      session = 'uuid-${++_sessionSeq}';
      q = 1;
      stage = 'basic';
      correctStreak = 0;
      wrongInQ = 0;
      score = 0;
      return _ok({'session_id': session});
    }
    if (path.endsWith('/round/answer/')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final isTimeout = body['is_timeout'] == true;
      final correct = !isTimeout && body['answer_position'] == currentTarget;
      final last = q >= 20;
      int earned = 0;
      String action;
      if (correct) {
        earned = 10;
        score += 10;
        correctStreak++;
        if (last) {
          action = 'finished';
        } else if (correctStreak >= 5 && stage != 'advanced') {
          stage = stage == 'basic' ? 'intermediate' : 'advanced';
          correctStreak = 0;
          action = 'promoted';
        } else {
          action = 'next_question';
        }
      } else {
        correctStreak = 0;
        wrongInQ++;
        if (last) {
          action = 'finished';
        } else if (wrongInQ >= 3 || isTimeout) {
          action = 'next_question';
        } else {
          action = 'retry';
        }
      }
      if (action != 'retry') {
        q++;
        wrongInQ = 0;
      }
      return _ok({
        'is_correct': correct,
        'action': action,
        'current_stage': stage,
        'correct_streak': correctStreak,
        'wrong_attempts': wrongInQ,
        'score_earned': earned,
        'fast_correct_streak': 0,
      });
    }
    if (path.endsWith('/round/')) {
      return _ok({
        'question_number': q,
        'stage': stage,
        'target_item': stage == 'basic'
            ? '魚'
            : (stage == 'intermediate' ? '鮭魚' : '鱸魚'),
        'target_position': currentTarget,
        'distractor_items': stage == 'advanced'
            ? [
                {'item': '魚骨頭', 'position': quadrants[(q + 2) % 4]},
              ]
            : [],
        'exposure_time_ms': stage == 'basic'
            ? 2000
            : (stage == 'intermediate' ? 1500 : 1000),
      });
    }
    if (path.endsWith('/finish/')) {
      return _ok({
        'total_questions': 20,
        'answered_count': 20,
        'correct_count': score ~/ 10,
        'timeout_count': 0,
        'accuracy': 0.5,
        'avg_response_time_ms': 800,
        'final_stage': stage,
        'total_score': score,
      });
    }
    if (path.endsWith('/config/')) return _ok({'total_questions': 20});
    return http.Response('not found', 404);
  }
}

// ───────────────────────── 測試環境（複製自 playthrough） ─────────────────────────

/// audioplayers 的 platform channel 全部回成功（null），其他 channel 照原本的 mock 走。
void installAudioChannelStub() {
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

/// 收集 FlutterError（overflow、build 例外等），不讓第一個錯誤就中斷流程
class ErrorCollector {
  final List<FlutterErrorDetails> errors = [];
  FlutterExceptionHandler? _orig;
  void start() {
    _orig = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d);
  }

  void stop() {
    FlutterError.onError = _orig;
  }

  List<String> get summaries => errors
      .map((e) => e.exceptionAsString().split('\n').take(2).join(' | '))
      .toList(growable: false);
}

DebugPrintCallback? _savedDebugPrint;

void silenceDebugPrint() {
  _savedDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {};
}

void restoreDebugPrint() {
  if (_savedDebugPrint != null) debugPrint = _savedDebugPrint!;
}

void setSurface(WidgetTester tester, Size logical, {double dpr = 3}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
}

const landscapePhone = Size(780, 360); // 1080x2340 @3x 橫向（遊戲實機的方向）
const smallLandscape = Size(640, 360); // 360x640 小手機 橫向

/// 在 http zone 裡跑整個流程；FlutterError（overflow 等）只印出，不讓測試失敗
Future<void> runGame(
  WidgetTester tester,
  FakeMarketBackend backend,
  Future<void> Function() body,
) async {
  final errors = ErrorCollector()..start();
  silenceDebugPrint();
  try {
    await http.runWithClient(() async {
      await body();
      // 把所有遊戲頁拆掉，跑完殘留的 Future.delayed／Timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    }, () => MockClient((req) => backend.handle(req)));
  } finally {
    errors.stop();
    restoreDebugPrint();
  }
  if (errors.summaries.isNotEmpty) {
    // ignore: avoid_print
    print(
      '── FlutterErrors (${errors.summaries.length}) ──\n'
      '${errors.summaries.toSet().join('\n')}',
    );
  }
}

Widget simpleHost() {
  return MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const GoToMarketTutorialPage(),
              ),
            ),
            child: const Text('OPEN_MARKET'),
          ),
        ),
      ),
    ),
  );
}

// ───────────────────────── 操作 helper ─────────────────────────

Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() cond, {
  Duration step = const Duration(milliseconds: 100),
  int maxSteps = 400,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (cond()) return true;
    await tester.pump(step);
  }
  return cond();
}

bool has(Finder f) => f.evaluate().isNotEmpty;

Finder get boardFinder => find.byWidgetPredicate(
  (w) => w is SizedBox && w.width == 480.0 && w.height == 150.0,
);

Finder get fishFinder => find.descendant(of: boardFinder, matching: _fishImage);

Finder get _fishImage => find.byWidgetPredicate((w) {
  if (w is! Image || w.image is! AssetImage) return false;
  final name = (w.image as AssetImage).assetName;
  return name.contains('fish') && !name.contains('bone');
});

String quadrantOfFish(WidgetTester tester) {
  final b = tester.getRect(boardFinder);
  final f = tester.getCenter(fishFinder.first);
  final dx = f.dx - b.center.dx;
  final dy = f.dy - b.center.dy;
  if (dx.abs() < 20 && dy.abs() < 20) return 'center';
  if (dy < 0) return dx > 0 ? 'q1' : 'q2';
  return dx > 0 ? 'q4' : 'q3';
}

Offset offsetOf(WidgetTester tester, String pos) {
  final b = tester.getRect(boardFinder);
  switch (pos) {
    case 'center':
      return b.center;
    case 'q1':
      return Offset(b.left + b.width * 0.88, b.top + b.height * 0.2);
    case 'q2':
      return Offset(b.left + b.width * 0.12, b.top + b.height * 0.2);
    case 'q3':
      return Offset(b.left + b.width * 0.12, b.top + b.height * 0.8);
    default:
      return Offset(b.left + b.width * 0.88, b.top + b.height * 0.8);
  }
}

String wrongOf(String target) => target == 'q1' ? 'q3' : 'q1';

/// 等閃現開始（魚出現），回傳魚的位置。呼叫完畫面停在閃現中。
Future<String> waitExposure(WidgetTester tester) async {
  expect(
    await pumpUntil(
      tester,
      () => has(find.text(kExposeText)) && has(fishFinder),
    ),
    isTrue,
    reason: '閃現沒有開始（卡住？）',
  );
  return quadrantOfFish(tester);
}

/// 等到可以作答
Future<void> waitAnswer(WidgetTester tester) async {
  expect(
    await pumpUntil(tester, () => has(find.text(kAnswerText))),
    isTrue,
    reason: '閃現結束後沒有進入作答',
  );
}

/// 讓剛出現的 Dialog／按鈕顏色動畫跑完再檢查（pump 一次大 duration 只會讓動畫停在起點，
/// 第一個 frame 才是動畫起點，所以要先 pump 一個 frame 再 pump 一段時間）。
/// 只能用在計時器不會往前走的畫面（教學、Dialog），遊戲進行中的畫面不要用。
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> tapPos(WidgetTester tester, String pos) async {
  await tester.tapAt(offsetOf(tester, pos));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

/// 答對一題，等到下一題／升階對話框／結算出現。回傳 'next' / 'transition' / 'result'
Future<String> answerCorrect(WidgetTester tester) async {
  final target = await waitExposure(tester);
  await waitAnswer(tester);
  await tapPos(tester, target);
  return _afterAnswer(tester);
}

Future<String> _afterAnswer(WidgetTester tester) async {
  final ok = await pumpUntil(
    tester,
    () =>
        has(find.text(kNextQBtn)) ||
        has(find.text(kScoreLabel)) ||
        has(find.text(kExposeText)),
    maxSteps: 100,
  );
  expect(ok, isTrue, reason: '作答後卡住，沒有下一題／升階／結算');
  if (has(find.text(kNextQBtn))) return 'transition';
  if (has(find.text(kScoreLabel))) return 'result';
  return 'next';
}

/// 答錯一次，等到出現「重看題目」（第 3 次錯則等到下一題出現）
Future<void> answerWrong(WidgetTester tester, {required bool third}) async {
  final target = await waitExposure(tester);
  await waitAnswer(tester);
  await tapPos(tester, wrongOf(target));
  await tester.pump(const Duration(milliseconds: 50));
}

// ───────────────────────── 教學頁走訪 ─────────────────────────

Future<void> tutorialChecks(
  WidgetTester tester,
  A11yReport a11y,
  String tag,
) async {
  const stageNames = ['簡單', '中等', '高階'];
  const stepCounts = [3, 3, 4];
  for (var s = 0; s < 3; s++) {
    // 階段橫幅（黑色遮罩 + 綠色標題卡）蓋住整頁約 1.6 秒
    await a11y.check(tester, '$tag 教學-${stageNames[s]}難度 階段橫幅');
    await tester.pump(const Duration(milliseconds: 1700));
    for (var st = 0; st < stepCounts[s]; st++) {
      var name = '$tag 教學-${stageNames[s]}難度 第${st + 1}步';
      if (s == 2 && st == 0) name += '（目標物／干擾物辨識卡）';
      await a11y.check(tester, name);
      await tester.tap(find.text('下一步'));
      await settle(tester);
    }
  }
  // 最後一步按「下一步」後會跳完成對話框
  expect(find.text('全難度教學完成！'), findsOneWidget);
  await a11y.check(tester, '$tag 教學-完成對話框');
}

// ───────────────────────── 主流程 ─────────────────────────

Future<void> mainFlow(WidgetTester tester, A11yReport a11y, String tag) async {
  await tester.pumpWidget(simpleHost());
  await tester.tap(find.text('OPEN_MARKET'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  await tutorialChecks(tester, a11y, tag);

  await tester.tap(find.text('開始挑戰 20 題'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(GoToMarketGamePage), findsOneWidget);

  // Q1：初階。閃現中 → 作答 → 答錯（可重看）→ 重看 → 答對
  var target = await waitExposure(tester);
  await a11y.check(tester, '$tag 遊戲-閃現中（初階）');
  await waitAnswer(tester);
  await a11y.check(tester, '$tag 遊戲-作答階段');
  await tapPos(tester, wrongOf(target));
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.text(kRetryBtn), findsOneWidget);
  await a11y.check(tester, '$tag 遊戲-答錯回饋（可重看，第 1 次）');
  await tester.tap(find.text(kRetryBtn));
  await tester.pump();
  target = await waitExposure(tester);
  await waitAnswer(tester);
  await tapPos(tester, target);
  expect(
    await pumpUntil(tester, () => has(find.text('太棒了！答對了！')), maxSteps: 30),
    isTrue,
    reason: '沒有出現答對回饋',
  );
  await a11y.check(tester, '$tag 遊戲-答對回饋');
  await _afterAnswer(tester);

  // Q2：逾時
  await waitExposure(tester);
  await waitAnswer(tester);
  await tester.pump(const Duration(seconds: 21));
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.text('答錯囉！請看魚的正確位置'), findsOneWidget);
  await a11y.check(tester, '$tag 遊戲-逾時回饋');
  // 逾時後 1.2 秒自動跳下一題
  expect(
    await pumpUntil(tester, () => has(find.text(kExposeText)), maxSteps: 50),
    isTrue,
    reason: '逾時後沒有跳下一題',
  );

  // Q3：連錯三次
  for (var i = 0; i < 2; i++) {
    await answerWrong(tester, third: false);
    expect(
      await pumpUntil(tester, () => has(find.text(kRetryBtn)), maxSteps: 20),
      isTrue,
    );
    await tester.tap(find.text(kRetryBtn));
    await tester.pump();
  }
  await answerWrong(tester, third: true);
  expect(find.text('答錯三次囉！準備進入下一題'), findsOneWidget);
  await a11y.check(tester, '$tag 遊戲-答錯回饋（第 3 次，不可重看）');
  expect(
    await pumpUntil(tester, () => has(find.text(kExposeText)), maxSteps: 50),
    isTrue,
    reason: '連錯三次後沒有跳下一題',
  );

  // Q4-Q8 連對 5 → 升階（中階）
  var state = '';
  for (var i = 0; i < 5; i++) {
    state = await answerCorrect(tester);
  }
  expect(state, 'transition', reason: '連對 5 題應出現升階對話框');
  await settle(tester);
  await a11y.check(tester, '$tag 升階對話框（初階→中階）');
  await tester.tap(find.text(kNextQBtn));
  await tester.pump();

  // 中階：閃現中、作答階段各檢查一次，這題答對後繼續答對到升階（高階）
  target = await waitExposure(tester);
  await a11y.check(tester, '$tag 遊戲-閃現中（中階，魚在四個角落）');
  await waitAnswer(tester);
  await a11y.check(tester, '$tag 遊戲-作答階段（中階）');
  await tapPos(tester, target);
  state = await _afterAnswer(tester);
  var guard = 0;
  while (state != 'transition' && guard++ < 12) {
    state = await answerCorrect(tester);
  }
  expect(state, 'transition', reason: '中階連對 5 題應升到高階');
  await settle(tester);
  await a11y.check(tester, '$tag 升階對話框（中階→高階）');
  await tester.tap(find.text(kNextQBtn));
  await tester.pump();

  // 高階：閃現中（含干擾物魚骨頭）
  target = await waitExposure(tester);
  expect(
    find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName.contains('bone'),
    ),
    findsOneWidget,
    reason: '高階應該出現干擾物',
  );
  await a11y.check(tester, '$tag 遊戲-閃現中（高階，含干擾物）');
  await waitAnswer(tester);

  // 暫停選單（作答階段打開）
  await tester.tap(find.text('選單'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('遊戲暫停'), findsOneWidget);
  await settle(tester);
  await a11y.check(tester, '$tag 暫停選單');
  await tester.tap(find.text('繼續遊戲'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('遊戲暫停'), findsNothing);

  // 把這題答對，之後一路答對到結算
  await tapPos(tester, target);
  state = await _afterAnswer(tester);
  guard = 0;
  while (state != 'result' && guard++ < 30) {
    state = await answerCorrect(tester);
  }
  expect(state, 'result', reason: '應該玩到結算');
  await settle(tester);
  await a11y.check(tester, '$tag 結算視窗');
}

// ───────────────────────── 錯誤／載入狀態 ─────────────────────────

Future<void> skipTutorialIntoGame(WidgetTester tester) async {
  await tester.pumpWidget(simpleHost());
  await tester.tap(find.text('OPEN_MARKET'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  // 階段橫幅蓋住整頁 1.6 秒，期間點「略過教學」只會關掉橫幅
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.tap(find.text('略過教學'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(GoToMarketGamePage), findsOneWidget);
}

Future<void> unauthorizedFlow(
  WidgetTester tester,
  A11yReport a11y,
  String tag,
) async {
  await skipTutorialIntoGame(tester);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('登入已過期'), findsOneWidget);
  await settle(tester);
  await a11y.check(tester, '$tag 錯誤狀態-登入已過期對話框（401）');
  await tester.tap(find.text('繼續練習'));
  await tester.pump(const Duration(milliseconds: 300));
  await waitExposure(tester);
}

Future<void> loadingFlow(
  WidgetTester tester,
  A11yReport a11y,
  String tag,
) async {
  await skipTutorialIntoGame(tester);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await a11y.check(tester, '$tag 載入中（後端無回應）');
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 1200));
  expect(find.text(kExposeText), findsOneWidget, reason: '逾時後應改本地模式開始');
}

// ───────────────────────── 測試 ─────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    installAudioChannelStub();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
  });

  testWidgets('來去菜市場：每個畫面跑 Flutter 無障礙 guideline', (tester) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final a11y = A11yReport('來去菜市場');

    final passes = <(String, Size, double)>[
      ('[780x360]', landscapePhone, 1.0),
      ('[640x360]', smallLandscape, 1.0),
      ('[780x360 字體1.3x]', landscapePhone, 1.3),
    ];

    for (final (tag, size, scale) in passes) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      setSurface(tester, size);

      await runGame(tester, FakeMarketBackend(), () async {
        await mainFlow(tester, a11y, tag);
      });

      SharedPreferences.setMockInitialValues({'access_token': 'test'});
      await runGame(tester, FakeMarketBackend()..failStatus = 401, () async {
        await unauthorizedFlow(tester, a11y, tag);
      });

      await runGame(tester, FakeMarketBackend()..hang = true, () async {
        await loadingFlow(tester, a11y, tag);
      });
    }

    a11y.finish();
  });
}
