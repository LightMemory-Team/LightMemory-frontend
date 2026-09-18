import 'package:flutter/material.dart';

/// 全遊戲共用的暫停選單彈窗（自動自適應直向與橫向）
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
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLandscape ? 24 : 32),
          ),
          child: Container(
            width: isLandscape ? 480 : 320,
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 24 : 28,
              vertical: isLandscape ? 16 : 36,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '遊戲暫停',
                  style: TextStyle(
                    fontSize: isLandscape ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D5A43),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: isLandscape ? 14 : 28),

                // 依據螢幕方向決定排列方式
                if (isLandscape)
                  _buildLandscapeButtons()
                else
                  _buildPortraitButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 橫向模式排版：2x2 雙欄排列，完全不溢位
  Widget _buildLandscapeButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSolidButton(
                label: '繼續遊戲',
                bgColor: const Color(0xFF2D5A43),
                textColor: Colors.white,
                height: 44,
                fontSize: 16,
                onTap: onResume,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: onTutorial != null
                  ? _buildOutlinedButton(
                      label: '玩法教學',
                      bgColor: const Color(0xFFEFF5F0),
                      borderColor: const Color(0xFFD3E4D6),
                      textColor: const Color(0xFF2D5A43),
                      height: 44,
                      fontSize: 16,
                      onTap: onTutorial!,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOutlinedButton(
                label: '重新開始',
                bgColor: const Color(0xFFEFF5F0),
                borderColor: const Color(0xFFD3E4D6),
                textColor: const Color(0xFF2D5A43),
                height: 44,
                fontSize: 16,
                onTap: onRestart,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildOutlinedButton(
                label: '退出遊戲',
                bgColor: const Color(0xFFFFF7F7),
                borderColor: const Color(0xFFF3D5D5),
                textColor: const Color(0xFFBC4747),
                height: 44,
                fontSize: 16,
                onTap: onExit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 直向模式排版：維持原本直向遊戲的樣式
  Widget _buildPortraitButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }

  Widget _buildSolidButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    double height = 54,
    double fontSize = 18,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2.7),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
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
            borderRadius: BorderRadius.circular(height / 2.7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.0,
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
    double height = 54,
    double fontSize = 18,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height / 2.7),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2.7),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
