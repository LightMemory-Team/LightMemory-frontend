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
    description: '語言幫助我們聽懂別人的話，也能表達自己的想法，讓我們在日常生活中與家人、朋友順利溝通。',
    screenshotLabel: '聲影日記畫面',
    screenshotPath: 'assets/images/abilities/language.jpg',
  ),
  CognitiveAbility(
    id: 'working_memory',
    title: '工作記憶',
    icon: Icons.lightbulb_outline,
    description: '工作記憶能幫助我們記住剛剛聽到或看到的事情，並在需要時想起來，例如記住要買的東西或煮菜的步驟。',
    screenshotLabel: '料理準備遊戲畫面',
    screenshotPath: 'assets/images/abilities/working_memory.jpg',
  ),
  CognitiveAbility(
    id: 'attention',
    title: '注意力',
    icon: Icons.adjust,
    description: '注意力能幫助我們專心做一件事，留意周圍的事物。無論是找東西、聽別人說話，都需要用到注意力。',
    screenshotLabel: '來去菜市場遊戲畫面',
    screenshotPath: 'assets/images/abilities/attention.jpg',
  ),
  CognitiveAbility(
    id: 'executive_function',
    title: '執行功能',
    icon: Icons.settings_outlined,
    description: '執行功能能幫助我們安排事情、做決定和解決問題，讓生活中的大小事都能更有順序地完成。',
    screenshotLabel: '整理菜籃遊戲畫面',
    screenshotPath: 'assets/images/abilities/executive_function.jpg',
  ),
  CognitiveAbility(
    id: 'visual_spatial',
    title: '視覺空間',
    icon: Icons.category_outlined,
    description: '視覺空間能力能幫助我們辨認物品的位置、方向和距離，例如在家中找到需要的東西，或判斷物品應該放在哪裡。',
    screenshotLabel: '冰箱清點遊戲畫面',
    screenshotPath: 'assets/images/abilities/visual_spatial.jpg',
  ),
  CognitiveAbility(
    id: 'math',
    title: '數學',
    icon: Icons.add,
    description: '數學能力能幫助我們處理生活中的數字，像是計算購物金額、確認找零，讓日常生活更加方便。',
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
