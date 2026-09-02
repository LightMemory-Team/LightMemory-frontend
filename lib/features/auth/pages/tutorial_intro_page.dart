import 'package:flutter/material.dart';
import '../../../screens/main_screen.dart';
import '../services/tutorial_service.dart';

/// 新手教學引導頁（圖1）
/// 對應設計圖：帶使用者認識「憶智防線」，提供「開始導覽」與「跳過教學」兩個入口
class TutorialIntroPage extends StatelessWidget {
  const TutorialIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // 上方 Logo（圓形圖示 + 「憶智防線」文字）
              ClipOval(
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '憶智防線',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B8A6B),
                ),
              ),

              const SizedBox(height: 28),

              // 中間插圖區塊（改成接近正方形）
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/tutorial.png',
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 28),

              // 標題與說明文字
              const Text(
                '歡迎加入憶智防線！',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '讓我們花一分鐘，\n帶您認識這份專屬的\n憶智防線。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const Spacer(),

              // 「開始導覽」按鈕
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
                  onPressed: () => _goToMainScreen(context, startTutorial: true),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '開始導覽',
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

              const SizedBox(height: 18),

              // 「跳過教學」文字按鈕
              TextButton(
                onPressed: () => _goToMainScreen(context, startTutorial: false),
                child: const Text(
                  '跳過教學',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 導向首頁（MainScreen）
  // startTutorial：true 代表要跑教練標記流程，false 代表直接跳過
  void _goToMainScreen(BuildContext context, {required bool startTutorial}) async {
    if (!startTutorial) {
      // 使用者按「跳過教學」，直接標記為已完成，之後不會再自動跳出
      await TutorialService.markTutorialCompleted();
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(startTutorial: startTutorial),
      ),
    );
  }
}