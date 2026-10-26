import 'package:flutter/material.dart';
import '../models/diary_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 點月曆上有日記的日期時跳出的小視窗（10/21 會議決議）：
/// 由上到下是「幾月幾日的日記」、照片、標題、內文，按「關閉」回到月曆。
/// 內容直接用月曆（D-1）已經拿到的資料，不用再打 API。
class DiaryDayDialog extends StatelessWidget {
  final DiarySummaryModel diary;

  const DiaryDayDialog({super.key, required this.diary});

  static Future<void> show(BuildContext context, DiarySummaryModel diary) {
    return showDialog(
      context: context,
      builder: (_) => DiaryDayDialog(diary: diary),
    );
  }

  /// 'YYYY-MM-DD' → '10月26日（一）的日記'；格式不對就原樣顯示
  String _formatHeading(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.month}月${date.day}日（${weekdays[date.weekday - 1]}）的日記';
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
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        // 深色沿用動態回顧頁的配色
        final cardColor = isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
        final titleColor = isDark ? Colors.white : AppTheme.primaryColor;
        final bodyColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final dateColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast
                ? const Color(0xFF333333)
                : AppTheme.colorScheme.onSurfaceVariant);
        final placeholderColor = isDark
            ? const Color(0xFF25382E)
            : AppTheme.colorScheme.secondaryContainer;

        final placeholder = Container(
          color: placeholderColor,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, size: 48, color: dateColor),
        );

        return Dialog(
          backgroundColor: cardColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isHighContrast && !isDark
                ? const BorderSide(color: Colors.black, width: 2)
                : BorderSide.none,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 480,
            ),
            // 整個視窗一起捲動：螢幕矮（手機橫放）或字體放大時，內容不會被擠爆
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 最上面先說是哪一天的日記
                  Text(
                    _formatHeading(diary.date),
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(17),
                      fontWeight: FontWeight.bold,
                      color: dateColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 照片用 16:9（同動態回顧頁），留空間給文字
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: diary.photoUrl.isEmpty
                          ? placeholder
                          : Image.network(
                              diary.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  placeholder,
                            ),
                    ),
                  ),
                  if (diary.title.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      diary.title,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(20),
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    diary.postText,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(17),
                      height: 1.6,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '關閉',
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
      },
    );
  }
}
