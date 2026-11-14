import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/rewards_models.dart';

/// 成就解鎖視窗（依〈點數與成就系統規格〉前端分頁）
///
/// - new_achievements 不是空陣列時才跳
/// - 有多個時依序顯示（前面的按「下一個」，最後一個按「太棒了！」）
/// - 不會自動消失，一定要按按鈕才關，長輩不會錯過
/// - 五款遊戲維持淺色：遊戲結算頁傳 forceLight: true
/// - 橫向畫面（來去菜市場、料理準備）高度比較矮：勳章縮小、內容可以上下捲動，避免溢版
///
/// 用法（等結算明細播完再跳）：
/// ```dart
/// RewardsEarnedCard(
///   rewards: rewards,
///   onFinished: () => showNewAchievements(context, rewards.newAchievements),
/// )
/// ```
Future<void> showNewAchievements(
  BuildContext context,
  List<NewAchievement> achievements, {
  bool forceLight = false,
}) async {
  for (int i = 0; i < achievements.length; i++) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // 點外面不會關，一定要按按鈕
      builder: (dialogContext) => _AchievementUnlockDialog(
        achievement: achievements[i],
        index: i,
        total: achievements.length,
        forceLight: forceLight,
      ),
    );
  }
}

class _AchievementUnlockDialog extends StatelessWidget {
  final NewAchievement achievement;
  final int index;
  final int total;
  final bool forceLight;

  const _AchievementUnlockDialog({
    required this.achievement,
    required this.index,
    required this.total,
    required this.forceLight,
  });

  static const Color _gold = Color(0xFFFFB300);

  String get _categoryLabel {
    switch (achievement.category) {
      case 'exploration':
        return '探索類';
      case 'training':
        return '訓練類';
      case 'milestone':
        return '里程碑類';
      default:
        return '成就';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = !forceLight && AppSettings.isDarkMode.value;
    final bool isHighContrast = AppSettings.isHighContrast.value;

    // 畫面矮（橫向手機）時用精簡版：勳章縮小、間距變小
    final bool isShort = MediaQuery.of(context).size.height < 500;
    final double medalBox = isShort ? 64 : 110;
    final double medalIcon = isShort ? 42 : 72;
    final double gapSmall = isShort ? 4 : 8;
    final double gapLarge = isShort ? 10 : 18;

    final Color bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color title = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final Color body = isDark
        ? const Color(0xFFCCCCCC)
        : (isHighContrast ? Colors.black : const Color(0xFF4A4A4A));
    final Color green = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342);
    final Color chipBg = isDark ? const Color(0xFF25382E) : const Color(0xFFE3EDE5);
    final Color goldBg = isDark ? const Color(0xFF3A2F12) : const Color(0xFFFFF4D6);

    final bool isLast = index == total - 1;

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: isHighContrast
            ? BorderSide(color: isDark ? Colors.white : Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: ConstrainedBox(
        // 橫向畫面也不會拉得太寬
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          // 畫面再矮也不會被切掉，滑一下就看得到按鈕
          padding: EdgeInsets.fromLTRB(24, isShort ? 16 : 28, 24, isShort ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 多個成就時顯示「第 1 個，共 2 個」
              if (total > 1)
                Padding(
                  padding: EdgeInsets.only(bottom: gapSmall),
                  child: Text(
                    '第 ${index + 1} 個，共 $total 個',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(14),
                      color: body,
                    ),
                  ),
                ),

              // 金色勳章：彈出來的動畫
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: medalBox,
                  height: medalBox,
                  decoration: BoxDecoration(color: goldBg, shape: BoxShape.circle),
                  child: Icon(Icons.military_tech, size: medalIcon, color: _gold),
                ),
              ),
              SizedBox(height: gapLarge),

              Text(
                '恭喜解鎖成就！',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  fontWeight: FontWeight.w600,
                  color: green,
                ),
              ),
              SizedBox(height: gapSmall),

              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(isShort ? 22 : 26),
                  fontWeight: FontWeight.bold,
                  color: title,
                ),
              ),
              const SizedBox(height: 6),

              if (achievement.description.isNotEmpty)
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    color: body,
                    height: 1.4,
                  ),
                ),
              SizedBox(height: isShort ? 10 : 16),

              // 類別＋點數
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _chip(_categoryLabel, chipBg, green),
                  if (achievement.points > 0)
                    _chip('+${achievement.points} 點', goldBg, const Color(0xFF8A5A00),
                        icon: Icons.monetization_on),
                ],
              ),
              SizedBox(height: isShort ? 14 : 24),

              // 按鈕：不會自動關
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    isLast ? '太棒了！' : '下一個',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFFFFB300)),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(15),
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}