import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/constants/route_constants.dart';
import '../core/network/error_message.dart';
import '../features/dashboard/pages/weekly_report_page.dart';
import '../features/home/models/home_models.dart';
import '../features/home/pages/all_games_page.dart';
import '../features/home/services/game_launcher.dart';
import '../features/home/services/home_service.dart';
import '../features/home/widgets/daily_task_card.dart';
import '../features/home/widgets/game_card.dart';
import '../features/home/widgets/greeting_section.dart';
import '../features/home/widgets/top_bar.dart';

/// 首頁（依小惠〈首頁改版 API 規格書〉與首頁改版設計）
///
/// 由上到下：招呼語 → 今日任務 → 大腦訓練遊戲（2 張卡片＋查看全部）
/// 三支 API（user、games、daily-tasks）同時呼叫；
/// 從遊戲、日記、週報回到首頁時重新整理，任務才會打勾。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _service = HomeService();

  HomeUser? _user;
  List<HomeGame> _games = [];
  DailyTasks? _dailyTasks;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ============================================================
  // 讀取資料
  // ============================================================

  /// 三支 API 同時呼叫，不用一支等一支
  Future<void> _loadAll() async {
    setState(() {
      _isLoading = _user == null;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getUser(),
        _service.getGames(),
        _service.getDailyTasks(),
      ]);
      if (!mounted) return;

      final user = results[0] as HomeUser;

      // 未讀通知數同步到右上角鈴鐺
      AppSettings.unreadNotificationCount.value = user.unreadNotificationCount;

      setState(() {
        _user = user;
        _games = results[1] as List<HomeGame>;
        _dailyTasks = results[2] as DailyTasks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取首頁失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入首頁');
      });
    }
  }

  /// 從遊戲、日記、週報回來：重新整理今日任務和「本週還沒玩」標籤
  Future<void> _refreshAfterReturn() async {
    try {
      final results = await Future.wait([
        _service.getDailyTasks(),
        _service.getGames(),
      ]);
      if (!mounted) return;
      setState(() {
        _dailyTasks = results[0] as DailyTasks;
        _games = results[1] as List<HomeGame>;
      });
    } catch (e) {
      // 重新整理失敗不擋畫面，維持原本的資料
      debugPrint('❌ 首頁重新整理失敗: $e');
    }
  }

  // ============================================================
  // 點擊
  // ============================================================

  /// 點今日任務：遊戲開那款遊戲、日記開上傳照片頁、上週回顧開週報表
  Future<void> _onTaskTap(DailyTask task) async {
    switch (task.type) {
      case 'game':
        if (task.gameId == null) return;
        await openGame(context, task.gameId!);
        break;
      case 'diary':
        await Navigator.of(context).pushNamed(AppRoutes.voiceDiaryUpload);
        break;
      case 'weekly_report':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const WeeklyReportPage()),
        );
        break;
      default:
        return;
    }
    if (mounted) _refreshAfterReturn();
  }

  Future<void> _onGameTap(HomeGame game) async {
    await openGame(context, game.id);
    if (mounted) _refreshAfterReturn();
  }

  Future<void> _onViewAllTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AllGamesPage()),
    );
    if (mounted) _refreshAfterReturn();
  }

  /// 首頁只顯示 2 張：本週還沒玩的排前面，其他維持後端給的順序
  List<HomeGame> get _homeGames {
    final sorted = [
      ..._games.where((g) => !g.playedThisWeek),
      ..._games.where((g) => g.playedThisWeek),
    ];
    return sorted.take(2).toList();
  }

  // ============================================================
  // Build
  // ============================================================

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

        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final subColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF595959);
        final themeGreen = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(),
          body: _buildBody(titleColor, subColor, themeGreen, isHighContrast),
        );
      },
    );
  }

  Widget _buildBody(
    Color titleColor,
    Color subColor,
    Color themeGreen,
    bool isHighContrast,
  ) {
    // 載入中
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: themeGreen));
    }

    // 載入失敗
    if (_errorMessage != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: subColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '目前無法載入首頁',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppSettings.scaleFont(18), color: subColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '再試一次',
                  style: TextStyle(fontSize: AppSettings.scaleFont(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final homeGames = _homeGames;

    return RefreshIndicator(
      color: themeGreen,
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // 招呼語：日期、早安午安晚安、點數、機器人鼓勵語
          GreetingSection(
            userName: _user!.userName,
            dailyTip: _user!.dailyTip,
          ),
          const SizedBox(height: 20),

          // 今日任務
          if (_dailyTasks != null)
            DailyTaskCard(
              dailyTasks: _dailyTasks!,
              onTaskTap: _onTaskTap,
            ),
          const SizedBox(height: 24),

          // 大腦訓練遊戲標題＋查看全部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '大腦訓練遊戲',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(19),
                  fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
                  color: titleColor,
                ),
              ),
              TextButton(
                onPressed: _onViewAllTap,
                style: TextButton.styleFrom(foregroundColor: themeGreen),
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 兩張遊戲卡片並排
          if (homeGames.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: GameCard(
                    game: homeGames[0],
                    onTap: () => _onGameTap(homeGames[0]),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: homeGames.length > 1
                      ? GameCard(
                          game: homeGames[1],
                          onTap: () => _onGameTap(homeGames[1]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}