import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/rewards_models.dart';
import 'achievement_unlock.dart';
import 'rewards_earned_card.dart';

/// 用「視窗」顯示獲得點數，接著跳成就解鎖視窗
///
/// 給結算畫面本身就是小視窗、塞不下點數卡片的遊戲用
/// （來去菜市場、料理準備是橫向畫面，結算是 MarketResultDialog）。
/// 流程：點數視窗（按「繼續」）→ 成就解鎖視窗（有新成就才跳）→ 回到呼叫端
///
/// - 0 點且沒拿滿：不跳點數視窗（規格書：不顯示「0 點」）
/// - 沒有新成就：不跳成就視窗
///
/// 用法（在開原本的結算視窗「之前」呼叫）：
/// ```dart
/// await showRewardsAndAchievements(context, rewards, forceLight: true);
/// // 再開原本的結算視窗
/// ```
Future<void> showRewardsAndAchievements(
  BuildContext context,
  RewardsResult rewards, {
  bool forceLight = false,
}) async {
  if (rewards.hasSomethingToShow && context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // 點外面不會關，一定要按「繼續」
      builder: (dialogContext) => _RewardsDialog(
        rewards: rewards,
        forceLight: forceLight,
      ),
    );
  }

  if (rewards.newAchievements.isNotEmpty && context.mounted) {
    await showNewAchievements(
      context,
      rewards.newAchievements,
      forceLight: forceLight,
    );
  }
}

class _RewardsDialog extends StatelessWidget {
  final RewardsResult rewards;
  final bool forceLight;

  const _RewardsDialog({required this.rewards, required this.forceLight});

  @override
  Widget build(BuildContext context) {
    final bool isDark = !forceLight && AppSettings.isDarkMode.value;
    final Color bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color green = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        // 橫向畫面也不會太寬
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          // 橫向畫面高度比較矮，內容可以上下捲動
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 跟其他遊戲結算頁同一張卡片；成就視窗由外面接著跳，這裡不重複跳
              RewardsEarnedCard(rewards: rewards, forceLight: forceLight),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    '繼續',
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
}