import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/dashboard_models.dart';
import 'dashboard_palette.dart';

/// 週報表點聲影日記相片時開的彈窗：大相片、日期、標題、內文，
/// 關掉後回到週報表原本的位置。
class DiaryPreviewDialog extends StatelessWidget {
  final WeeklyDiaryItem diary;
  final DashboardPalette palette;

  const DiaryPreviewDialog({
    super.key,
    required this.diary,
    required this.palette,
  });

  static Future<void> show(
    BuildContext context, {
    required WeeklyDiaryItem diary,
    required DashboardPalette palette,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DiaryPreviewDialog(diary: diary, palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final date = diary.date;
    final dateText = '${date.month}/${date.day}（${weekdays[date.weekday - 1]}）';

    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: palette.isHighContrast
            ? BorderSide(color: palette.title, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  diary.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: palette.soft,
                    child: Icon(
                      Icons.photo_outlined,
                      size: 56,
                      color: palette.onSoft,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              dateText,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(16),
                fontWeight: FontWeight.w600,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              diary.title,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(22),
                fontWeight: FontWeight.bold,
                color: palette.title,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  diary.postText,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    height: 1.5,
                    color: palette.title,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '關閉',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
