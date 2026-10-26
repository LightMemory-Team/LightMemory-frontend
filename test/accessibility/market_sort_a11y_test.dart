// 整理菜籃（market_sort）無障礙檢查
//
// 走完一整局，在每一個不同的畫面／狀態呼叫 Flutter 內建的無障礙 guideline
// （androidTapTarget / iOSTapTarget / labeledTapTarget / textContrast），
// 只收集違規、不讓測試失敗（加 --dart-define=A11Y_STRICT=true 才會失敗）。
// 另外檢查「拖曳作答有沒有非拖曳的替代操作（點擊）」是否出現在 semantics tree。
//
// 執行：flutter test test/accessibility/market_sort_a11y_test.dart
// 報告：build/a11y_report/整理菜籃.txt

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/main.dart';
import 'package:light_memory/core/constants/api_constants.dart';
import 'package:light_memory/core/services/audio_service.dart' as core_audio;
import 'package:light_memory/features/game/market_sort/models/game_rule.dart';
import 'package:light_memory/features/game/market_sort/models/market_sort_item.dart';
import 'package:light_memory/features/game/market_sort/models/market_sort_item_attributes.dart';
import 'package:light_memory/features/game/market_sort/models/market_sort_item_pool.dart';
import 'package:light_memory/features/game/market_sort/services/market_sort_api_service.dart';
import 'package:light_memory/features/game/market_sort/widgets/result_history_chart.dart';
import 'package:light_memory/features/game/market_sort/widgets/rule_badge.dart';
import 'package:light_memory/features/game/market_sort/widgets/tutorial_modal.dart';
import 'package:light_memory/features/game/widgets/game_pause.dart';
import 'package:light_memory/screens/game_home_screen.dart';
import 'package:light_memory/screens/market_sort_game_screen.dart';
import 'package:light_memory/screens/market_sort_result_screen.dart';

import 'a11y_check.dart';

// ───────────────────────── 假後端與共用工具（從 playthrough 測試複製） ─────────────────────────

const _submitUrl = '${ApiConstants.serverUrl}/api/games/market-sort/submit/';
const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

String _okBody({String tier = 'good'}) => jsonEncode({
  'success': true,
  'data': {
    'current_score': 82,
    'highest_score': 90,
    'recent_scores': [60, 70, 75, 80],
    'encouragement_tier': tier,
  },
  'error': null,
});

class _Backend {
  int submitCalls = 0;
  bool failNext = true;

  MockClient client() => MockClient((req) async {
    if (req.url.toString() == _submitUrl) {
      submitCalls++;
      if (failNext) {
        failNext = false;
        return http.Response(
          jsonEncode({
            'success': false,
            'data': null,
            'error': {'code': 'SERVER_ERROR', 'message': '伺服器錯誤'},
          }),
          500,
          headers: _jsonHeaders,
        );
      }
      return http.Response(_okBody(), 200, headers: _jsonHeaders);
    }
    return http.Response(
      jsonEncode({
        'success': false,
        'data': null,
        'error': {'code': 'NOT_FOUND', 'message': 'not found'},
      }),
      404,
      headers: _jsonHeaders,
    );
  });
}

const Map<Object, String> _basketText = {
  ItemCategory.vegetable: '蔬菜 🥬',
  ItemCategory.fruit: '水果 🍎',
  ItemCategory.meatEgg: '肉蛋 🍗',
  ItemColor.red: '紅色 🔴',
  ItemColor.green: '綠色 🟢',
  ItemColor.yellow: '黃色 🟡',
  ItemFreshness.raw: '生食 🥗',
  ItemFreshness.cooked: '熟食 🍳',
};

List<Object> _valuesFor(GameRule rule) {
  switch (rule) {
    case GameRule.species:
      return ItemCategory.values;
    case GameRule.color:
      return ItemColor.values;
    case GameRule.freshness:
      return ItemFreshness.values;
  }
}

void _stubPlatformChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.allMessagesHandler = (channel, handler, message) {
    if (channel.startsWith('xyz.luan/audioplayers')) {
      return Future.value(
        const StandardMethodCodec().encodeSuccessEnvelope(null),
      );
    }
    if (handler != null) return handler(message);
    return null;
  };
}

/// 收集 Flutter 錯誤（overflow 等），不中斷測試；overflow 在小螢幕是已知現象，只記錄
class _ErrorSink {
  final List<String> errors = [];
  FlutterExceptionHandler? _old;
  void attach() {
    _old = FlutterError.onError;
    FlutterError.onError = (e) {
      String first;
      try {
        first = e.exceptionAsString().split('\n').first;
      } catch (_) {
        first = e.exception.runtimeType.toString();
      }
      String? loc;
      try {
        loc = RegExp(
          r'lib/[^\s:]+\.dart:\d+',
        ).firstMatch(e.toString())?.group(0);
      } catch (_) {}
      errors.add(loc == null ? first : '$first  @$loc');
    };
  }

