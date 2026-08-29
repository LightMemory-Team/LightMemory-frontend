import 'package:flutter/material.dart';
class CognitiveDomain {
  final String id;          // 給程式辨識用的英文代號，例如 'language'
  final String title;       // 顯示給使用者看的中文名稱，例如 '語言'
  final IconData icon;      // 卡片上的圖示
  final bool isRecommended; // 是否顯示「今日推薦」標籤

  const CognitiveDomain({
    required this.id,
    required this.title,
    required this.icon,
    this.isRecommended = false,
  });
}