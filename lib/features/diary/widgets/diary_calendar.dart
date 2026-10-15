import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

class DiaryCalendar extends StatefulWidget {
  /// 當月已完成的日記列表（D-1 回傳的 diaries[]），用來在對應日期顯示日記照片
  final List<DiarySummaryModel> diaries;
  /// 使用者換月份時呼叫，外部要重新打 D-1 拿新月份的資料
  final void Function(DateTime focusedMonth) onMonthChanged;
  /// 點擊有日記的日期時呼叫，外部通常會打 D-4 開啟該篇日記
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
          // 點日記是打開那篇日記，不需要「選取」狀態；
          // 原本會把點過的日期變成深綠圓圈、蓋掉日記標記，所以拿掉
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
            todayDecoration: BoxDecoration(
              color: todayContainerColor,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            // 有日記的日期：用那天的日記照片填滿圓形、外圈金色（對照比賽版 index.css 的 .dot-photo）。
            // 用 prioritizedBuilder 而不是 defaultBuilder，今天剛好有日記時也會顯示照片，
            // 不會被「今天」的樣式蓋掉。
            prioritizedBuilder: (context, day, focusedDay) {
              if (day.month != focusedDay.month) return null; // 上下個月的灰色日期不處理
              final diary = _diaryForDay(day);
              if (diary == null) return null; // 沒有日記的日期用預設樣式
              return Center(
                child: _DiaryDayMarker(
                  day: day.day,
                  photoUrl: diary.photoUrl,
                  textColor: textColor,
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final diary = _diaryForDay(selectedDay);
            if (diary == null) return; // 沒有日記的日期點了沒有作用
            setState(() => _focusedDay = focusedDay);
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

/// 月曆上有日記的那一天：日記照片填滿圓形＋金色外框。
/// 沒有照片或照片載入失敗時，退回淡金色底＋日期數字，至少看得出這天有寫日記。
class _DiaryDayMarker extends StatelessWidget {
  final int day;
  final String photoUrl;
  final Color textColor;

  const _DiaryDayMarker({
    required this.day,
    required this.photoUrl,
    required this.textColor,
  });

  static const double _size = 40;
  static const Color _gold = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: _gold.withValues(alpha: 0.22),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: AppSettings.scaleFont(14),
          color: textColor,
        ),
      ),
    );

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold, width: 2.5),
      ),
      child: ClipOval(
        child: photoUrl.isEmpty
            ? fallback
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}
