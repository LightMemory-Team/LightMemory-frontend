/// 題目類型：跟上一題規則相同（repeat）還是不同（switch）
enum TrialType { repeat, switchType }

/// 錯誤類型：只有答錯時才有意義，答對時對應欄位是 null
///
/// - persistent：switch 題答錯，且選的籃子剛好對應「上一題的舊規則」
///   （代表長者慣性用舊規則作答，這是認知彈性測驗最想抓到的錯誤模式）
/// - random：其他所有答錯情況，包含全部的 repeat 題答錯
///   （repeat 題規則沒變，不存在「用舊規則」這個概念，答錯一律算 random）
enum ErrorType { persistent, random }

/// 單題的完整判定紀錄，每題只會有一筆（答錯不能重試，直接進下一題）
class TrialResult {
  final int questionIndex; // 全場累計題號，1起算
  final bool isCorrect;
  final int reactionTimeMs; // 從 interactive 狀態開始計時到判定為止
  final TrialType trialType;
  final ErrorType? errorType; // 答對時為 null

  const TrialResult({
    required this.questionIndex,
    required this.isCorrect,
    required this.reactionTimeMs,
    required this.trialType,
    required this.errorType,
  });
}