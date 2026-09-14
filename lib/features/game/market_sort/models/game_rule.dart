/// 整理菜籃遊戲的四種分類規則
///
/// 「隨機」（第四階段）在資料層面不是獨立的規則，
/// 而是「每題各自指定 species / color / freshness 其中一種」的狀態，
/// 所以這裡的 enum 只需要三個值，隨機階段出題時每一題會各自帶一個 GameRule 進來。
enum GameRule {
  species, // 種類：蔬菜／水果／肉蛋
  color, // 顏色：紅／綠／黃
  freshness, // 生熟：生食／熟食
}

/// 畫面上顯示用的中文名稱與圖示，跟遊戲進行頁「目前分類：種類」那個提示區塊對應
extension GameRuleDisplay on GameRule {
  String get label {
    switch (this) {
      case GameRule.species:
        return '種類';
      case GameRule.color:
        return '顏色';
      case GameRule.freshness:
        return '生熟';
    }
  }
}