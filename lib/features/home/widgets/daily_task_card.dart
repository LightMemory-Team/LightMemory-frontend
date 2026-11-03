import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/home_models.dart';

/// 首頁「今日任務」卡片（依首頁改版設計）
///
/// - 標題「今日任務」＋右邊「完成 1 / 5」
/// - 進度條：completed_count ÷ total_count
/// - 任務清單：完成的打勾＋刪除線；沒完成的空心圓＋右邊箭頭，點了跳到對應頁面
class DailyTaskCard extends StatelessWidget {
  final DailyTasks dailyTasks;

  /// 點沒完成的任務時呼叫，由首頁決定跳到哪一頁（遊戲、日記、週報）
  final ValueChanged<DailyTask> onTaskTap;

  const DailyTaskCard({
    super.key,
    required this.dailyTasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.isDarkMode,
        AppSettings.fontSizeLevel,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final colors = _TaskColors(isDark: isDark, isHighContrast: isHighContrast);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: isHighContrast
                ? Border.all(color: colors.title, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題＋完成數
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '今日任務',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(19),
                        fontWeight: FontWeight.bold,
                        color: colors.title,
                      ),
                    ),
                  ),
                  Text(
                    '完成 ${dailyTasks.completedCount} / ${dailyTasks.totalCount}',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 進度條
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: dailyTasks.progress,
                  minHeight: 10,
                  backgroundColor: colors.itemBg,
                  valueColor: AlwaysStoppedAnimation(colors.green),
                ),
              ),
              const SizedBox(height: 14),

              // 任務清單
              if (dailyTasks.tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '今天的任務還在準備中',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(15),
                      color: colors.subtitle,
                    ),
                  ),
                )
              else
                ...dailyTasks.tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TaskItem(
                      task: task,
                      colors: colors,
                      onTap: task.done ? null : () => onTaskTap(task),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 一列任務：圓圈／打勾＋標題＋箭頭
class _TaskItem extends StatelessWidget {
  final DailyTask task;
  final _TaskColors colors;
  final VoidCallback? onTap;

  const _TaskItem({
    required this.task,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool done = task.done;

    return Material(
      color: colors.itemBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // 完成：實心綠圓＋白色打勾；沒完成：空心綠圓
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? colors.green : Colors.transparent,
                  border: Border.all(color: colors.green, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    fontWeight: FontWeight.w600,
                    color: done ? colors.doneText : colors.title,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: colors.doneText,
                  ),
                ),
              ),
              if (!done)
                Icon(Icons.chevron_right, size: 26, color: colors.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片顏色：跟著深色模式、高對比切換
class _TaskColors {
  final Color cardBg;
  final Color itemBg;
  final Color title;
  final Color subtitle;
  final Color green;
  final Color doneText;

  factory _TaskColors({required bool isDark, required bool isHighContrast}) {
    if (isDark) {
      return const _TaskColors._(
        cardBg: Color(0xFF25382E),
        itemBg: Color(0xFF1E1E1E),
        title: Colors.white,
        subtitle: Color(0xFFCCCCCC),
        green: Color(0xFF4CAF50),
        doneText: Color(0xFF8A8A8A),
      );
    }
    return _TaskColors._(
      cardBg: const Color(0xFFE3EDE5),
      itemBg: Colors.white,
      title: isHighContrast ? Colors.black : const Color(0xFF1E1E1E),
      subtitle: isHighContrast ? Colors.black : const Color(0xFF595959),
      green: const Color(0xFF2E6342),
      doneText: isHighContrast ? const Color(0xFF333333) : const Color(0xFF8A8A8A),
    );
  }

  const _TaskColors._({
    required this.cardBg,
    required this.itemBg,
    required this.title,
    required this.subtitle,
    required this.green,
    required this.doneText,
  });
}