import 'package:flutter/material.dart';

class DailySuggestion {
  final String text;
  final String actionRoute;

  DailySuggestion({
    required this.text,
    required this.actionRoute,
  });
}

class DailySuggestionCard extends StatefulWidget {
  final DailySuggestion suggestion;

  const DailySuggestionCard({super.key, required this.suggestion});

  @override
  State<DailySuggestionCard> createState() => _DailySuggestionCardState();
}

class _DailySuggestionCardState extends State<DailySuggestionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // TODO: 導頁
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFFC3D8C5)
              : const Color(0xFFDCE8DC),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '每日建議',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2E7D4F),
                    ),
                  ),
                  Text(widget.suggestion.text, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}