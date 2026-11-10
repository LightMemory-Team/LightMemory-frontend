import 'dart:async';

import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/rewards_models.dart';

/// 結算頁的「獲得點數」卡片（依〈點數與成就系統規格〉前端分頁）
///
/// - 顯示本場獲得點數、breakdown 逐行出現、目前總點數
/// - 達每日上限顯示「今天的點數拿滿了，明天再來」
/// - 0 點且沒拿滿：整張卡片不顯示（規格書：不顯示「0 點」）
/// - 明細播完後呼叫 [onFinished]，外面可以接著跳成就解鎖視窗
///
/// 用法：
/// ```dart
/// RewardsEarnedCard(
///   rewards: rewards,
///   forceLight: true, // 五款遊戲維持淺色
///   onFinished: () => showNewAchievements(context, rewards.newAchievements),
/// )
/// ```
class RewardsEarnedCard extends StatefulWidget {
  final RewardsResult rewards;

  /// 五款遊戲維持淺色（規格書），遊戲結算頁傳 true
  final bool forceLight;

  /// 明細全部出現後呼叫（沒有東西可顯示時，一建立就呼叫）
  final VoidCallback? onFinished;

  const RewardsEarnedCard({
    super.key,
    required this.rewards,
    this.forceLight = false,
    this.onFinished,
  });

  @override
  State<RewardsEarnedCard> createState() => _RewardsEarnedCardState();
}

class _RewardsEarnedCardState extends State<RewardsEarnedCard> {
  /// 目前顯示到第幾行明細
  int _visibleLines = 0;
  Timer? _timer;

  static const Duration _lineInterval = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _startReveal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 明細一行一行出現，播完通知外面
  void _startReveal() {
    final lines = widget.rewards.breakdown.length;

    if (!widget.rewards.hasSomethingToShow || lines == 0) {
      // 沒東西要播：等畫面建好再通知，避免在 build 期間跳視窗
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }

    _timer = Timer.periodic(_lineInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _visibleLines++);
      if (_visibleLines >= lines) {
        timer.cancel();
        // 最後一行出現後稍等一下再通知
        Timer(_lineInterval, _finish);
      }
    });
  }

  bool _finished = false;

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = widget.rewards;
    if (!rewards.hasSomethingToShow) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final bool isDark = !widget.forceLight && AppSettings.isDarkMode.value;
        final bool isHighContrast = AppSettings.isHighContrast.value;

        final Color cardBg = isDark ? const Color(0xFF2A2414) : const Color(0xFFFFF8E1);
        final Color border = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF5C4A1A) : const Color(0xFFFFE08A));
        final Color title = isDark ? Colors.white : const Color(0xFF1E1E1E);
        final Color body = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast ? Colors.black : const Color(0xFF4A4A4A));
        final Color green = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342);
        final Color divider = isDark ? const Color(0xFF5C4A1A) : const Color(0xFFFFE08A);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: isHighContrast ? 2 : 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題：本場獲得 +N 點
              if (rewards.pointsEarned > 0)
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 30, color: Color(0xFFFFB300)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '本場獲得 +${rewards.pointsEarned} 點',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(22),
                          fontWeight: FontWeight.bold,
                          color: title,
                        ),
                      ),
                    ),
                  ],
                ),

              // 明細：一行一行出現
              if (rewards.pointsEarned > 0 && rewards.breakdown.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: divider),
                const SizedBox(height: 8),
                for (int i = 0; i < rewards.breakdown.length; i++)
                  AnimatedOpacity(
                    opacity: i < _visibleLines ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              rewards.breakdown[i].label,
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(16),
                                color: body,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${rewards.breakdown[i].points}',
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(17),
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],

              // 目前總點數
              if (rewards.pointsEarned > 0 && rewards.totalPoints > 0) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: divider),
                const SizedBox(height: 10),
                Text(
                  '目前共有 ${rewards.totalPoints} 點',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    fontWeight: FontWeight.w600,
                    color: green,
                  ),
                ),
              ],

              // 達每日上限
              if (rewards.dailyCapReached) ...[
                if (rewards.pointsEarned > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    if (rewards.pointsEarned == 0) ...[
                      const Icon(Icons.monetization_on, size: 26, color: Color(0xFFFFB300)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        '今天的點數拿滿了，明天再來',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(17),
                          fontWeight: FontWeight.bold,
                          color: title,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}