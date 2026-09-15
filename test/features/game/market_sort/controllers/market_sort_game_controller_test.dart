import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/game/market_sort/controllers/market_sort_game_controller.dart';

void main() {
  test('28題的規則與階段邊界推進邏輯正確', () {
    final controller = MarketSortGameController();

    final boundaryQuestions = <int>[];

    for (var i = 0; i < 28; i++) {
      if (controller.isStageBoundary) {
        boundaryQuestions.add(controller.displayQuestionNumber);
      }
      controller.moveToNextQuestion();
    }

    // 三個大階段邊界應該剛好是第6、11、16題（生熟5題結束後、
    // 種類5題結束後、顏色5題結束後，各自的下一題）
    expect(boundaryQuestions, [6, 11, 16]);
  });

  test('全場第一題沒有previousRule', () {
    final controller = MarketSortGameController();
    expect(controller.previousRule, isNull);
  });

  test('走完28題後isLastQuestion為true', () {
    final controller = MarketSortGameController();
    for (var i = 0; i < 27; i++) {
      controller.moveToNextQuestion();
    }
    expect(controller.isLastQuestion, isTrue);
  });

    test('第一題(非repeat、非邊界)locked狀態1秒後自動轉interactive', () async {
    final controller = MarketSortGameController();
    controller.startQuestion();
    expect(controller.phase, QuestionPhase.locked);

    await Future.delayed(const Duration(milliseconds: 1100));
    expect(controller.phase, QuestionPhase.interactive);
  });

  test('resolveQuestion記錄reaction_time_ms並轉入resolved', () async {
    final controller = MarketSortGameController();
    controller.startQuestion();
    await Future.delayed(const Duration(milliseconds: 1100)); // 等過locked
    await Future.delayed(const Duration(milliseconds: 200)); // 模擬思考時間

    controller.resolveQuestion();

    expect(controller.phase, QuestionPhase.resolved);
    expect(controller.lastReactionTimeMs, isNotNull);
    expect(controller.lastReactionTimeMs! >= 150, isTrue);
  });

  test('locked狀態呼叫resolveQuestion應被防呆擋下，不會誤判定', () async {
    final controller = MarketSortGameController();
    controller.startQuestion();
    controller.resolveQuestion(); // 這時還在locked，應該什麼都不發生

    expect(controller.phase, QuestionPhase.locked);
  });
}