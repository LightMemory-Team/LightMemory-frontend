import 'package:flutter/material.dart';
import '../models/diary_model.dart';
import '../services/diary_service.dart';
import '../widgets/diary_calendar.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../home/widgets/top_bar.dart';
import '../../home/widgets/greeting_section.dart';
import '../../home/models/home_data.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  final DiaryService _diaryService = DiaryService();

  bool _isLoading = true;
  bool _isFirstLoad = true; // 只有第一次進頁面才整頁轉圈圈
  bool _hasTodayDiary = false;
  List<DiarySummaryModel> _diaries = [];

  @override
  void initState() {
    super.initState();
    _loadMonth(DateTime.now());
  }

  Future<void> _loadMonth(DateTime month) async {
    // 只有第一次載入時才顯示整頁 loading。
    // 切換月份時如果也整頁轉圈圈，DiaryCalendar 會被整個卸載重建，
    // 導致它內部記錄目前顯示月份的 _focusedDay 被重置成「今天」。
    if (_isFirstLoad) {
      setState(() => _isLoading = true);
    }

    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final result = await _diaryService.getDiaryList(month: monthStr);
    if (!mounted) return;
    setState(() {
      _hasTodayDiary = result.hasTodayDiary;
      _diaries = result.diaries;
      _isLoading = false;
      _isFirstLoad = false;
    });
  }

  void _onTodayTap() {
    if (_hasTodayDiary) return;
    Navigator.pushNamed(context, AppRoutes.voiceDiaryUpload);
  }

  void _onDiaryTap(DiarySummaryModel diary) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('之後這裡會開啟「${diary.title}」的回顧畫面')),
    );
  }

  Future<void> _onReviewTap() async {
    final review = await _diaryService.getDiaryReview();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '動態回顧',
                style: TextStyle(
                  fontSize: AppTheme.fontTitle,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (review.yesterday == null && review.lastYear == null)
                const Text('目前還沒有可以回顧的紀錄')
              else ...[
                if (review.yesterday != null) ...[
                  Text('昨天・${review.yesterday!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(review.yesterday!.postText),
                  const SizedBox(height: 16),
                ],
                if (review.lastYear != null) ...[
                  Text('去年的今天・${review.lastYear!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(review.lastYear!.postText),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorScheme;
    final homeData = mockHomeData;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const TopBar(title: '聲影日記'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadMonth(DateTime.now()),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    GreetingSection(
                      userName: homeData.userName,
                      dailyTip: '今天想記錄下什麼美好的回憶嗎？',
                    ),
                    const SizedBox(height: 20),
                    // 今天按鈕
                    GestureDetector(
                      onTap: _onTodayTap,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: _hasTodayDiary
                              ? colorScheme.secondaryContainer
                              : AppTheme.primaryColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _hasTodayDiary ? '已完成今天的紀錄' : '今天',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontTitle,
                                    fontWeight: FontWeight.bold,
                                    color: _hasTodayDiary
                                        ? colorScheme.onSecondaryContainer
                                        : Colors.white,
                                  ),
                                ),
                                if (!_hasTodayDiary)
                                  const Text(
                                    '點擊開始記錄',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                            Icon(
                              _hasTodayDiary ? Icons.check_circle : Icons.add,
                              color: _hasTodayDiary
                                  ? colorScheme.onSecondaryContainer
                                  : Colors.white,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 動態回顧按鈕
                    GestureDetector(
                      onTap: _onReviewTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '動態回顧',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontTitle - 4,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  '重溫過往的時光',
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.auto_stories,
                              color: colorScheme.onSecondaryContainer,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 月曆
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                      ),
                      child: DiaryCalendar(
                        diaries: _diaries,
                        onMonthChanged: _loadMonth,
                        onDiaryTap: _onDiaryTap,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}