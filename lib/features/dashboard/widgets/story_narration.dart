import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/dashboard_models.dart';
import 'dashboard_palette.dart';
import 'robot_avatar.dart';

/// 週報表區塊之間的機器人旁白：小機器人頭像＋對話泡泡。
/// 文字是固定的銜接句，不跟著資料變動；一句最多兩行。
class StoryNarration extends StatelessWidget {
  final String text;
  final DashboardPalette palette;
  final DashboardMood mood;

  const StoryNarration({
    super.key,
    required this.text,
    required this.palette,
    this.mood = DashboardMood.keep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: RobotAvatar(mood: mood, size: 42),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.card,
              border: palette.cardBorder,
              boxShadow: palette.cardShadow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: palette.title,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
