import 'package:flutter/material.dart';
import '../models/diary_model.dart';
import '../services/diary_service.dart';
import '../widgets/diary_calendar.dart';
import '../widgets/diary_day_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app_settings.dart';
import '../../../core/navigation/app_route_observer.dart';
import '../../home/widgets/top_bar.dart';
import '../../home/widgets/greeting_section.dart';
import '../../home/models/home_data.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> with RouteAware {
  final DiaryService _diaryService = DiaryService();

  bool _isLoading = true;
  bool _isFirstLoad = true;
  bool _hasError = false;
  bool _hasTodayDiary = false;
  List<DiarySummaryModel> _diaries = [];

  @override
  void initState() {
    super.initState();
    _loadMonth(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 上面的頁面都關掉、主畫面重新顯示時呼叫（例如寫完日記在完成頁按「回首頁」），
  /// 重新讀取這個月的資料，「已完成今天的紀錄」和月曆上今天的照片才會馬上出現。
  ///
  /// 不能用「await 進入上傳頁」的寫法：上傳頁、聊天頁、生成頁都用
  /// pushReplacementNamed 換頁，上傳頁一被聊天頁取代，await 就結束了，
  /// 那時候日記根本還沒寫完。
  @override
  void didPopNext() {
    _loadMonth(DateTime.now());
  }

  Future<void> _loadMonth(DateTime month) async {
    if (_isFirstLoad) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    try {
      final result = await _diaryService.getDiaryList(month: monthStr);
      if (!mounted) return;
      setState(() {
        _hasTodayDiary = result.hasTodayDiary;
        _diaries = result.diaries;
        _isLoading = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
        _hasError = true;
      });
    }
  }

  void _onTodayTap() {
    if (_hasTodayDiary) return;
    // 寫完回來時的重新讀取由 didPopNext() 處理
    Navigator.pushNamed(context, AppRoutes.voiceDiaryUpload);
  }

  /// 點月曆上有日記的日期：跳出小視窗顯示那天的日記（10/21 會議決議）
  void _onDiaryTap(DiarySummaryModel diary) {
    DiaryDayDialog.show(context, diary);
  }

  /// 動態回顧：原本是底部彈窗，改成獨立頁面（對照比賽版 review.html）
  void _onReviewTap() {
    Navigator.pushNamed(context, AppRoutes.voiceDiaryReview);
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
        final subtitleColor = isDark
            ? const Color(0xFFCCCCCC)
            : AppTheme.colorScheme.onSurfaceVariant;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(title: '聲影日記'),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '讀取失敗，請檢查登入狀態後再試一次',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(14),
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _loadMonth(DateTime.now()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                            ),
                          ),
                          child: Text(
                            '重新載入',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppSettings.scaleFont(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
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
                                  ? containerColor
                                  : AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusCard,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 用 Expanded 包住文字，畫面窄或字體放大時文字換行，
                                // 不會把右邊圖示擠出卡片（RenderFlex overflowed）
                                Expanded(
                                  child: Column(
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
                                ),
                                const SizedBox(width: 12),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
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
                                ),
                                const SizedBox(width: 12),
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
