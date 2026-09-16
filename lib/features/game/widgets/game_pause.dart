import 'package:flutter/material.dart';

/// 全遊戲共用的暫停選單彈窗
class GamePause extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback? onTutorial;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GamePause({
    super.key,
    required this.onResume,
    this.onTutorial,
    required this.onRestart,
    required this.onExit,
  });

  /// 靜態呼叫方法
  static Future show(
    BuildContext context, {
    required VoidCallback onResume,
    VoidCallback? onTutorial,
    required VoidCallback onRestart,
    required VoidCallback onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogCtx) => GamePause(
        onResume: () {
          Navigator.of(dialogCtx).pop();
          onResume();
        },
        onTutorial: onTutorial != null
            ? () {
                Navigator.of(dialogCtx).pop();
                onTutorial();
              }
            : null,
        onRestart: () {
          Navigator.of(dialogCtx).pop();
          onRestart();
        },
        onExit: () {
          Navigator.of(dialogCtx).pop();
          onExit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '遊戲暫停',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5A43),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // 1. 繼續遊戲
            _buildSolidButton(
              label: '繼續遊戲',
              bgColor: const Color(0xFF2D5A43),
              textColor: Colors.white,
              onTap: onResume,
            ),
            const SizedBox(height: 16),
            // 2. 玩法教學（可選）
            if (onTutorial != null) ...[
              _buildOutlinedButton(
                label: '玩法教學',
                bgColor: const Color(0xFFEFF5F0),
                borderColor: const Color(0xFFD3E4D6),
                textColor: const Color(0xFF2D5A43),
                onTap: onTutorial!,
              ),
              const SizedBox(height: 16),
            ],
            // 3. 重新開始
            _buildOutlinedButton(
              label: '重新開始',
              bgColor: const Color(0xFFEFF5F0),
              borderColor: const Color(0xFFD3E4D6),
              textColor: const Color(0xFF2D5A43),
              onTap: onRestart,
            ),
            const SizedBox(height: 16),
            // 4. 退出遊戲
            _buildOutlinedButton(
              label: '退出遊戲',
              bgColor: const Color(0xFFFFF7F7),
              borderColor: const Color(0xFFF3D5D5),
              textColor: const Color(0xFFBC4747),
              onTap: onExit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolidButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
