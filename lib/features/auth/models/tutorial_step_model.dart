import 'package:flutter/material.dart';

/// 新手教學單一步驟的資料模型
/// 對應首頁上依序出現的教練標記（coach mark）提示框
class TutorialStepModel {
  final int stepNumber;      // 教學進行到第幾步（用於「1/5」進度點與判斷是否為最後一步）
  final int pageIndex;       // 對應 MainScreen 底部導覽的分頁 index，用來切換高亮的頁籤
  final IconData icon;       // 提示框左上角小圖示，跟該頁籤圖示一致
  final String title;        // 提示框標題
  final String description;  // 提示框說明文字
  final String buttonLabel;  // 按鈕文字：前四步是「下一步」，最後一步是「完成教學」

  const TutorialStepModel({
    required this.stepNumber,
    required this.pageIndex,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
  });
}