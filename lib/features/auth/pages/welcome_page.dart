import 'package:flutter/material.dart';
import '../../../screens/main_screen.dart';
import 'tutorial_intro_page.dart';

class WelcomePage extends StatelessWidget {
  final String userName;

  /// 剛註冊的新使用者：顯示「歡迎加入」，按鈕接新手教學引導頁；
  /// 一般登入：顯示「歡迎回來」，按鈕直接進主畫面
  final bool isNewUser;

  const WelcomePage({
    super.key,
    required this.userName,
    this.isNewUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F3),
        elevation: 0,
        centerTitle: true,
        title: const Text('憶智防線', style: TextStyle(color: Colors.black87)),
      ),
      body: SafeArea(
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D6B4A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isNewUser ? '歡迎加入，$userName！' : '歡迎回來，$userName！',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8A6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (isNewUser) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TutorialIntroPage(),
                        ),
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
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '進入首頁',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
