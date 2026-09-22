import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../features/auth/models/tutorial_mock_data.dart';
import '../features/auth/services/tutorial_service.dart';
import '../features/auth/widgets/tutorial_overlay.dart';
import '../features/diary/pages/diary_home_page.dart';

class MainScreen extends StatefulWidget {
  // 是否要在進入首頁後立刻開始播放新手教學
  // 由 TutorialIntroPage 點擊「開始導覽」時傳入 true
  final bool startTutorial;

  const MainScreen({super.key, this.startTutorial = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // 預設停留在中間「首頁」

  // 新手教學狀態
  bool _isTutorialActive = false;
  int _tutorialStepIndex = 0;
  Rect? _currentTargetRect;

  // 每個底部導覽 icon 各自的 GlobalKey，用來之後量測它在螢幕上的實際位置
  final Map<int, GlobalKey> _navItemKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
  };

  final List<Widget> _pages = [
    const DiaryHomePage(),
    const Scaffold(body: Center(child: Text('資訊站'))),
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('儀表板'))),
    const Scaffold(body: Center(child: Text('會員'))),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.startTutorial) {
      // 要等第一次畫面 build 完成後才能開始量測 icon 位置，
      // 所以用 addPostFrameCallback 延到那個時間點再執行
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTutorial());
    }
  }

  // 開始播放教學：從第 0 步開始
  void _startTutorial() {
    setState(() {
      _isTutorialActive = true;
      _tutorialStepIndex = 0;
      _currentIndex = mockTutorialSteps[0].pageIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTargetRect());
  }

  // 量測目前這一步要指向的 icon，在螢幕上的實際位置與大小
  void _measureTargetRect() {
    final pageIndex = mockTutorialSteps[_tutorialStepIndex].pageIndex;
    final renderObject = _navItemKeys[pageIndex]?.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero);
      setState(() {
        _currentTargetRect = position & renderObject.size;
      });
    }
  }

  // 點擊提示框裡的「下一步／完成教學」按鈕
  void _handleTutorialNext() {
    final isLastStep = _tutorialStepIndex == mockTutorialSteps.length - 1;

    if (isLastStep) {
      TutorialService.markTutorialCompleted();
      setState(() {
        _isTutorialActive = false;
        _currentTargetRect = null;
      });
      return;
    }

    setState(() {
      _tutorialStepIndex += 1;
      _currentIndex = mockTutorialSteps[_tutorialStepIndex].pageIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTargetRect());
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2E6342);
    const inactiveColor = Color(0xFF4E4E54);

    return Stack(
      children: [
        Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: Container(
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.menu_book_outlined,
                  '聲影日記',
                  activeColor,
                  inactiveColor,
                ),
                _buildNavItem(
                  1,
                  Icons.info_outline,
                  '資訊站',
                  activeColor,
                  inactiveColor,
                ),
                _buildNavItem(
                  2,
                  Icons.home_outlined,
                  '首頁',
                  activeColor,
                  inactiveColor,
                ),
                _buildNavItem(
                  3,
                  Icons.insert_chart_outlined_rounded,
                  '儀表板',
                  activeColor,
                  inactiveColor,
                ),
                _buildNavItem(
                  4,
                  Icons.person_outline,
                  '會員',
                  activeColor,
                  inactiveColor,
                ),
              ],
            ),
          ),
        ),
        // 教學疊加層：只有教學進行中，且目標位置已經量測到時才顯示
        if (_isTutorialActive && _currentTargetRect != null)
          TutorialOverlay(
            step: mockTutorialSteps[_tutorialStepIndex],
            totalSteps: mockTutorialSteps.length,
            targetRect: _currentTargetRect!,
            onNext: _handleTutorialNext,
          ),
      ],
    );
  }

  // 底部導覽列的每個分頁項目：選中時套用「大圓圈浮起」樣式，沒選中時是黑框線小圖示，
  // 五個分頁共用同一套邏輯，選中狀態完全跟著 _currentIndex 走，不綁定特定分頁
  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.25);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          key: _navItemKeys[index], // 量測用的定位點
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isSelected
                  ? Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const SizedBox(width: 48, height: 24),
                        Positioned(
                          top: -20,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: activeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(icon, color: inactiveColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: safeTextScaler,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}