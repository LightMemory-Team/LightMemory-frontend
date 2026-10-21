import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/dashboard_models.dart';
import 'dashboard_palette.dart';
import 'robot_avatar.dart';

/// 儀表板最上方的狀態卡片：左邊機器人（依狀態換表情），右邊標題＋說明，
/// 文字都是後端回傳的值。
class DashboardStatusCard extends StatelessWidget {
  final DashboardStatus status;
  final DashboardPalette palette;

  const DashboardStatusCard({
    super.key,
    required this.status,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: palette.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFF3F6E5A),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: RobotAvatar(mood: status.mood, size: 92),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.title,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(24),
                      fontWeight: FontWeight.bold,
                      color: palette.onSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  status.message,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: palette.title,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
