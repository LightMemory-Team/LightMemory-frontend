import 'package:flutter/material.dart';
import 'tutorial_step_model.dart';

// 新手教學步驟假資料，依序對應首頁教練標記（coach mark）要顯示的內容
// pageIndex 對應 MainScreen 的 _currentIndex：
// 0 = 聲影日記　1 = 資訊站　2 = 首頁　3 = 儀表板　4 = 會員
final List<TutorialStepModel> mockTutorialSteps = [
  const TutorialStepModel(
    stepNumber: 1,
    pageIndex: 2,
    icon: Icons.home_rounded,
    title: '這裡是首頁，隨時都能回到這裡！',
    description: '不管是玩遊戲還是看日記，點擊這裡就能快速回到主畫面喔。',
    buttonLabel: '下一步',
  ),
  const TutorialStepModel(
    stepNumber: 2,
    pageIndex: 0,
    icon: Icons.menu_book_outlined,
    title: '聲影日記',
    description: '用照片和聲音記錄您的每一天！',
    buttonLabel: '下一步',
  ),
  const TutorialStepModel(
    stepNumber: 3,
    pageIndex: 1,
    icon: Icons.info_outline,
    title: '資訊站',
    description: '了解最新的健康資訊與防詐騙知識。',
    buttonLabel: '下一步',
  ),
  const TutorialStepModel(
    stepNumber: 4,
    pageIndex: 3,
    icon: Icons.insert_chart_outlined_rounded,
    title: '儀表板',
    description: '查看您的腦年齡與認知能力變化趨勢！',
    buttonLabel: '下一步',
  ),
  const TutorialStepModel(
    stepNumber: 5,
    pageIndex: 4,
    icon: Icons.person_outline,
    title: '會員頁面',
    description: '查看您的個人資料與偏好設定！',
    buttonLabel: '完成教學',
  ),
];