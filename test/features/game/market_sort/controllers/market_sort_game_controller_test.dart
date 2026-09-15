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
}