import 'package:flutter/material.dart';

/// 暫時版本的暫停選單，等組員的正式版推上來後可整份取代
class GamePause {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResume,
    VoidCallback? onTutorial,
    required VoidCallback onRestart,
    required VoidCallback onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '遊戲暫停',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3D6B4A)),
              ),
              const SizedBox(height: 24),
              _buildButton(
                context,
                label: '繼續遊戲',
                color: const Color(0xFF5B8A6B),
                textColor: Colors.white,
                onTap: () {
                  Navigator.of(context).pop();
                  onResume();
                },
              ),
              if (onTutorial != null) ...[
                const SizedBox(height: 12),
                _buildButton(
                  context,
                  label: '玩法教學',
                  color: const Color(0xFFF6F8F3),
                  textColor: const Color(0xFF3D6B4A),
                  onTap: () {
                    Navigator.of(context).pop();
                    onTutorial();
                  },
                ),
              ],
              const SizedBox(height: 12),
              _buildButton(
                context,
                label: '重新開始',
                color: const Color(0xFFF6F8F3),
                textColor: const Color(0xFF3D6B4A),
                onTap: () {
                  Navigator.of(context).pop();
                  onRestart();
                },
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                label: '退出遊戲',
                color: const Color(0xFFFFF0F0),
                textColor: const Color(0xFFD32F2F),
                onTap: () {
                  Navigator.of(context).pop();
                  onExit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildButton(
    BuildContext context, {
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}