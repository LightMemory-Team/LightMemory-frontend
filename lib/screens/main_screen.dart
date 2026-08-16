import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 預設選中中間第 3 個項目（索引為 2 的「首頁」）
  int _currentIndex = 2;

  // 5 個主分頁（其餘 4 頁先放簡單佔位文字，首頁放入剛剛建好的 HomeScreen）
  final List<Widget> _pages = const [
    Center(child: Text('聲影日記 (尚未實作)', style: TextStyle(fontSize: 18))),
    Center(child: Text('資訊站 (尚未實作)', style: TextStyle(fontSize: 18))),
    HomeScreen(),
    Center(child: Text('儀表板 (尚未實作)', style: TextStyle(fontSize: 18))),
    Center(child: Text('會員 (尚未實作)', style: TextStyle(fontSize: 18))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 可以在切換分頁時保留各分頁的狀態與資料
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '聲影日記'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: '資訊站'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: '儀表板',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '會員',
          ),
        ],
      ),
    );
  }
}
