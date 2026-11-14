import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/rewards_models.dart';

/// 成就卡片（依〈點數與成就系統規格〉前端分頁）
///
/// - 已解鎖：金色勳章 military_tech（#FFB300），顯示解鎖日期
/// - 未解鎖：灰色鎖頭 lock（#7A7A7A），整張卡片置灰，顯示進度 current / target
class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  /// 2026-11-09 → 2026/11/09
  String _formatDate(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final colors = RewardsColors.of(
          isDark: AppSettings.isDarkMode.value,
          isHighContrast: AppSettings.isHighContrast.value,
        );
        final bool unlocked = achievement.unlocked;

        final Color titleColor = unlocked ? colors.title : colors.lockedText;
        final Color bodyColor = unlocked ? colors.subtitle : colors.lockedText;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked ? colors.cardBg : colors.lockedBg,
            borderRadius: BorderRadius.circular(20),
            border: colors.isHighContrast
                ? Border.all(color: colors.title, width: 2)
                : Border.all(color: unlocked ? colors.goldBorder : colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 圖示：已解鎖金色勳章、未解鎖灰色鎖頭
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: unlocked ? colors.goldBg : colors.lockedIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.military_tech : Icons.lock,
                  size: 32,
                  color: unlocked ? RewardsColors.gold : RewardsColors.lockGrey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名稱＋點數
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(18),
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${achievement.points} 點',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(15),
                            fontWeight: FontWeight.bold,
                            color: unlocked ? colors.green : colors.lockedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 解鎖條件
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(15),
                        color: bodyColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 已解鎖：日期；未解鎖：進度條＋current / target
                    if (unlocked)
                      Text(
                        '${_formatDate(achievement.unlockedAt)} 解鎖',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(14),
                          fontWeight: FontWeight.w600,
                          color: colors.green,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: achievement.progressRatio,
                                minHeight: 8,
                                backgroundColor: colors.progressBg,
                                valueColor: AlwaysStoppedAnimation(colors.progressFill),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${achievement.current} / ${achievement.target}',
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(14),
                              fontWeight: FontWeight.bold,
                              color: colors.lockedText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 點數與成就共用顏色：跟著深色模式、高對比切換
class RewardsColors {
  /// 規格書：已解鎖勳章金色、未解鎖鎖頭灰色
  static const Color gold = Color(0xFFFFB300);
  static const Color lockGrey = Color(0xFF7A7A7A);

  final bool isDark;
  final bool isHighContrast;
  final Color pageBg;
  final Color cardBg;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color green;
  final Color goldBg;
  final Color goldBorder;
  final Color lockedBg;
  final Color lockedIconBg;
  final Color lockedText;
  final Color progressBg;
  final Color progressFill;

  const RewardsColors._({
    required this.isDark,
    required this.isHighContrast,
    required this.pageBg,
    required this.cardBg,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.green,
    required this.goldBg,
    required this.goldBorder,
    required this.lockedBg,
    required this.lockedIconBg,
    required this.lockedText,
    required this.progressBg,
    required this.progressFill,
  });

  factory RewardsColors.of({required bool isDark, required bool isHighContrast}) {
    if (isDark) {
      return RewardsColors._(
        isDark: true,
        isHighContrast: isHighContrast,
        pageBg: const Color(0xFF121212),
        cardBg: const Color(0xFF1E1E1E),
        border: const Color(0xFF333333),
        title: Colors.white,
        subtitle: const Color(0xFFCCCCCC),
        green: const Color(0xFF4CAF50),
        goldBg: const Color(0xFF3A2F12),
        goldBorder: const Color(0xFF5C4A1A),
        lockedBg: const Color(0xFF1A1A1A),
        lockedIconBg: const Color(0xFF2A2A2A),
        lockedText: const Color(0xFF9A9A9A),
        progressBg: const Color(0xFF333333),
        progressFill: const Color(0xFF8A8A8A),
      );
    }
    return RewardsColors._(
      isDark: false,
      isHighContrast: isHighContrast,
      pageBg: const Color(0xFFF5F4EE),
      cardBg: Colors.white,
      border: const Color(0xFFE5E5E5),
      title: isHighContrast ? Colors.black : const Color(0xFF1E1E1E),
      subtitle: isHighContrast ? Colors.black : const Color(0xFF595959),
      green: const Color(0xFF2E6342),
      goldBg: const Color(0xFFFFF4D6),
      goldBorder: const Color(0xFFFFE08A),
      lockedBg: const Color(0xFFF0F0F0),
      lockedIconBg: const Color(0xFFE2E2E2),
      lockedText: isHighContrast ? Colors.black : const Color(0xFF7A7A7A),
      progressBg: const Color(0xFFDDDDDD),
      progressFill: const Color(0xFF9E9E9E),
    );
  }
}