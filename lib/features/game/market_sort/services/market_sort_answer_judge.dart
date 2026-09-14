import '../models/game_rule.dart';
import '../models/market_sort_item.dart';
import '../models/trial_result.dart';

/// 單題作答的判定結果（還沒補上 questionIndex 跟 reactionTimeMs，
/// 那兩個由呼叫端的 controller 補上，這裡只負責「對不對、什麼錯法」）
class AnswerJudgement {
  final bool isCorrect;
  final ErrorType? errorType;

  const AnswerJudgement({required this.isCorrect, required this.errorType});
}

/// error_type 判定演算法（對應設計文件第六節）
///
/// [item] 當題出現的商品
/// [currentRule] 當題規則
/// [selectedBucketValue] 長者拖進去的那個籃子，代表的屬性值
///   （例如拖進「水果籃」，這個值就是 ItemCategory.fruit）
/// [trialType] 當題是 repeat 還是 switch
/// [previousRule] 上一題的規則；第一題沒有上一題，傳 null
AnswerJudgement judgeAnswer({
  required MarketSortItem item,
  required GameRule currentRule,
  required Object selectedBucketValue,
  required TrialType trialType,
  required GameRule? previousRule,
}) {
  final correctValue = item.valueFor(currentRule);

  // 步驟1：選的籃子對不對
  if (selectedBucketValue == correctValue) {
    return const AnswerJudgement(isCorrect: true, errorType: null);
  }

  // 步驟2：答錯了，判斷 persistent 或 random
  // repeat 題規則沒變，沒有「用舊規則」這個概念，一律算 random
  if (trialType == TrialType.repeat) {
    return const AnswerJudgement(
      isCorrect: false,
      errorType: ErrorType.random,
    );
  }

  // switch 題答錯：檢查選的籃子是不是剛好對應上一題的規則
  // previousRule 為 null（例如全場第一題）時，不會有 persistent 判定
  if (previousRule != null) {
    final previousValue = item.valueFor(previousRule);
    // previousValue 為 null 代表這個商品在上一題規則底下本身就被排除，
    // 邏輯上不會出現 persistent，這裡的 null 檢查只是防呆，避免誤判
    if (previousValue != null && selectedBucketValue == previousValue) {
      return const AnswerJudgement(
        isCorrect: false,
        errorType: ErrorType.persistent,
      );
    }
  }

  return const AnswerJudgement(isCorrect: false, errorType: ErrorType.random);
}