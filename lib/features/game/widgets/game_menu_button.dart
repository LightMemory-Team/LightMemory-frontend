import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// 遊戲進行中左上角的「選單」按鈕（10/8 老師建議）
///
/// 取代原本的返回箭頭：箭頭容易讓長輩以為按了會直接離開遊戲，
/// 改成寫著「選單」的深綠色按鈕，點擊後打開暫停選單（GamePause），
/// 繼續遊戲、玩法教學、重新開始、退出遊戲都收在裡面。
class GameMenuButton extends StatelessWidget {
  final VoidCallback onTap;

  /// 橫向遊戲（來去菜市場）頂部空間比較小，用較小的尺寸
  final bool compact;

  const GameMenuButton({super.key, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final height = compact ? 34.0 : 44.0;
    final radius = BorderRadius.circular(height / 2);

    return Material(
      color: AppTheme.primaryColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: compact ? 18 : 22,
              ),
              const SizedBox(width: 6),
              Text(
                '選單',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
