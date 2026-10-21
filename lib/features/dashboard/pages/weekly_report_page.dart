import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../../auth/pages/auth_gate.dart';
import '../../game/cooking_prep/pages/cooking_prep_game_page.dart';
import '../../game/fridge_inventory/pages/fridge_tutorial_page.dart';
import '../../game/go_to_market/pages/go_to_market_tutorial_page.dart';
import '../../game/market_shopping/pages/market_shopping_game_page.dart';
import '../../home/widgets/top_bar.dart';
import '../models/ability_catalog.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../widgets/ability_action_dialog.dart';
import '../widgets/dashboard_load_state.dart';
import '../widgets/dashboard_palette.dart';
import '../widgets/diary_preview_dialog.dart';
import '../widgets/reveal_on_scroll.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/story_narration.dart';
import '../widgets/story_step.dart';
import '../widgets/weekly_report_sections.dart';
import 'ability_detail_page.dart';
import 'diary_from_report_page.dart';

/// 每一頁（旁白＋區塊）的最小高度，佔可捲動區域高度的比例。內容靠上對齊
const double kStoryMinHeightFactor = 0.45;

/// 頁跟頁之間的間距
const double kStoryStepGap = 32;

/// 收尾頁（機器人道別＋「回上一頁」）的最小高度比例，內容置中
const double kStoryEndingMinHeightFactor = 0.7;

