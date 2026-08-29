import 'package:flutter/material.dart';
import '../models/cognitive_domain_model.dart';

class DomainCard extends StatefulWidget {
  final CognitiveDomain domain;
  final VoidCallback onTap;

  const DomainCard({
    super.key,
    required this.domain,
    required this.onTap,
  });

  @override
  State<DomainCard> createState() => _DomainCardState();
}

class _DomainCardState extends State<DomainCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFFC3D8C5) // 按下去的深色
              : const Color(0xFFDCE8DC), // 原本的淺色
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.domain.icon,
                  color: const Color(0xFF4A7C5C),
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.domain.title,
                  style: const TextStyle(
                    color: Color(0xFF3D6B4A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.domain.isRecommended)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '今日推薦',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
