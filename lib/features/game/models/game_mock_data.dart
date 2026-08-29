import 'package:flutter/material.dart';
import 'cognitive_domain_model.dart';

// 假資料：六大認知領域，之後接上真實 API 後這份清單會被後端資料取代
final List<CognitiveDomain> mockCognitiveDomains = [
  const CognitiveDomain(
    id: 'language',
    title: '語言',
    icon: Icons.menu_book_outlined,
    isRecommended: true,
  ),
  const CognitiveDomain(
    id: 'working_memory',
    title: '工作記憶',
    icon: Icons.lightbulb_outline,
  ),
  const CognitiveDomain(
    id: 'attention',
    title: '注意力',
    icon: Icons.adjust,
  ),
  const CognitiveDomain(
    id: 'executive_function',
    title: '執行功能',
    icon: Icons.settings_outlined,
  ),
  const CognitiveDomain(
    id: 'visual_spatial',
    title: '視覺空間',
    icon: Icons.category_outlined,
  ),
  const CognitiveDomain(
    id: 'math',
    title: '數學',
    icon: Icons.add,
  ),
];