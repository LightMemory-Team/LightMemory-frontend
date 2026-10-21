import 'package:flutter/material.dart';

/// 六大認知能力的基本資料（代號、中文名稱、圖示），儀表板、六大能力說明、
/// 週報表共用。代號跟遊戲首頁（game_mock_data.dart）一致，後端回傳的
/// 分數也用同一組代號當 key。
class CognitiveAbility {
  final String id;
  final String title;
  final IconData icon;

  /// 六大能力說明頁的說明文字（定義、例如、在哪裡練習，各一行）
  final String description;

  /// 六大能力說明頁的遊戲截圖，null 代表還沒有圖片，畫面會顯示預留框
  final String? screenshotPath;

  /// 截圖預留框上的文字，例如「料理準備遊戲畫面」
  final String screenshotLabel;

  const CognitiveAbility({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.screenshotLabel,
    this.screenshotPath,
  });
}

/// 遊戲首頁的順序，六大能力說明（六宮格、說明頁）照這個順序
const List<CognitiveAbility> kAbilities = [
  CognitiveAbility(
    id: 'language',
    title: '語言',
    icon: Icons.menu_book_outlined,
    description:
        '聽懂別人說的話，也能把自己的想法說出來。\n'
        '例如：聽懂家人交代要買哪些東西，或告訴家人今天發生的事情。\n'
        '在「聲影日記」裡練習。',
    screenshotLabel: '聲影日記畫面',
    screenshotPath: 'assets/images/abilities/language.jpg',
  ),
  CognitiveAbility(
    id: 'working_memory',
    title: '工作記憶',
    icon: Icons.lightbulb_outline,
    description:
        '暫時記住事情，並在需要時拿來使用的能力。\n'
        '例如：煮菜時，記得湯裡還要加鹽，也記得另一道菜還沒炒好。\n'
        '在「料理準備」裡練習。',
    screenshotLabel: '料理準備遊戲畫面',
    screenshotPath: 'assets/images/abilities/working_memory.jpg',
  ),
  CognitiveAbility(
    id: 'attention',
    title: '注意力',
    icon: Icons.adjust,
    description:
        '專心看、聽和找東西的能力。\n'
        '例如：在市場裡找到要買的東西，或專心聽別人說話。\n'
        '在「來去菜市場」裡練習。',
    screenshotLabel: '來去菜市場遊戲畫面',
    screenshotPath: 'assets/images/abilities/attention.jpg',
  ),
  CognitiveAbility(
    id: 'executive_function',
    title: '執行功能',
    icon: Icons.settings_outlined,
    description:
        '安排事情、做決定和解決問題的能力。\n'
        '例如：準備煮飯時，想好要先洗菜、切菜，再開始煮。\n'
        '在「整理菜籃」裡練習。',
    screenshotLabel: '整理菜籃遊戲畫面',
    screenshotPath: 'assets/images/abilities/executive_function.jpg',
  ),
  CognitiveAbility(
    id: 'visual_spatial',
    title: '視覺空間',
    icon: Icons.category_outlined,
    description:
        '辨認東西的位置、方向和距離的能力。\n'
        '例如：找到冰箱裡的雞蛋，或分得出牛奶在雞蛋的左邊還是右邊。\n'
        '在「冰箱清點」裡練習。',
    screenshotLabel: '冰箱清點遊戲畫面',
    screenshotPath: 'assets/images/abilities/visual_spatial.jpg',
  ),
  CognitiveAbility(
    id: 'math',
    title: '數學',
    icon: Icons.add,
    description:
        '數數量、算金額和找零的能力。\n'
        '例如：買菜時算出總共花了多少錢，或確認店家找的錢有沒有正確。\n'
        '在「市場買菜」裡練習。',
    screenshotLabel: '市場買菜遊戲畫面',
    screenshotPath: 'assets/images/abilities/math.jpg',
  ),
];

/// 雷達圖的順序（從正上方開始順時針），照設計稿
const List<String> kRadarAbilityOrder = [
  'working_memory',
  'attention',
  'math',
  'visual_spatial',
  'executive_function',
  'language',
];

CognitiveAbility abilityById(String id) =>
    kAbilities.firstWhere((ability) => ability.id == id);
