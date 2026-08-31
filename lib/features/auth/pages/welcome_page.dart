import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final String userName;

  const WelcomePage({super.key, required this.userName});

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
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5B8A6B), width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 70,
                  color: Color(0xFF5B8A6B),
                ),
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
                '歡迎回來，$userName！',
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
                    // TODO: 導頁到首頁
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
