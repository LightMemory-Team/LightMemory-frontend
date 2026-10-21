import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../../auth/pages/auth_gate.dart';
import '../../home/widgets/top_bar.dart';
import '../models/ability_catalog.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';
import '../widgets/ability_radar_chart.dart';
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
                      if (overview.isUnlocked)
                        _RadarCard(overview: overview, palette: palette)
                      else
                        _UnlockProgressCard(
                          overview: overview,
                          palette: palette,
                        ),
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

  @override
  Widget build(BuildContext context) {
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
            notes: kRadarAbilityOrder
                .map((id) => overview.zScores[id] == null ? '近期未遊玩' : null)
                .toList(),
            // z 分數 -2～+2 換成雷達圖的 0～100：-2 在中心、0（跟平常一樣）
            // 在中間那圈、+2 在最外圈
            values: kRadarAbilityOrder.map((id) {
              final z = overview.zScores[id];
              return z == null ? null : (z.clamp(-2.0, 2.0) + 2) * 25;
            }).toList(),
            userColor: palette.primary,
            gridColor: palette.grid,
            labelColor: palette.title,
            labelFontSize: AppSettings.scaleFont(17),
          ),
        ],
      ),
    );
  }
}

/// 未解鎖：每款遊戲還差幾場，鼓勵長者玩滿
class _UnlockProgressCard extends StatelessWidget {
  final DashboardOverview overview;
  final DashboardPalette palette;

  const _UnlockProgressCard({required this.overview, required this.palette});

  @override
  Widget build(BuildContext context) {
    final required = overview.requiredSessions;

    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 8),
          Text(
            '每個遊戲玩滿 $required 場，就能看到你的分布圖囉！',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(18),
              height: 1.4,
              color: palette.body,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in overview.progress!) ...[
            const SizedBox(height: 12),
            _buildRow(item, required),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(DashboardUnlockProgress item, int required) {
    final done = item.sessionCount >= required;
    final remaining = required - item.sessionCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(19),
                  fontWeight: FontWeight.bold,
                  color: palette.title,
                ),
              ),
            ),
            if (done) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 24,
                color: palette.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              done ? '完成了' : '還差 $remaining 場',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(17),
                fontWeight: FontWeight.w600,
                color: done ? palette.primary : palette.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: LinearProgressIndicator(
            value: (item.sessionCount / required).clamp(0.0, 1.0),
            minHeight: 14,
            color: palette.primary,
            backgroundColor: palette.track,
          ),
        ),
      ],
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
