import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // 預設停留在中間「首頁」

  final List<Widget> _pages = [
    const Scaffold(body: Center(child: Text('聲影日記'))),
    const Scaffold(body: Center(child: Text('資訊站'))),
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('儀表板'))),
    const Scaffold(body: Center(child: Text('會員'))),
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2E6342); // 選中深綠色（高對比度）
    const inactiveColor = Color(0xFF4E4E54); // 未選中深灰（符合 WCAG AA 5.6:1）

    return Scaffold(
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
            _buildCenterHomeItem(2, activeColor, inactiveColor),
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
    );
  }

  // 一般分頁項目
  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.25);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: safeTextScaler,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 中間綠色圓形凸起「首頁」項目
  Widget _buildCenterHomeItem(
    int index,
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
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
                        color: const Color(0xFF386646), // 加深的主題草綠色
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF386646).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '首頁',
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
