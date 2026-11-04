// 料理準備（cooking_prep）無障礙 widget test。
//
// 沿用 playthrough 測試的 FakeBackend／插件 channel stub，走完整個遊戲流程，
// 在每個不同的畫面／狀態呼叫 A11yReport.check（androidTapTarget、iOSTapTarget、
// labeledTapTarget、textContrast）。預設只收集違規、不讓測試失敗；
// 加 --dart-define=A11Y_STRICT=true 才會因違規失敗。報告寫到 build/a11y_report/。
//
// 遊戲頁鎖橫向，所以用 780x360（跟 playthrough 測試相同）。主要畫面另外再用
// textScaleFactor 1.3 檢查一次。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/core/services/audio_service.dart';
import 'package:light_memory/features/game/cooking_prep/pages/cooking_prep_game_page.dart';

import 'package:light_memory/features/game/cooking_prep/widgets/chopping_reward_scene.dart';
import 'package:light_memory/features/game/cooking_prep/widgets/seasoning_soup_reward_scene.dart';

import 'a11y_check.dart';

// ───────────────────────── Fake backend（複製自 playthrough 測試）─────────────────────────

const Map<String, List<String>> kPools = {
  'basic': ['馬鈴薯', '胡蘿蔔', '洋蔥'],
  'intermediate': ['辣椒粉', '鮮奶油', '咖哩塊'],
  'advanced': ['馬鈴薯塊', '馬鈴薯泥', '紅蘿蔔塊', '紅蘿蔔片', '洋蔥圈', '洋蔥絲'],
};
const Map<String, String> kNextStage = {
  'basic': 'intermediate',
  'intermediate': 'advanced',
};
final List<String> kAllItems = kPools.values.expand((e) => e).toList();

class FakeBackend {
  FakeBackend({
    this.pretest = false,
    this.pretestRounds = 4,
    this.promoteStreak = 2,
    this.bonus = 15,
    this.gameLength = const Duration(seconds: 600),
  });

  bool pretest;
  final int pretestRounds;
  final int promoteStreak;
  final int bonus;
  Duration gameLength;

  /// endpoint -> 依序消耗的故障：int(HTTP status) / 'network' / 'hang'
  final Map<String, List<Object>> faults = {};
  final Map<String, Duration> delays = {};

  /// 送出這一輪答案時回 GAME_TIME_UP（模擬正式賽時間到）
  int? timeUpAtRound;

  // 狀態
  int startCount = 0;
  int finishCount = 0;
  String? sessionId;
  bool sessionPretest = false;
  String stage = 'basic';
  int bridgeRound = -1;
  String bridgeStage = 'basic';
  List<String> chain = [];
  int servedRound = 0;
  List<String> currentOptions = [];
  int streak = 0;
  int correct = 0;
  int wrong = 0;
  int bonusTotal = 0;
  final List<int> rts = [];
  DateTime? expiresAt;
  bool finished = false;
  int _rot = 0;

  final List<String> log = [];
  final List<Map<String, dynamic>> answerBodies = [];
  final Map<String, int> roundCallsBySession = {};
  final Set<String> finishedSessions = {};

  String get rightAnswer => chain[servedRound - 1];

