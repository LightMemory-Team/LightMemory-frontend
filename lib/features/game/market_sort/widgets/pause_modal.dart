import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

// 暫時測試用的深綠色，照組員截圖目測估的，不是正式色碼，
// 之後要跟組員要正確 hex 值定案，不要直接沿用這個數字
const _testPrimaryColor = Color(0xFF2E5940);

class PauseModal extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onTutorial;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const PauseModal({
    super.key,
    required this.onResume,
    required this.onTutorial,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '遊戲暫停',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _testPrimaryColor,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _testPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '繼續遊戲',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SecondaryButton(label: '玩法教學', onPressed: onTutorial),
              const SizedBox(height: 18),
              _SecondaryButton(label: '重新開始', onPressed: onRestart),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onExit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.red.shade50,
                  side: BorderSide(color: Colors.red.shade100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '退出遊戲',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: _testPrimaryColor.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _testPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}