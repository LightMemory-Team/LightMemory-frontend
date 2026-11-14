import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../../auth/pages/auth_gate.dart';
import '../../home/services/game_launcher.dart';
import '../../home/widgets/top_bar.dart';
import '../../rewards/widgets/achievement_unlock.dart';
import '../models/ability_catalog.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../widgets/ability_radar_chart.dart';
import '../widgets/dashboard_alert_card.dart';
import '../widgets/dashboard_load_state.dart';
import '../widgets/dashboard_palette.dart';
import '../widgets/dashboard_status_card.dart';
import 'ability_menu_page.dart';
import 'weekly_report_page.dart';

/// 健康儀表板首頁（底部導覽「儀表板」）：狀態卡片、認知能力分布圖、
/// 「查看週報表」「六大能力說明」兩個按鈕。
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _service = DashboardService();
  DashboardOverview? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _service.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
      // 點數與成就：開儀表板解鎖成就時直接跳成就視窗（沒有結算頁）
      showNewAchievements(context, overview.rewards.newAchievements);
    } on NotLoggedInException {
      // 沒登入或 token 無效：清掉 token，交給 AuthGate 走登入流程
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('儀表板資料讀取失敗：$e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
        final overview = _overview;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: const TopBar(title: '健康儀表板'),
          body: overview == null
              ? DashboardLoadState(
                  isLoading: _isLoading,
                  onRetry: _load,
                  palette: palette,
                )
              : RefreshIndicator(
                  color: palette.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      DashboardStatusCard(
                        status: overview.status,
                        palette: palette,
                      ),
                      const SizedBox(height: 20),
                      // 小提醒：近期某場表現比平常低很多（後端判斷，沒有就不顯示）
                      if (overview.alerts.isNotEmpty) ...[
                        DashboardAlertCard(
                          alerts: overview.alerts,
                          palette: palette,
                          onPlay: _playAlertGame,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _RadarCard(overview: overview, palette: palette),
                      const SizedBox(height: 24),
                      _buildPrimaryButton(palette),
                      const SizedBox(height: 14),
                      _buildSecondaryButton(palette),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// 小提醒的「去玩一次」：開遊戲，回來後重新整理（新分數可能讓提醒消失）
  Future<void> _playAlertGame(String gameId) async {
    await openGame(context, gameId);
    if (mounted) await _load();
  }

  Widget _buildPrimaryButton(DashboardPalette palette) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.event_note_rounded, size: 26),
        label: Text(
          '查看週報表',
          style: TextStyle(
            fontSize: AppSettings.scaleFont(20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(DashboardPalette palette) {
    return SizedBox(
      height: 60,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbilityMenuPage()),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.card,
          foregroundColor: palette.primary,
          side: BorderSide(
            color: palette.isHighContrast ? palette.title : palette.primary,
            width: 2,
          ),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.grid_view_rounded, size: 24),
        label: Text(
          '六大能力說明',
          style: TextStyle(
            fontSize: AppSettings.scaleFont(20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 「認知能力分布圖」卡片：標題、圖例、雷達圖
class _RadarCard extends StatelessWidget {
  final DashboardOverview overview;
  final DashboardPalette palette;

  const _RadarCard({required this.overview, required this.palette});

  /// 名稱下方的分數，未解鎖或最近沒玩是 null
  String? _scoreLabelFor(String id) {
    final d = overview.dimensions[id];
    if (d == null || !d.unlocked || d.score == null) return null;
    return d.score!.round().toString();
  }

  /// 名稱下方的小字：未解鎖寫還差幾次，已解鎖但最近沒玩寫「最近還沒玩」
  String? _noteFor(String id) {
    final d = overview.dimensions[id];
    // 語言是聲影日記，用篇數算
    final isDiary = id == 'language';
    if (d == null || !d.unlocked) {
      final remaining = d?.sessionsToUnlock ?? overview.requiredSessions;
      return isDiary ? '再寫 $remaining 篇' : '再玩 $remaining 次';
    }
    if (d.score == null) return isDiary ? '最近還沒寫' : '最近還沒玩';
    return null;
  }

  /// 未解鎖或最近沒玩的能力灰色顯示
  bool _isMuted(String id) {
    final d = overview.dimensions[id];
    return d == null || !d.unlocked || d.score == null;
  }

  /// 還在參考期的能力名稱，依雷達圖順序
  List<String> _referencePeriodTitles() => [
    for (final id in kRadarAbilityOrder)
      if (overview.dimensions[id]?.isReferencePeriod ?? false)
        abilityById(id).title,
  ];

  @override
  Widget build(BuildContext context) {
    final referenceTitles = _referencePeriodTitles();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: palette.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '認知能力分布圖',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(22),
              fontWeight: FontWeight.bold,
              color: palette.title,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _LegendItem(
                label: '長者數值',
                textColor: palette.body,
                marker: Container(width: 22, height: 3, color: palette.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AbilityRadarChart(
            labels: kRadarAbilityOrder
                .map((id) => abilityById(id).title)
                .toList(),
            scoreLabels: kRadarAbilityOrder.map(_scoreLabelFor).toList(),
            notes: kRadarAbilityOrder.map(_noteFor).toList(),
            muted: kRadarAbilityOrder.map(_isMuted).toList(),
            // score 是 1～100，直接當半徑；未解鎖或最近沒玩是 null，畫在中心點
            values: kRadarAbilityOrder
                .map((id) => overview.dimensions[id]?.score)
                .toList(),
            userColor: palette.primary,
            gridColor: palette.grid,
            labelColor: palette.title,
            labelFontSize: AppSettings.scaleFont(17),
          ),
          // 參考期：基準還偏向其他使用者，分數先參考就好
          if (referenceTitles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '＊${referenceTitles.join('、')}：前幾次會參考其他使用者的表現',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(15),
                  color: palette.body,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Widget marker;
  final Color textColor;

  const _LegendItem({
    required this.label,
    required this.marker,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSettings.scaleFont(16),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