  http.Response _ok(Map<String, dynamic> data) => http.Response.bytes(
    utf8.encode(jsonEncode({'success': true, 'data': data, 'error': null})),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _err(int status, String code, String message) =>
      http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'success': false,
            'data': null,
            'error': {'code': code, 'message': message},
          }),
        ),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Future<http.Response> handle(http.Request req) async {
    // 先在「收到請求當下」算好回應，再模擬回程延遲（跟真實後端一致）
    final ep = _ep(req.url.path);
    final d = delays[ep];
    http.Response? resp;
    Object? err;
    try {
      resp = await _handle(req);
    } catch (e) {
      err = e;
    }
    if (d != null) await Future<void>.delayed(d);
    if (err != null) throw err;
    return resp!;
  }

  String _ep(String path) {
    if (path.endsWith('/round/answer/')) return 'answer';
    if (path.endsWith('/round/')) return 'round';
    if (path.endsWith('/config/')) return 'config';
    if (path.endsWith('/start/')) return 'start';
    if (path.endsWith('/finish/')) return 'finish';
    return 'other:$path';
  }

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path;
    final String ep;
    if (path.endsWith('/round/answer/')) {
      ep = 'answer';
    } else if (path.endsWith('/round/')) {
      ep = 'round';
    } else if (path.endsWith('/config/')) {
      ep = 'config';
    } else if (path.endsWith('/start/')) {
      ep = 'start';
    } else if (path.endsWith('/finish/')) {
      ep = 'finish';
    } else {
      ep = 'other:$path';
    }
    log.add(ep);
    if (req.headers['Authorization'] != 'Bearer test') {
      return _err(401, 'UNAUTHORIZED', 'no token');
    }
    final f = faults[ep];
    if (f != null && f.isNotEmpty) {
      final x = f.removeAt(0);
      if (x == 'network') {
        throw http.ClientException('Connection closed', req.url);
      }
      if (x == 'hang') return Completer<http.Response>().future;
      if (x is int) {
        return http.Response('<h1>Server Error ($x)</h1>', x);
      }
    }

    switch (ep) {
      case 'config':
        return _ok({
          'is_pretest': pretest,
          'current_stage': 'basic',
          'pretest_total_rounds': pretestRounds,
          'base_time_limit_seconds': gameLength.inSeconds,
          'promote_streak': promoteStreak,
          'promote_bonus_seconds': bonus,
        });
      case 'start':
        startCount++;
        sessionId = 's$startCount';
        sessionPretest = pretest;
        stage = 'basic';
        bridgeRound = -1;
        chain = [kPools['basic']![startCount % 3]];
        servedRound = 0;
        currentOptions = [];
        streak = 0;
        correct = 0;
        wrong = 0;
        bonusTotal = 0;
        rts.clear();
        finished = false;
        expiresAt = sessionPretest ? null : DateTime.now().add(gameLength);
        return _ok({
          'session_id': sessionId,
          'is_pretest': sessionPretest,
          'current_stage': stage,
          'expires_at': expiresAt?.toUtc().toIso8601String(),
          'seed_item': chain.first,
        });
      case 'round':
        final sid = req.url.queryParameters['session_id']!;
        roundCallsBySession[sid] = (roundCallsBySession[sid] ?? 0) + 1;
        if (sid != sessionId) {
          return _err(404, 'SESSION_NOT_FOUND', 'session not found');
        }
        if (finished) {
          return _err(400, 'SESSION_ALREADY_FINISHED', 'already finished');
        }
        servedRound++;
        final prev = chain.last;
        final pool = kPools[stage]!;
        String newItem;
        do {
          newItem = pool[_rot++ % pool.length];
        } while (newItem == prev);
        final distractor = pool.firstWhere(
          (x) => x != prev && x != newItem,
        );
        currentOptions = servedRound.isEven
            ? [prev, distractor]
            : [distractor, prev];
        chain.add(newItem);
        final reported = servedRound == bridgeRound ? bridgeStage : stage;
        return _ok({
          'round_number': servedRound,
          'stage': reported,
          'option_items': currentOptions,
          'new_item': newItem,
        });
      case 'answer':
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        answerBodies.add(body);
        if (body['session_id'] != sessionId) {
          return _err(404, 'SESSION_NOT_FOUND', 'session not found');
        }
        if (finished) {
          return _err(400, 'SESSION_ALREADY_FINISHED', 'already finished');
        }
        if (body['round_number'] != servedRound) {
          return _err(400, 'ROUND_MISMATCH', 'round mismatch');
        }
        if (timeUpAtRound == servedRound) {
          finished = true;
          return _err(400, 'GAME_TIME_UP', '遊戲時間已結束');
        }
        final ok = body['selected_item'] == chain[servedRound - 1];
        rts.add((body['response_time_ms'] as num).toInt());
        if (ok) {
          correct++;
          streak++;
        } else {
          wrong++;
          streak = 0;
        }
        String action = 'next_question';
        int granted = 0;
        if (sessionPretest) {
          if (servedRound >= pretestRounds) action = 'finished';
        } else if (ok && streak >= promoteStreak && kNextStage[stage] != null) {
          action = 'promoted';
          bridgeStage = stage;
          bridgeRound = servedRound + 1;
          stage = kNextStage[stage]!;
          streak = 0;
          granted = bonus;
          bonusTotal += bonus;
          expiresAt = expiresAt?.add(Duration(seconds: bonus));
        }
        return _ok({
          'is_correct': ok,
          'action': action,
          'current_stage': stage,
          'correct_streak': streak,
          'bonus_seconds_granted': granted,
          'expires_at': expiresAt?.toUtc().toIso8601String(),
          'score_earned': ok ? 10 : 0,
        });
      case 'finish':
        finishCount++;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        finishedSessions.add(body['session_id'].toString());
        finished = true;
        if (sessionPretest) pretest = false; // 結束過一場，下次就是正式賽
        final total = correct + wrong;
        return _ok({
          'total_rounds': total,
          'total_correct': correct,
          'total_wrong': wrong,
          'accuracy': total == 0 ? 0.0 : correct / total,
          'avg_response_time_ms': rts.isEmpty
              ? 0
              : rts.reduce((a, b) => a + b) ~/ rts.length,
          'final_stage': stage,
          'total_bonus_seconds': bonusTotal,
          'total_score': sessionPretest ? null : correct * 10,
        });
    }
    return http.Response('not found', 404);
  }
}

