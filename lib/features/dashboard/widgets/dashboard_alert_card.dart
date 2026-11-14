import 'package:flutter/material.dart';

import '../../../app_settings.dart';
import '../models/dashboard_models.dart';
import 'dashboard_palette.dart';

/// 儀表板「小提醒」卡片：近期某一場遊戲的表現比平常低很多時出現。
///
/// 只是「建議多注意」，不是醫療判斷：文案由後端產生（不寫「異常」「退步」），
/// 每筆附「去玩一次」，讓長輩休息後再試一次
class DashboardAlertCard extends StatelessWidget {
  final List<DashboardAlert> alerts;
  final DashboardPalette palette;

  /// 點「去玩一次」：由儀表板頁開對應的遊戲
  final ValueChanged<String> onPlay;

  const DashboardAlertCard({
    super.key,
    required this.alerts,
    required this.palette,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final fg = palette.alertForeground;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
      decoration: BoxDecoration(
        color: palette.alertBackground,
        borderRadius: BorderRadius.circular(20),
        border: palette.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: fg, size: 26),
              const SizedBox(width: 8),
              Text(
                '小提醒',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(19),
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ],
          ),
          for (final (index, alert) in alerts.indexed) ...[
            if (index > 0)
              Divider(height: 12, color: fg.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 6),
              child: Text(
                alert.message,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(16),
                  height: 1.5,
                  color: palette.title,
                ),
              ),
            ),
            if (alert.gameId.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onPlay(alert.gameId),
                  style: TextButton.styleFrom(
                    foregroundColor: fg,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(
                    alert.gameTitle.isEmpty ? '去玩一次' : '去玩一次「${alert.gameTitle}」',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
