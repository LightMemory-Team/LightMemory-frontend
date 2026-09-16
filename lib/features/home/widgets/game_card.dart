import 'package:flutter/material.dart';
import '../../game/market_shopping/pages/market_shopping_game_page.dart';

class Game {
  final String id;
  final String title;

  Game({
    required this.id,
    required this.title,
  });
}

class GameCard extends StatefulWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MarketShoppingGamePage(),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFFC3D8C5) // 按下去的深色
              : const Color(0xFFDCE8DC), // 原本的淺色
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: Color(0xFF4A7C5C), size: 26),
            const SizedBox(width: 12),
            Text(
              widget.game.title,
              style: const TextStyle(
                color: Color(0xFF3D6B4A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}