// ───────────────────────── Harness ─────────────────────────

class H {
  H(this.t, this.b, this.a11y);
  final WidgetTester t;
  final FakeBackend b;
  final A11yReport a11y;
  final List<String> errors = [];
  final List<String> overflows = [];
  final List<String> unreached = [];
  String currentScreen = '';

  bool has(Finder f) => f.evaluate().isNotEmpty;

  Future<void> step([int ms = 100]) async {
    await t.pump(Duration(milliseconds: ms));
    final e = t.takeException();
    if (e != null) errors.add('UNCAUGHT: $e');
  }

  Future<void> wait(int ms) async {
    for (var e = 0; e < ms; e += 100) {
      await step(100);
    }
  }

  Future<bool> until(bool Function() c, {int maxMs = 20000, int stepMs = 100}) async {
    for (var e = 0; e <= maxMs; e += stepMs) {
      if (c()) return true;
      await step(stepMs);
    }
    return c();
  }

  bool optionsShown(int n) =>
      b.servedRound == n &&
      b.chain.length > n - 1 &&
      !has(find.text('請記住這個')) &&
      has(find.byKey(ValueKey<String>(b.chain[n - 1]))) &&
      !has(find.byType(Dialog));

  Future<bool> waitOptions(int n, {int maxMs = 20000}) =>
      until(() => optionsShown(n), maxMs: maxMs);

  Future<void> answer(bool correct) async {
    final right = b.rightAnswer;
    final pick = correct ? right : b.currentOptions.firstWhere((o) => o != right);
    await t.tap(find.byKey(ValueKey<String>(pick)));
    await step(50);
  }

  Future<void> tapText(String s) async {
    await t.tap(find.text(s).last);
    await step(50);
  }

  /// 檢查目前畫面；[scaled] 為 true 時另外用 textScaleFactor 1.3 再檢查一次。
  /// 檢查本身不會丟例外（A11yReport 內部已 try/catch），這裡再包一層以免整個流程中斷。
  Future<void> snap(String screen, {bool scaled = false}) async {
    try {
      currentScreen = screen;
      await a11y.check(t, screen);
      if (scaled) {
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        await step(50);
        await a11y.check(t, '$screen［字級1.3x］');
        t.platformDispatcher.clearTextScaleFactorTestValue();
        await step(50);
      }
    } catch (e) {
      errors.add('檢查「$screen」時出錯: $e');
      t.platformDispatcher.clearTextScaleFactorTestValue();
    }
    final ex = t.takeException();
    if (ex != null) errors.add('UNCAUGHT(snap $screen): $ex');
  }

  /// 條件成立才檢查，否則記為「沒走到」。
  Future<void> snapIf(bool reached, String screen, {bool scaled = false}) async {
    if (reached) {
      await snap(screen, scaled: scaled);
    } else {
      unreached.add(screen);
    }
  }

  Future<bool> waitTutorialPage(String marker) async {
    final ok = await until(() => has(find.text(marker)), maxMs: 3000);
    await wait(900); // 等 PageView 轉場結束
    return ok;
  }
}

void setSurface(WidgetTester t, Size logical) {
  t.view.devicePixelRatio = 3;
  t.view.physicalSize = logical * 3;
}

