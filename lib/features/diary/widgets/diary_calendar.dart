import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary_model.dart';
import '../../../theme/app_theme.dart';

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
    return TableCalendar<DiarySummaryModel>(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      locale: 'zh_TW',
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppTheme.colorScheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      eventLoader: (day) {
        final diary = _diaryForDay(day);
        return diary == null ? [] : [diary];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          return const Positioned(
            bottom: 2,
            child: Icon(Icons.star, size: 12, color: Colors.amber),
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
  }
}