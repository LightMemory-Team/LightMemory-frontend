/// cooking_prep 是「記憶配對」（memory_recall）的美術主題包裝，資料結構全部
/// 直接用同資料夾內 memory_recall_model.dart 的（MemoryRecallRound／
/// MemoryRecallAnswerResult 等，API client 跟 model 都收在 cooking_prep 自己的
/// services／models 底下，沒有獨立的 memory_recall 遊戲功能了），這裡只留
/// 「後端階段字串 → 中文主題名稱」的對照，不再有本地的 CookingStage／
/// CookingIngredient／CookingRound 這些概念。
extension MemoryRecallStageTitle on String {
  /// this 是後端的 current_stage 字串（'basic'／'intermediate'／'advanced'）
  String get cookingStageTitle {
    switch (this) {
      case 'basic':
        return '切菜';
      case 'intermediate':
        return '調味';
      case 'advanced':
        return '烹飪';
      default:
        return this;
    }
  }
}
