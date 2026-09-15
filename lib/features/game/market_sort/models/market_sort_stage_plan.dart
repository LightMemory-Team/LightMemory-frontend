import 'game_rule.dart';

/// 單一階段的規則安排：這個階段有幾題、用哪個規則
/// 第四階段（隨機混合）比較特別，不是固定單一規則，
/// 而是每題各自指定，所以用 rules 這個「每題規則列表」表示，
/// 前三階段則是同一個規則重複 questionCount 次。
class StagePlan {
  final String stageName; // 例如 "生熟"、"種類"、"顏色"、"隨機混合"
  final int questionCount;
  final List<GameRule> rules; // 長度等於 questionCount，依序對應每一題的規則

  const StagePlan({
    required this.stageName,
    required this.questionCount,
    required this.rules,
  });
}

/// 28題版的四階段藍圖：生熟(5) → 種類(5) → 顏色(5) → 隨機混合(13)
///
/// 前三階段的 rules 是同一個規則重複填滿；
/// 第四階段目前先用一個簡單的規則序列頂著（之後階段2後半段會另外寫
/// 「動態抽題」邏輯，這裡先給一組固定序列，讓後面的控制器邏輯可以先跑起來）。
final List<StagePlan> marketSort28QuestionPlan = [
  StagePlan(
    stageName: '生熟',
    questionCount: 5,
    rules: List.filled(5, GameRule.freshness),
  ),
  StagePlan(
    stageName: '種類',
    questionCount: 5,
    rules: List.filled(5, GameRule.species),
  ),
  StagePlan(
    stageName: '顏色',
    questionCount: 5,
    rules: List.filled(5, GameRule.color),
  ),
  StagePlan(
    stageName: '隨機混合',
    questionCount: 13,
    rules: [
      // 暫定序列，之後會被動態抽題邏輯取代，這裡先確保有13個值可以跑
      GameRule.color, GameRule.species, GameRule.freshness,
      GameRule.species, GameRule.color, GameRule.freshness,
      GameRule.species, GameRule.freshness, GameRule.color,
      GameRule.species, GameRule.color, GameRule.freshness,
      GameRule.species,
    ],
  ),
];