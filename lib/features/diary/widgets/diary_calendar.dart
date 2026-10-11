import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

class DiaryCalendar extends StatefulWidget {
  /// 當月已完成的日記列表（D-1 回傳的 diaries[]），用來在對應日期畫星星
  final List<DiarySummaryModel> diaries;
  /// 使用者換月份時呼叫，外部要重新打 D-1 拿新月份的資料
  final void Function(DateTime focusedMonth) onMonthChanged;
  /// 點擊有星星的日期時呼叫，外部通常會打 D-4 開啟該篇日記
  final void Function(DiarySummaryModel diary) onDiaryTap;

  const DiaryCalendar({
    super.key,
    required this.diaries,
    required this.onMonthChanged,
    required this.onDiaryTap,
  });

  @override
  State<DiaryCalendar> createState() => _DiaryCalendarState();
}

class _DiaryCalendarState extends State<DiaryCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  /// diaries[] 依 date 字串（YYYY-MM-DD）找出當天是否有已完成的日記
  DiarySummaryModel? _diaryForDay(DateTime day) {
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    for (final diary in widget.diaries) {
      if (diary.date == dateStr) return diary;
    }
    return null;
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

        final textColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final mutedTextColor = isDark
            ? const Color(0xFFCCCCCC)
            : const Color(0xFF595959);
        final outsideTextColor = isDark
            ? const Color(0xFF666666)
            : const Color(0xFFBBBBBB);
        // 跟 diary_home_page.dart 的「今天已完成」容器色一致，
        // 深色色票目前是暫定值，待設計端確認。
        final todayContainerColor = isDark
            ? const Color(0xFF25382E)
            : AppTheme.colorScheme.secondaryContainer;
        final todayTextColor = isDark
            ? const Color(0xFFB8E6D0)
            : AppTheme.colorScheme.onSecondaryContainer;

        return TableCalendar<DiarySummaryModel>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          locale: 'zh_TW',
          daysOfWeekHeight: AppSettings.scaleFont(24),
          rowHeight: AppSettings.scaleFont(48),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: AppSettings.scaleFont(13),
              color: mutedTextColor,
            ),
            weekendStyle: TextStyle(
              fontSize: AppSettings.scaleFont(13),
              color: mutedTextColor,
            ),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              color: textColor,
            ),
            weekendTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              color: textColor,
            ),
            outsideTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              color: outsideTextColor,
            ),
            todayTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              fontWeight: FontWeight.bold,
              color: todayTextColor,
            ),
            selectedTextStyle: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            todayDecoration: BoxDecoration(
              color: todayContainerColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            // 有日記紀錄的日期：橘色圓圈包住數字、右上角疊一顆星星
            defaultBuilder: (context, day, focusedDay) {
              final diary = _diaryForDay(day);
              if (diary == null) return null; // 沒有日記的日期用預設樣式，不覆寫
              return Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSettings.scaleFont(14),
                            color: textColor,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(Icons.star, size: 14, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final diary = _diaryForDay(selectedDay);
            if (diary == null) return; // 沒有日記的日期點了沒有作用
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDiaryTap(diary);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            widget.onMonthChanged(focusedDay);
          },
        );
      },
    );
  }
}