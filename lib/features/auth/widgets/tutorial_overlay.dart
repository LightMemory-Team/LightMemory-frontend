import 'package:flutter/material.dart';
import '../models/tutorial_step_model.dart';

/// 新手教學的教練標記（coach mark）疊加層
/// 負責：把畫面其餘部分變暗、在目標區域挖一個洞露出原本內容、
/// 並在下方顯示提示框（icon + 標題 + 說明 + 進度點 + 按鈕）
class TutorialOverlay extends StatelessWidget {
  final TutorialStepModel step;
  final int totalSteps;
  final Rect targetRect; // 要挖洞、露出來的目標區域（某個底部導覽 icon 的位置與大小）
  final VoidCallback onNext;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.targetRect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明遮罩，中間挖出目標區域的洞
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _SpotlightPainter(targetRect)),
          ),
        ),
        // 提示框：固定貼在底部導覽列上方
        Positioned(
          left: 16,
          right: 16,
          bottom: 90, // 底部導覽列高度 74 + 間距 16
          child: _TutorialBubble(
            step: step,
            totalSteps: totalSteps,
            onNext: onNext,
          ),
        ),
      ],
    );
  }
}

/// 負責畫「全螢幕變暗 + 挖一個洞」的畫家（CustomPainter）
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  const _SpotlightPainter(this.targetRect);

  @override
  void paint(Canvas canvas, Size size) {
    // 第一個 Path：整個螢幕範圍
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // 第二個 Path：目標區域（稍微放大一點、加圓角，讓框看起來有留白）
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect.inflate(10),
          const Radius.circular(20),
        ),
      );
    // 用「差集」把整個螢幕 Path 減去目標區域 Path，剩下的就是「有洞的遮罩」
    final combinedPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      holePath,
    );
    canvas.drawPath(
      combinedPath,
      Paint()..color = Colors.black.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

/// 提示框本體
class _TutorialBubble extends StatelessWidget {
  final TutorialStepModel step;
  final int totalSteps;
  final VoidCallback onNext;

  const _TutorialBubble({
    required this.step,
    required this.totalSteps,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = step.stepNumber == totalSteps;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5B8A6B).withOpacity(0.12),
              ),
              child: Icon(step.icon, color: const Color(0xFF5B8A6B), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 進度點 ●●○○○
                      Row(
                        children: List.generate(totalSteps, (index) {
                          final isActive = index < step.stepNumber;
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xFF5B8A6B)
                                  : const Color(0xFFD9D9D9),
                            ),
                          );
                        }),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8A6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onPressed: onNext,
                        child: Text(
                          step.buttonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}