/// 週報表：上一個完整的週（週一到週日），一直往下滑、一頁講一件事，
/// 每個區塊捲到畫面上時才進場（RevealOnScroll）。
///
/// 故事感：每頁前面有機器人旁白銜接，左側旅程線的圓點隨捲動依序亮起，
/// 每頁有最小高度（見上方常數），最後以機器人道別收尾。旁白、旅程線都只是
/// 固定文字和版面，不讀資料、不做計算。
///
/// 只跟自己比：不放同齡平均、不放雷達圖、不放一週曲線圖，
/// 不使用紅色和負面字眼。
class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final DashboardService _service = DashboardService();
  WeeklyReport? _report;
  bool _isLoading = true;

  // 旅程線：每一頁的圓點亮了沒（開場、三個數字、打卡、本週 vs 上週、
  // 聲影日記、下週目標、收尾，共 7 頁）
  final List<bool> _stepLit = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final report = await _service.getWeeklyReport();
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } on NotLoggedInException {
      // 沒登入或 token 無效：清掉 token，交給 AuthGate 走登入流程
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('週報表資料讀取失敗：$e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 點「本週 vs 上週」的單項能力：先問要去玩還是看說明
  Future<void> _onAbilityTap(String abilityId) async {
    final ability = abilityById(abilityId);
    final action = await AbilityActionDialog.show(
      context,
      ability: ability,
      palette: DashboardPalette.current(),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case AbilityAction.play:
        _playAbility(ability);
      case AbilityAction.explain:
        _openAbility(abilityId);
    }
  }

  void _openAbility(String abilityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AbilityDetailPage(
          initialAbilityId: abilityId,
          fromWeeklyReport: true,
        ),
      ),
    );
  }

  /// 「前往遊玩」：各能力對應的遊戲入口。
  /// 照抄自 lib/screens/game_home_screen.dart 的 DomainCard onTap，
  /// 遊戲首頁換了入口時這裡要一起改。語言（聲影日記）遊戲首頁沒有，
  /// 這裡另外開聲影日記首頁。
  void _playAbility(CognitiveAbility ability) {
    if (ability.id == 'language') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiaryFromReportPage()),
      );
    } else if (ability.id == 'visual_spatial') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FridgeTutorialPage()),
      );
    } else if (ability.id == 'math') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MarketShoppingGamePage()),
      );
    } else if (ability.id == 'executive_function') {
      Navigator.pushNamed(context, AppRoutes.gameMarketSort);
    } else if (ability.id == 'attention') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GoToMarketTutorialPage()),
      );
    } else if (ability.id == 'working_memory') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CookingPrepGamePage()),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ability.title} 訓練敬請期待！'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 第 [index] 頁出現在畫面上：圓點亮起。快速滑過時中間的頁可能來不及
  /// 偵測到，所以前面的頁一起亮，旅程線才會依序連起來。
  void _lightStep(int index) {
    if (!mounted || _stepLit[index]) return;
    setState(() {
      for (var i = 0; i <= index; i++) {
        _stepLit[i] = true;
      }
    });
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
        final palette = DashboardPalette.current();
        final report = _report;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: const TopBar(title: '週報表', showBackButton: true),
          body: report == null
              ? DashboardLoadState(
                  isLoading: _isLoading,
                  onRetry: _load,
                  palette: palette,
                )
              : _buildReport(report, palette),
        );
      },
    );
  }

  Widget _buildReport(WeeklyReport report, DashboardPalette palette) {
    // 每一頁＝旁白＋原本的區塊，區塊的順序和內容不變。
    // 旁白是固定的銜接句，不跟著資料變動。
    final steps = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(report, palette),
          const SizedBox(height: 20),
          _narration(0, '嗨，這一週我們一起回頭看看吧', palette),
          const SizedBox(height: 16),
          RevealOnScroll(
            builder: (context, revealed) =>
                WeeklySummarySection(summary: report.summary, palette: palette),
          ),
        ],
      ),
      _withNarration(
        1,
        '先看看你這週來了幾天',
        palette,
        RevealOnScroll(
          builder: (context, revealed) => WeeklyNumbersSection(
            report: report,
            revealed: revealed,
            palette: palette,
          ),
        ),
      ),
      _withNarration(
        2,
        '一天一格，來過的那天會亮起來',
        palette,
        RevealOnScroll(
          builder: (context, revealed) => WeeklyCheckInSection(
            playedDays: report.playedDays,
            revealed: revealed,
            palette: palette,
          ),
        ),
      ),
      _withNarration(
        3,
        '再看看跟上週比，有什麼不一樣',
        palette,
        RevealOnScroll(
          builder: (context, revealed) => WeeklyComparisonSection(
            report: report,
            revealed: revealed,
            palette: palette,
            onAbilityTap: _onAbilityTap,
          ),
        ),
      ),
      _withNarration(
        4,
        '還有你記下的這些日子',
        palette,
        RevealOnScroll(
          builder: (context, revealed) => WeeklyDiarySection(
            diaries: report.diaries,
            talkSeconds: report.diaryTalkSeconds,
            palette: palette,
            onDiaryTap: (diary) => DiaryPreviewDialog.show(
              context,
              diary: diary,
              palette: palette,
            ),
          ),
        ),
      ),
      _withNarration(
        5,
        '最後，下週我們一起試試這個',
        palette,
        RevealOnScroll(
          builder: (context, revealed) =>
              WeeklyGoalSection(goal: report.nextWeekGoal, palette: palette),
        ),
      ),
      RevealOnScroll(
        onRevealed: () => _lightStep(6),
        builder: (context, revealed) => _buildEnding(report, palette),
      ),
    ];
    assert(steps.length == _stepLit.length);

    // 頁數不多，用 Column 一次建好，不用 ListView：ListView 會把
    // 捲出畫面太遠的區塊回收掉，捲回來時進場動畫會重播
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, step) in steps.indexed)
                StoryStep(
                  // 收尾頁維持原本的高度並置中，其他頁內容靠上
                  minHeight: index == steps.length - 1
                      ? height * kStoryEndingMinHeightFactor
                      : height * kStoryMinHeightFactor,
                  centered: index == steps.length - 1,
                  lit: _stepLit[index],
                  nextLit: index + 1 < _stepLit.length && _stepLit[index + 1],
                  isFirst: index == 0,
                  isLast: index == steps.length - 1,
                  bottomGap: index == steps.length - 1 ? 0 : kStoryStepGap,
                  palette: palette,
                  child: step,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 機器人旁白：捲到才淡入（跟區塊一樣只播一次），同時亮起這一頁的圓點
  Widget _narration(int step, String text, DashboardPalette palette) {
    return RevealOnScroll(
      onRevealed: () => _lightStep(step),
      builder: (context, revealed) =>
          StoryNarration(text: text, palette: palette),
    );
  }

  Widget _withNarration(
    int step,
    String text,
    DashboardPalette palette,
    Widget section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _narration(step, text, palette),
        const SizedBox(height: 16),
        section,
      ],
    );
  }

  Widget _buildHeader(WeeklyReport report, DashboardPalette palette) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    String format(DateTime d) =>
        '${d.month}/${d.day}（${weekdays[d.weekday - 1]}）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '上週回顧',
          style: TextStyle(
            fontSize: AppSettings.scaleFont(28),
            fontWeight: FontWeight.w800,
            color: palette.title,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${format(report.weekStart)} ～ ${format(report.weekEnd)}',
          style: TextStyle(
            fontSize: AppSettings.scaleFont(18),
            fontWeight: FontWeight.w600,
            color: palette.primary,
          ),
        ),
      ],
    );
  }

  /// 收尾：機器人說再見＋「回上一頁」，最下面是免責聲明
  Widget _buildEnding(WeeklyReport report, DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: palette.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const RobotAvatar(mood: DashboardMood.good, size: 96),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '這週辛苦了，下週見！',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSettings.scaleFont(24),
            fontWeight: FontWeight.bold,
            color: palette.title,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
            label: Text(
              '回上一頁',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildFooter(report, palette),
      ],
    );
  }

  Widget _buildFooter(WeeklyReport report, DashboardPalette palette) {
    return Text(
      report.disclaimer,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: AppSettings.scaleFont(15),
        color: palette.body,
      ),
    );
  }
}
