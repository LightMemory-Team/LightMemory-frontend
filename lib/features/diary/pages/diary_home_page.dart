import 'package:flutter/material.dart';
import '../models/diary_model.dart';
import '../services/diary_service.dart';
import '../widgets/diary_calendar.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app_settings.dart';
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
  bool _isFirstLoad = true;
  bool _hasTodayDiary = false;
  List<DiarySummaryModel> _diaries = [];

  @override
  void initState() {
    super.initState();
    _loadMonth(DateTime.now());
  }

  Future<void> _loadMonth(DateTime month) async {
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

    final isDark = AppSettings.isDarkMode.value;
    final isHighContrast = AppSettings.isHighContrast.value;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark
        ? Colors.white
        : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
    final bodyColor = isDark
        ? const Color(0xFFCCCCCC)
        : const Color(0xFF595959);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                  fontSize: AppSettings.scaleFont(AppTheme.fontTitle),
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              if (review.yesterday == null && review.lastYear == null)
                Text(
                  '目前還沒有可以回顧的紀錄',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(14),
                    color: bodyColor,
                  ),
                )
              else ...[
                if (review.yesterday != null) ...[
                  Text(
                    '昨天・${review.yesterday!.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSettings.scaleFont(14),
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.yesterday!.postText,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(14),
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (review.lastYear != null) ...[
                  Text(
                    '去年的今天・${review.lastYear!.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSettings.scaleFont(14),
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.lastYear!.postText,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(14),
                      color: bodyColor,
                    ),
                  ),
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
    final homeData = mockHomeData;

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;

        final bgColor = isDark
            ? const Color(0xFF121212)
            : AppTheme.backgroundColor;
        final cardBg = isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
        // 淺綠底容器（今天已完成／動態回顧按鈕）的深色版本，
        // 團隊目前還沒有指定的深色色票，先用跟 GreetingSection、
        // HomeScreen 深色配色風格接近的顏色頂著，之後設計那邊有
        // 指定的話再換。
        final containerColor = isDark
            ? const Color(0xFF25382E)
            : AppTheme.colorScheme.secondaryContainer;
        final onContainerColor = isDark
            ? const Color(0xFFB8E6D0)
            : AppTheme.colorScheme.onSecondaryContainer;

        return Scaffold(
          backgroundColor: bgColor,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: _hasTodayDiary
                                  ? containerColor
                                  : AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusCard,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _hasTodayDiary ? '已完成今天的紀錄' : '今天',
                                      style: TextStyle(
                                        fontSize: AppSettings.scaleFont(
                                          AppTheme.fontTitle,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: _hasTodayDiary
                                            ? onContainerColor
                                            : Colors.white,
                                      ),
                                    ),
                                    if (!_hasTodayDiary)
                                      Text(
                                        '點擊開始記錄',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: AppSettings.scaleFont(13),
                                        ),
                                      ),
                                  ],
                                ),
                                Icon(
                                  _hasTodayDiary
                                      ? Icons.check_circle
                                      : Icons.add,
                                  color: _hasTodayDiary
                                      ? onContainerColor
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
                              color: containerColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusCard,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '動態回顧',
                                      style: TextStyle(
                                        fontSize: AppSettings.scaleFont(
                                          AppTheme.fontTitle - 4,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: onContainerColor,
                                      ),
                                    ),
                                    Text(
                                      '重溫過往的時光',
                                      style: TextStyle(
                                        color: onContainerColor,
                                        fontSize: AppSettings.scaleFont(13),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.auto_stories,
                                  color: onContainerColor,
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
                            color: cardBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusCard,
                            ),
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
      },
    );
  }
}