// ───────────────────────── Test ─────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) {
      if (channel == 'plugins.flutter.io/path_provider') {
        return Future.value(
          const StandardMethodCodec().encodeSuccessEnvelope(
            Directory.systemTemp.path,
          ),
        );
      }
      if (channel.startsWith('xyz.luan/audioplayers')) {
        return Future.value(
          const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      if (handler != null) return handler(message);
      return null;
    };
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
  });

  testWidgets('料理準備：每個畫面跑無障礙 guideline', (t) async {
    // audioplayers 的 channel 在測試環境被 stub，播放器永遠等不到就緒、
    // 留下 30 秒的 Timer 並在逾時後丟未捕捉的 TimeoutException。
    // 直接用公開的開關把音效關掉（與無障礙檢查無關）。
    AudioService.setEnabled(false);
    addTearDown(() => AudioService.setEnabled(true));
    final a11y = A11yReport('cooking_prep');
    // 前測 → 正式賽；每答對一題就升階（promoteStreak: 1），第 5 輪回 GAME_TIME_UP
    final b = FakeBackend(pretest: true, promoteStreak: 1)..timeUpAtRound = 5;
    // 第一次 config/、start/ 失敗 → 錯誤畫面
    b.faults['config'] = [500];
    b.faults['start'] = [500];
    final h = H(t, b, a11y);

    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final orig = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString().split('\n').first;
      if (msg.contains('overflowed')) {
        final where = RegExp(r'[\w/]+\.dart:\d+').firstMatch(d.toString())?.group(0) ?? '';
        h.overflows.add('$msg ${h.currentScreen} $where');
      } else {
        h.errors.add('FLUTTER_ERROR: $msg');
      }
    };

    try {
      await http.runWithClient(() async {
        setSurface(t, const Size(780, 360)); // 遊戲頁鎖橫向
        await t.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute(builder: (_) => const CookingPrepGamePage()),
                    ),
                    child: const Text('ENTER'),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('ENTER'));
        await h.step();

        // ── 開局讀取中
        await h.snap('開局讀取中（轉圈圈）');

        // ── 錯誤／重試畫面（start/ 500）
        final err = await h.until(() => h.has(find.text('重試')));
        await h.wait(600); // 等頁面進場轉場結束，否則截圖會抓到半透明的文字
        await h.snapIf(err, '錯誤重試畫面（start/ 500）', scaled: true);
        if (err) await h.tapText('重試');

        // ── 教學三頁
        final tut1 = await h.waitTutorialPage('基本玩法');
        await h.snapIf(tut1, '教學第1頁（基本玩法）', scaled: true);
        if (tut1) {
          await h.tapText('下一頁 →');
          final tut2 = await h.waitTutorialPage('三個關卡');
          await h.snapIf(tut2, '教學第2頁（三個關卡）');
          if (tut2) {
            await h.tapText('下一頁 →');
            final tut3 = await h.waitTutorialPage('限時挑戰');
            await h.snapIf(tut3, '教學第3頁（限時挑戰）');
            if (tut3) await h.tapText('開始遊戲 →');
          } else {
            h.unreached.add('教學第3頁（限時挑戰）');
          }
        } else {
          h.unreached.addAll(['教學第2頁（三個關卡）', '教學第3頁（限時挑戰）']);
        }
        await h.wait(300);

        // ── 前測第1輪：展示 seed、展示 P(1)、選項卡
        final pre1 = await h.until(() => h.has(find.text('請記住這個')), maxMs: 5000);
        await h.snapIf(pre1, '前測－物品展示（切菜場景）', scaled: true);
        final opt1 = await h.waitOptions(1);
        await h.snapIf(opt1, '前測－選項卡（練習題徽章）', scaled: true);
        if (opt1) {
          // 答錯後的回饋狀態（紅叉）
          await h.answer(false);
          await h.wait(300);
          await h.snap('前測－答錯後的選項卡回饋');
          await h.wait(2200);
        }
        // 暫停選單（前測展示階段）
        final pre2 = await h.until(() => h.has(find.text('請記住這個')), maxMs: 5000);
        if (pre2) {
          await h.tapText('選單');
          await h.wait(300);
          await h.snapIf(h.has(find.text('遊戲暫停')), '暫停選單', scaled: true);
          await h.tapText('繼續遊戲');
        } else {
          h.unreached.add('暫停選單');
        }
        // 前測第2~4輪直接答完
        for (var n = 2; n <= 4; n++) {
          final ok = await h.waitOptions(n);
          if (!ok) {
            h.unreached.add('前測第$n輪');
            break;
          }
          await h.answer(true);
          await h.wait(1200);
        }

        // ── 前測結束 → 正式賽第1輪（basic）
        final f1 = await h.until(() => b.startCount == 2, maxMs: 15000);
        if (!f1) h.unreached.add('正式賽');
        final prev = await h.until(() => h.has(find.text('請記住這個')), maxMs: 8000);
        await h.snapIf(prev, '正式賽－物品展示（切菜 basic）');
        final fo1 = await h.waitOptions(1);
        await h.snapIf(fo1, '正式賽－選項卡（含全域與單題時間條）', scaled: true);
        if (fo1) {
          await h.answer(true); // 答對 → 升調味 → 切菜 reward
          final r1 = await h.until(() => h.has(find.byType(ChoppingRewardScene)), maxMs: 4000);
          await h.snapIf(r1, '切菜獎勵動畫（答對）＋升階 SnackBar');
        } else {
          h.unreached.add('切菜獎勵動畫');
        }

        // 第2輪（basic，橋接輪）→ 答對 → 升烹飪
        final fo2 = await h.waitOptions(2);
        if (fo2) {
          await h.answer(true);
          await h.wait(500);
        } else {
          h.unreached.add('正式賽第2輪');
        }

        // 第3輪 intermediate：調味
        final p3 = await h.until(() => h.has(find.text('請記住這個')), maxMs: 8000);
        await h.snapIf(p3, '正式賽－物品展示（調味 intermediate）', scaled: true);
        final fo3 = await h.waitOptions(3);
        await h.snapIf(fo3, '正式賽－選項卡（調味）');
        if (fo3) {
          await h.answer(true);
          final r3 = await h.until(() => h.has(find.byType(SeasoningSoupRewardScene)), maxMs: 4000);
          await h.snapIf(r3, '調味獎勵動畫（湯）');
        } else {
          h.unreached.add('調味獎勵動畫');
        }

        // 第4輪 advanced：烹飪
        final p4 = await h.until(() => h.has(find.text('請記住這個')), maxMs: 8000);
        await h.snapIf(p4, '正式賽－物品展示（烹飪 advanced）', scaled: true);
        final fo4 = await h.waitOptions(4);
        await h.snapIf(fo4, '正式賽－選項卡（烹飪）');
        if (fo4) {
          // 在選項畫面打開暫停選單
          await h.tapText('選單');
          await h.wait(300);
          await h.snapIf(h.has(find.text('遊戲暫停')), '暫停選單（選項卡畫面上）');
          await h.tapText('繼續遊戲');
          await h.answer(true);
          await h.wait(300);
          await h.snap('烹飪階段－答對後選項卡回饋（無獎勵動畫）');
        } else {
          h.unreached.add('暫停選單（選項卡畫面上）');
        }

        // 第5輪 → GAME_TIME_UP → 時間到！→ 彩蛋 → 結算
        final fo5 = await h.waitOptions(5);
        if (fo5) {
          await h.answer(true);
          final tu = await h.until(() => h.has(find.text('時間到！')), maxMs: 3000);
          await h.snapIf(tu, '時間到提示', scaled: true);
          final egg = await h.until(() => h.has(find.text('恭喜完成烹飪關卡！')), maxMs: 5000);
          await h.snapIf(egg, '彩蛋（咖哩飯慶祝）', scaled: true);
          final res = await h.until(() => h.has(find.text('本次分數')), maxMs: 5000);
          await h.wait(600); // 等對話框淡入結束
          await h.snapIf(res, '結算對話框', scaled: true);
          if (!res) h.unreached.add('再玩一次後的流程');
        } else {
          h.unreached.addAll(['時間到提示', '彩蛋（咖哩飯慶祝）', '結算對話框']);
        }

        await t.pumpWidget(const SizedBox());
        for (var i = 0; i < 60; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final e = t.takeException();
        if (e != null) h.errors.add('UNCAUGHT(teardown): $e');
      }, () => MockClient(b.handle));
    } finally {
      FlutterError.onError = orig;
    }

    // ignore: avoid_print
    print('===== 沒走到的畫面：${h.unreached.isEmpty ? '無' : h.unreached.join('、')} =====');
    // ignore: avoid_print
    print('===== 版面溢出（RenderFlex，不算 a11y 違規）：${h.overflows.length} 次 =====');
    for (final o in h.overflows.toSet()) {
      // ignore: avoid_print
      print('  [overflow] $o');
    }
    // ignore: avoid_print
    for (final e in h.errors) {
      // ignore: avoid_print
      print('  [error] $e');
    }

    a11y.finish();
    expect(h.errors, isEmpty, reason: h.errors.join('\n'));
    expect(h.unreached, isEmpty, reason: '有畫面沒走到：${h.unreached}');
  });
}