  void detach() => FlutterError.onError = _old;
}

void _setSurface(WidgetTester tester, Size logical, {double dpr = 3}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
}

Future<void> _pumpApp(WidgetTester tester, {Widget? home}) async {
  late RouteFactory appRoutes;
  late ThemeData theme;
  await tester.pumpWidget(
    Builder(
      builder: (ctx) {
        final app = const MyApp().build(ctx) as MaterialApp;
        appRoutes = app.onGenerateRoute!;
        theme = app.theme!;
        return const SizedBox();
      },
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      onGenerateRoute: appRoutes,
      home: home ?? const GameHomeScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _finishCountdown(WidgetTester tester) async {
  expect(find.text('準備開始'), findsOneWidget);
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump();
  expect(find.text('準備開始'), findsNothing);
}

GameRule _currentRule(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(RuleBadge),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .toList();
  return GameRule.values.firstWhere((r) => texts.contains(r.label));
}

MarketSortItem _currentItem(WidgetTester tester) {
  final cardTexts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is Draggable<MarketSortItem>),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .toSet();
  return marketSortItemPool.firstWhere((i) => cardTexts.contains(i.name));
}

int _questionNumber(WidgetTester tester) {
  final f = find.textContaining(RegExp(r'^\d+/\d+$'));
  return int.parse(tester.widget<Text>(f).data!.split('/').first);
}

Future<void> _dragItemTo(WidgetTester tester, Object bucketValue) async {
  final from = tester.getCenter(
    find.byWidgetPredicate((w) => w is Draggable<MarketSortItem>),
  );
  final to = tester.getCenter(find.text(_basketText[bucketValue]!));
  final g = await tester.startGesture(from);
  await tester.pump();
  await g.moveBy(const Offset(0, 30));
  await tester.pump();
  await g.moveTo(to);
  await tester.pump();
  await g.up();
  await tester.pump();
}

/// 作答目前這題（等鎖定結束 → 拖曳）。[onFeedback] 在閃爍回饋期間被呼叫（約 250ms 時）。
/// 回傳作答的題號。
Future<int> _answer(
  WidgetTester tester, {
  required bool correct,
  Future<void> Function()? onFeedback,
}) async {
  await tester.pump(const Duration(milliseconds: 2100));
  final number = _questionNumber(tester);
  final rule = _currentRule(tester);
  final item = _currentItem(tester);
  final right = item.valueFor(rule)!;
  final target = correct
      ? right
      : _valuesFor(rule).firstWhere((v) => v != right);
  await _dragItemTo(tester, target);
  await tester.pump(const Duration(milliseconds: 250));
  if (onFeedback != null) await onFeedback();
  await tester.pump(const Duration(milliseconds: 500));
  return number;
}

// ───────────────────────── semantics 檢視：有沒有非拖曳替代操作 ─────────────────────────

class _SemNode {
  final String label;
  final Rect rect;
  final bool tap;
  final bool hasOtherAction;
  _SemNode(this.label, this.rect, this.tap, this.hasOtherAction);
}

List<_SemNode> _collectSemantics(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  try {
    final out = <_SemNode>[];
    final root = tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!;
    void visit(SemanticsNode node, Matrix4 parent) {
      final data = node.getSemanticsData();
      final label = [
        data.label,
        data.value,
        data.hint,
      ].where((s) => s.isNotEmpty).join(' | ').replaceAll('\n', ' ');
      final tap = data.hasAction(SemanticsAction.tap) ||
          data.hasAction(SemanticsAction.longPress);
      final other = (data.customSemanticsActionIds?.isNotEmpty ?? false) ||
          data.hasAction(SemanticsAction.increase) ||
          data.hasAction(SemanticsAction.decrease);
      if (label.isNotEmpty || tap || other) {
        out.add(_SemNode(label, node.rect, tap, other));
      }
      node.visitChildren((c) {
        visit(c, parent);
        return true;
      });
    }

    visit(root, Matrix4.identity());
    return out;
  } finally {
    handle.dispose();
  }
}

/// 檢查「商品卡」與「籃子」在 semantics tree 裡有沒有可點擊（非拖曳）的替代操作，
/// 並把結果記成一筆自訂違規（guideline = nonDragAlternative）。
void _reportDragAlternative(
  WidgetTester tester,
  A11yReport a11y,
  String screen,
  MarketSortItem item,
  GameRule rule,
) {
  final nodes = _collectSemantics(tester);
  final basketLabels = _valuesFor(rule)
      .map((v) => _basketText[v]!.split(' ').first)
      .toList();
  final itemNodes = nodes.where((n) => n.label.contains(item.name)).toList();
  final basketNodes = nodes
      .where((n) => basketLabels.any((b) => n.label.contains(b)))
      .toList();
  final itemTap = itemNodes.any((n) => n.tap || n.hasOtherAction);
  final basketTap = basketNodes.any((n) => n.tap || n.hasOtherAction);

  // ignore: avoid_print
  print(
    '[$screen] semantics 節點（有文字或可操作）：\n${nodes.map((n) => '  - "${n.label}" tap=${n.tap} otherAction=${n.hasOtherAction} ${n.rect}').join('\n')}',
  );
  // ignore: avoid_print
  print(
    '[$screen] 商品「${item.name}」節點=${itemNodes.length}、可點擊=$itemTap；'
    '籃子 $basketLabels 節點=${basketNodes.length}、可點擊=$basketTap',
  );

  if (!itemTap && !basketTap) {
    a11y.violations.add(
      A11yViolation(
        screen,
        'nonDragAlternative',
        '作答只能靠拖曳（Draggable + DragTarget）：商品「${item.name}」'
            '${itemNodes.isEmpty ? '' : '有文字節點但'}沒有任何 tap／自訂動作，'
            '籃子（${basketLabels.join('、')}）的 semantics 節點'
            '${basketNodes.isEmpty ? '也沒有' : '有文字但沒有'}可點擊動作，'
            '讀屏使用者無法「點商品再點籃子」完成作答。',
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test'});
    _stubPlatformChannels();
    core_audio.AudioService.setEnabled(false);
  });

  testWidgets('整理菜籃：每個畫面跑無障礙 guideline', (tester) async {
    _setSurface(tester, const Size(360, 780));
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final a11y = A11yReport('整理菜籃');
    final backend = _Backend();
    final sink = _ErrorSink()..attach();
    final skipped = <String>[];

    // 整個測試期間常開 semantics：a11y.check 每次只短暫 ensureSemantics()，
    // 若 semantics 當下才開啟、還沒經過 frame，tree 是空的，guideline 會「空過」。
    final semanticsHandle = tester.ensureSemantics();

    /// 單一畫面的檢查包起來：任何例外都記下來，不讓整個流程中斷
    Future<void> check(String screen) async {
      try {
        final n = _collectSemantics(tester);
        // ignore: avoid_print
        print(
          '[semantics] $screen：${n.length} 個有文字或可操作的節點，'
          '可點擊=${n.where((e) => e.tap).length}',
        );
        await a11y.check(tester, screen);
      } catch (e) {
        skipped.add('$screen：$e');
      }
    }

    try {
      await http.runWithClient(() async {
        await _pumpApp(tester, home: const MarketSortGameScreen());

        // 1. 倒數畫面
        await check('倒數畫面（3）');
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // 2. 第 1 題鎖定中（生熟規則，鎖定 1 秒，AbsorbPointer）
        expect(find.byType(RuleBadge), findsOneWidget);
        await check('遊戲-鎖定中（Q1 生熟規則）');

        // 3. 可作答（商品 + 兩個籃子）
        await tester.pump(const Duration(milliseconds: 1100));
        await check('遊戲-可作答（Q1 生熟規則，2 個籃子）');
        _reportDragAlternative(
          tester,
          a11y,
          '遊戲-可作答（Q1 生熟規則，2 個籃子）',
          _currentItem(tester),
          _currentRule(tester),
        );

        // 4. 閒置提示（5 秒沒操作）
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('請把商品拖到正確的籃子裡！'), findsOneWidget);
        await check('遊戲-閒置提示（商品跳動＋箭頭）');

        // 5. 暫停選單
        await tester.tap(find.text('選單'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(GamePause), findsOneWidget);
        await check('暫停選單');

        // 6. 玩法教學兩頁
        await tester.tap(find.text('玩法教學'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(TutorialModal), findsOneWidget);
        await check('玩法教學-第 1 頁（怎麼玩）');
        await tester.tap(find.text('下一頁 →'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.text('遊戲共分四階段'), findsOneWidget);
        await check('玩法教學-第 2 頁（遊戲共分四階段）');
        await tester.tap(find.text('開始遊戲 →'));
        await tester.pump();
        await _finishCountdown(tester);

        // 7. 答對回饋（Q1）
        await _answer(
          tester,
          correct: true,
          onFeedback: () => check('遊戲-答對回饋（籃子閃綠）'),
        );

        // 8. 答錯回饋（Q2）
        await _answer(
          tester,
          correct: false,
          onFeedback: () => check('遊戲-答錯回饋（籃子閃橘）'),
        );

        // Q3~Q5 直接答完
        for (var q = 3; q <= 5; q++) {
          await _answer(tester, correct: true);
        }

        // 9. 規則切換：第 6 題換成「種類」規則，鎖定 2 秒（沒有獨立 banner，
        //    只有 RuleBadge 文字改變，沒有任何提示／公告）
        expect(_questionNumber(tester), 6);
        await check('遊戲-規則切換後鎖定中（Q6 生熟→種類，2 秒）');
        await tester.pump(const Duration(milliseconds: 2100));
        await check('遊戲-可作答（Q6 種類規則，3 個籃子）');
        _reportDragAlternative(
          tester,
          a11y,
          '遊戲-可作答（Q6 種類規則，3 個籃子）',
          _currentItem(tester),
          _currentRule(tester),
        );
        await _answer(tester, correct: true);
        for (var q = 7; q <= 10; q++) {
          await _answer(tester, correct: true);
        }

        // 10. 顏色規則（Q11）可作答
        await tester.pump(const Duration(milliseconds: 2100));
        expect(_questionNumber(tester), 11);
        await check('遊戲-可作答（Q11 顏色規則，3 個籃子）');

        // 11. 小螢幕 320x568（同一題）
        _setSurface(tester, const Size(320, 568));
        await tester.pump();
        await check('遊戲-可作答 @320x568（Q11 顏色規則）');
        _setSurface(tester, const Size(360, 780));
        await tester.pump();

        // 12. 大字體 1.3 倍：遊戲畫面、暫停選單
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        await tester.pump();
        await check('遊戲-可作答 @字級1.3x（Q11 顏色規則）');
        await tester.tap(find.text('選單'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await check('暫停選單 @字級1.3x');
        await tester.tap(find.text('繼續遊戲'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pump();
        await _finishCountdown(tester);

        // 13. 玩完剩下的題目 → 第一次送出失敗 → SnackBar
        while (_questionNumber(tester) < 28) {
          await _answer(tester, correct: true);
        }
        await _answer(tester, correct: true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('成績送出失敗，請確認網路後再試一次'), findsOneWidget);
        await check('送出失敗（SnackBar＋重試）');

        // 14. 重試成功 → 結算頁
        await tester.tap(find.text('重試'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.byType(MarketSortResultScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 2)); // fl_chart 動畫
        expect(find.byType(ResultHistoryChart), findsOneWidget);
        await check('結算頁（分數卡＋歷史圖表）');

        _setSurface(tester, const Size(320, 568));
        await tester.pump();
        await check('結算頁 @320x568');
        _setSurface(tester, const Size(360, 780));
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        await tester.pump();
        await check('結算頁 @字級1.3x');
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pump();
      }, backend.client);

      // 15. 結算頁另一種狀態：第一次玩（無歷史圖表）＋「沒關係再加油」配色
      await _pumpApp(
        tester,
        home: MarketSortResultScreen(
          result: MarketSortSubmitResult(
            currentScore: 40,
            highestScore: 95,
            recentScores: const [],
            encouragementTier: 'keep_trying',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await check('結算頁（keep_trying，無歷史圖表）');
    } finally {
      sink.detach();
    }

    // ignore: avoid_print
    print(
      '[限制] textContrastGuideline 只檢查 find.text(...).hitTestable() 的文字：'
      '鎖定中／回饋閃爍（AbsorbPointer）與 320x568 被擠出畫面的籃子標籤不會被檢查，'
      '它們的對比結果等同「可作答」畫面（橘色 2.70、黃色 1.79）。',
    );

    // 已知版面問題（overflow）只印出，不讓測試失敗
    // ignore: avoid_print
    print('[版面] 過程中收到的 Flutter 錯誤：${sink.errors.toSet().toList()}');
    // ignore: avoid_print
    print('[流程] 因例外被跳過的畫面：${skipped.isEmpty ? '無' : skipped}');
    // ignore: avoid_print
    print(
      '[流程] 無法到達：獨立的「規則切換 banner」不存在（只有 RuleBadge 文字變化）；'
      '遊戲頁沒有獨立的「送出中」畫面（_isSubmitting 沒有任何 UI）。',
    );
    for (final s in skipped) {
      a11y.violations.add(A11yViolation('(流程)', 'skipped', s));
    }

    semanticsHandle.dispose();
    a11y.finish();
  });
}
