import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'go_to_market_game_page.dart';
import 'go_to_market_tutorial_page.dart'; // 如果你的教學頁檔名不同，請對齊檔名

class GoToMarketEntryPage extends StatefulWidget {
  const GoToMarketEntryPage({super.key});

  @override
  State createState() => _GoToMarketEntryPageState();
}

class _GoToMarketEntryPageState extends State {
  static const String _keyHasPlayed = 'has_played_market_game';

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  Future _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasPlayed = prefs.getBool(_keyHasPlayed) ?? false;

    if (!mounted) return;

    if (!hasPlayed) {
      // 首次進入：進入教學頁，並註記已看過
      await prefs.setBool(_keyHasPlayed, true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GoToMarketTutorialPage()),
      );
    } else {
      // 已經玩過：直接跳進遊戲本體
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GoToMarketGamePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9F6),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2D5A43))),
    );
  }
}
