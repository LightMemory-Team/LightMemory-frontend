import 'package:flutter/material.dart';
import '../../../screens/main_screen.dart';
import 'tutorial_intro_page.dart';

/// 歡迎頁（啟動頁）
///
/// - 剛註冊的新使用者：「歡迎加入，玉蘭！」，輕觸後進新手教學引導頁
/// - 一般登入、或打開 App 已經登入過：「歡迎回來，玉蘭！」，輕觸後進主畫面
/// - 點整個畫面任何地方都可以進入（長輩手指比較不準，不限定點到文字）
class WelcomePage extends StatelessWidget {
  final String userName;

  /// 剛註冊的新使用者：顯示「歡迎加入」，輕觸後接新手教學引導頁；
  /// 一般登入：顯示「歡迎回來」，輕觸後直接進主畫面
  final bool isNewUser;

  const WelcomePage({
    super.key,
    required this.userName,
    this.isNewUser = false,
  });

  void _enter(BuildContext context) {
    if (isNewUser) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TutorialIntroPage()),
      );
      return;
    }
    // 進主畫面時清掉前面所有頁面（身分選擇、登入），讓主畫面成為最底層。
    // 原本只取代歡迎頁，最底層還是身分選擇頁，聲影日記完成頁按「回首頁」
    // （popUntil isFirst）會一路退回身分選擇頁。
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = userName.trim();
    final String greeting = isNewUser
        ? (name.isEmpty ? '歡迎加入！' : '歡迎加入，$name！')
        : (name.isEmpty ? '歡迎回來！' : '歡迎回來，$name！');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: GestureDetector(
        // 點整個畫面任何地方都可以進入
        behavior: HitTestBehavior.opaque,
        onTap: () => _enter(context),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '憶智防線',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D6B4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '輕觸螢幕進入首頁',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}