import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app_settings.dart';
import '../models/ability_catalog.dart';
import '../models/dashboard_models.dart';
import 'dashboard_palette.dart';
import 'robot_avatar.dart';

// 週報表的各個區塊，由上到下一個區塊只講一件事。
// 每個區塊都收 `revealed`（捲到畫面上了沒），裡面的數字、長條、打卡圓點
// 等 revealed 變 true 才開始動，跟區塊本身的進場同步。

const Duration _kGrowDuration = Duration(milliseconds: 900);

/// 秒數轉成「X 分鐘」「X 小時 Y 分鐘」，對話時長、遊玩時間共用
String formatDuration(int seconds) {
  final minutes = (seconds / 60).round();
  if (seconds == 0) return '0 分鐘';
  if (minutes < 1) return '不到 1 分鐘';
  if (minutes < 60) return '$minutes 分鐘';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours 小時' : '$hours 小時 $rest 分鐘';
}

/// 區塊外框：白底圓角卡片＋（可選）標題
class WeeklySectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final DashboardPalette palette;

  const WeeklySectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: palette.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(22),
                      fontWeight: FontWeight.bold,
                      color: palette.title,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

/// 數字從 0 跳到目標值
class _CountUpText extends StatelessWidget {
  final int value;
  final bool revealed;
  final TextStyle style;

  const _CountUpText({
    required this.value,
    required this.revealed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: revealed ? value.toDouble() : 0),
      duration: _kGrowDuration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

// ── ① 一句話總結 ─────────────────────────────────────────────────

class WeeklySummarySection extends StatelessWidget {
  final String summary;
  final DashboardPalette palette;

  const WeeklySummarySection({
    super.key,
    required this.summary,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return WeeklySectionCard(
      palette: palette,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF3F6E5A),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const RobotAvatar(mood: DashboardMood.good, size: 78),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(21),
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                  color: palette.onSoft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ② 三個大數字 ─────────────────────────────────────────────────

class WeeklyNumbersSection extends StatelessWidget {
  final WeeklyReport report;
  final bool revealed;
  final DashboardPalette palette;

  const WeeklyNumbersSection({
    super.key,
    required this.report,
    required this.revealed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tile(report.daysPlayed, '天', '玩了幾天')),
            const SizedBox(width: 12),
            Expanded(child: _tile(report.sessionsPlayed, '場', '玩了幾場')),
            const SizedBox(width: 12),
            Expanded(child: _tile(report.streakDays, '天', '連續天數')),
          ],
        ),
        const SizedBox(height: 12),
        _PlayTimeCard(
          playTime: report.playTime,
          revealed: revealed,
          palette: palette,
        ),
      ],
    );
  }

  Widget _tile(int value, String unit, String caption) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: palette.cardDecoration(radius: 20),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _CountUpText(
                  value: value,
                  revealed: revealed,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(42),
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              caption,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(16),
                fontWeight: FontWeight.w600,
                color: palette.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 三個大數字下方：本週遊玩時間，每款遊戲一根長條，
/// 長條以這週玩最久的遊戲當滿格
class _PlayTimeCard extends StatelessWidget {
  final WeeklyPlayTime playTime;
  final bool revealed;
  final DashboardPalette palette;

  const _PlayTimeCard({
    required this.playTime,
    required this.revealed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final maxSeconds = playTime.games.fold<int>(
      0,
      (max, g) => g.seconds > max ? g.seconds : max,
    );
    final labelStyle = TextStyle(
      fontSize: AppSettings.scaleFont(17),
      fontWeight: FontWeight.w600,
      color: palette.body,
    );

    return WeeklySectionCard(
      title: '本週遊玩時間',
      trailing: playTime.totalSeconds == 0
          ? null
          : Text(
              '共 ${formatDuration(playTime.totalSeconds)}',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                fontWeight: FontWeight.bold,
                color: palette.primary,
              ),
            ),
      palette: palette,
      child: playTime.totalSeconds == 0
          ? Text(
              '這週還沒開始玩，下週一起動動腦吧！',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                color: palette.body,
              ),
            )
          : Column(
              children: [
                for (final (index, game) in playTime.games.indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        // 最長的遊戲名稱「整理菜籃遊戲」6 個字放得下
                        width: AppSettings.scaleFont(17) * 6.5,
                        child: Text(game.label, style: labelStyle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: game.seconds == 0
                            ? Text('還沒玩', style: labelStyle)
                            : _growBar(game.seconds / maxSeconds),
                      ),
                      if (game.seconds > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatDuration(game.seconds),
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(17),
                            fontWeight: FontWeight.bold,
                            color: palette.title,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  /// 長條從 0 長到 [ratio]，跟「本週 vs 上週」的長條一樣
  Widget _growBar(double ratio) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: palette.track,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: revealed ? ratio.clamp(0.0, 1.0) : 0),
              duration: _kGrowDuration,
              curve: Curves.easeOutCubic,
              builder: (context, factor, _) => Container(
                width: width * factor,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── ③ 本週打卡 ───────────────────────────────────────────────────

class WeeklyCheckInSection extends StatelessWidget {
  final List<bool> playedDays;
  final bool revealed;
  final DashboardPalette palette;

  const WeeklyCheckInSection({
    super.key,
    required this.playedDays,
    required this.revealed,
    required this.palette,
  });

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  String get _caption {
    final count = playedDays.where((d) => d).length;
    if (count == 0) return '下週來集第一格吧！';
    if (count == 7) return '七格全部集滿了，太厲害了！';
    return '這週集了 $count 格，下週再多集幾格吧！';
  }

  @override
  Widget build(BuildContext context) {
    return WeeklySectionCard(
      title: '本週打卡',
      palette: palette,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final dotSize = ((constraints.maxWidth - 6 * 8) / 7).clamp(
                28.0,
                44.0,
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  return Column(
                    children: [
                      _dot(i, dotSize),
                      const SizedBox(height: 6),
                      Text(
                        _weekdays[i],
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(16),
                          fontWeight: FontWeight.bold,
                          color: palette.body,
                        ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(18),
              fontWeight: FontWeight.w600,
              color: palette.title,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index, double size) {
    final played = playedDays[index];
    final emptyDot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.grid, width: 2.5),
      ),
    );
    if (!played) return emptyDot;

    // 有玩的那天：在空圓框上「蓋章」，一格一格依序彈出來
    return Stack(
      alignment: Alignment.center,
      children: [
        emptyDot,
        Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * 0.6,
              ),
            )
            // 用 target 控制時 Animate 本身的 delay 沒作用，延遲要寫在效果上
            .animate(target: revealed ? 1 : 0)
            .scaleXY(
              delay: (200 + index * 90).ms,
              begin: 0.3,
              end: 1,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(
              delay: (200 + index * 90).ms,
              duration: 200.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}

// ── ④ 本週 vs 上週 ───────────────────────────────────────────────

class WeeklyComparisonSection extends StatelessWidget {
  final WeeklyReport report;
  final bool revealed;
  final DashboardPalette palette;
  final void Function(String abilityId) onAbilityTap;

  const WeeklyComparisonSection({
    super.key,
    required this.report,
    required this.revealed,
    required this.palette,
    required this.onAbilityTap,
  });

  @override
  Widget build(BuildContext context) {
    // 六項能力固定照遊戲首頁的順序，不管後端回傳的順序
    final statsById = {for (final s in report.abilities) s.id: s};

    return WeeklySectionCard(
      title: '本週 vs 上週',
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.isFirstWeek)
            _FirstWeekBanner(palette: palette)
          else
            _Legend(palette: palette),
          const SizedBox(height: 16),
          // 整體：淺綠底，跟下面六項分開
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.soft.withValues(alpha: palette.isDark ? 1 : 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: _ComparisonRow(
              title: '整體表現',
              icon: Icons.insights_rounded,
              stat: report.overall,
              isFirstWeek: report.isFirstWeek,
              revealed: revealed,
              palette: palette,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '六大能力',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(18),
              fontWeight: FontWeight.bold,
              color: palette.body,
            ),
          ),
          const SizedBox(height: 4),
          for (final (index, ability) in kAbilities.indexed) ...[
            if (index > 0) Divider(height: 1, color: palette.track),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onAbilityTap(ability.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _ComparisonRow(
                  title: ability.title,
                  icon: ability.icon,
                  stat: statsById[ability.id],
                  isFirstWeek: report.isFirstWeek,
                  revealed: revealed,
                  palette: palette,
                  showChevron: true,
                  // 語言是聲影日記，不是遊戲
                  notPlayedText: ability.id == 'language'
                      ? '這週還沒寫日記，寫一篇看看'
                      : '還沒玩，玩一場看看',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FirstWeekBanner extends StatelessWidget {
  final DashboardPalette palette;

  const _FirstWeekBanner({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: palette.onSoft, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '這是你的第一週，是一個好的開始！',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                fontWeight: FontWeight.bold,
                color: palette.onSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 圖例：上週（淺色）、本週（深色）、個人最佳（直線）
class _Legend extends StatelessWidget {
  final DashboardPalette palette;

  const _Legend({required this.palette});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: AppSettings.scaleFont(16),
      fontWeight: FontWeight.w600,
      color: palette.body,
    );
    Widget swatch(Color color) => Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(_lastWeekColor(palette)),
            const SizedBox(width: 6),
            Text('上週', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(palette.primary),
            const SizedBox(width: 6),
            Text('本週', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 3, height: 18, color: _bestMarkColor(palette)),
            const SizedBox(width: 6),
            Text('個人最佳', style: style),
          ],
        ),
      ],
    );
  }
}

Color _lastWeekColor(DashboardPalette palette) =>
    palette.isDark ? const Color(0xFF5E8C70) : const Color(0xFFAFCDB8);

Color _bestMarkColor(DashboardPalette palette) =>
    palette.isDark ? const Color(0xFFF2C77B) : const Color(0xFFD08A1E);

/// 一行比較：圖示＋名稱＋狀態詞，下面上週／本週兩根長條
class _ComparisonRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final WeeklyAbilityStat? stat;
  final bool isFirstWeek;
  final bool revealed;
  final DashboardPalette palette;
  final bool showChevron;
  final String notPlayedText;

  const _ComparisonRow({
    required this.title,
    required this.icon,
    required this.stat,
    required this.isFirstWeek,
    required this.revealed,
    required this.palette,
    this.showChevron = false,
    this.notPlayedText = '還沒玩，玩一場看看',
  });

  @override
  Widget build(BuildContext context) {
    final stat = this.stat;
    final played = stat?.playedThisWeek ?? false;
    final trend = stat?.trend;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 26, color: palette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(19),
                  fontWeight: FontWeight.bold,
                  color: palette.title,
                ),
              ),
            ),
            if (played && trend != null && !isFirstWeek)
              _TrendChip(trend: trend, palette: palette),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 28, color: palette.body),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (!played)
          Text(
            notPlayedText,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(17),
              color: palette.body,
            ),
          )
        // 語言（聲影日記）目前沒有分數：有寫日記，但沒有長條可畫
        else if (stat!.thisWeek == null)
          Text(
            '這週有練習，分數還在準備中',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(17),
              color: palette.body,
            ),
          )
        else ...[
          if (!isFirstWeek) ...[
            _BarLine(
              label: '上週',
              value: stat.lastWeek,
              best: stat.personalBest,
              color: _lastWeekColor(palette),
              revealed: revealed,
              palette: palette,
            ),
            const SizedBox(height: 8),
          ],
          _BarLine(
            label: '本週',
            value: stat.thisWeek,
            best: stat.personalBest,
            color: palette.primary,
            revealed: revealed,
            palette: palette,
          ),
        ],
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  final AbilityTrend trend;
  final DashboardPalette palette;

  const _TrendChip({required this.trend, required this.palette});

  @override
  Widget build(BuildContext context) {
    final icon = switch (trend) {
      AbilityTrend.improved => Icons.trending_up_rounded,
      AbilityTrend.steady => Icons.trending_flat_rounded,
      AbilityTrend.practice => Icons.fitness_center_rounded,
    };
    final fg = palette.trendForeground(trend);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: palette.trendBackground(trend),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 4),
          Text(
            abilityTrendLabel(trend),
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// 一根長條：左邊「上週／本週」，中間長條（從 0 長出來）＋個人最佳
/// 標線，右邊分數。上週沒玩時顯示「上週沒玩」。
class _BarLine extends StatelessWidget {
  final String label;
  final double? value;
  final double? best;
  final Color color;
  final bool revealed;
  final DashboardPalette palette;

  const _BarLine({
    required this.label,
    required this.value,
    required this.best,
    required this.color,
    required this.revealed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: AppSettings.scaleFont(16),
      fontWeight: FontWeight.w600,
      color: palette.body,
    );
    final sideWidth = AppSettings.scaleFont(16) * 2.8;
    final value = this.value;
    final best = this.best;

    return Row(
      children: [
        SizedBox(
          width: sideWidth,
          child: Text(label, style: labelStyle),
        ),
        Expanded(
          child: value == null
              ? Text('沒玩', style: labelStyle)
              : SizedBox(
                  height: 22,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: palette.track,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: revealed ? (value / 100).clamp(0.0, 1.0) : 0,
                            ),
                            duration: _kGrowDuration,
                            curve: Curves.easeOutCubic,
                            builder: (context, factor, _) => Container(
                              width: width * factor,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                          if (best != null)
                            Positioned(
                              left: (width * (best / 100).clamp(0.0, 1.0) - 1.5)
                                  .clamp(0.0, width - 3),
                              top: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                opacity: revealed ? 1 : 0,
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: _bestMarkColor(palette),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
        ),
        SizedBox(
          width: sideWidth,
          child: value == null
              ? null
              : Text(
                  '${value.round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: FontWeight.bold,
                    color: palette.title,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── ⑤ 聲影日記 ───────────────────────────────────────────────────

class WeeklyDiarySection extends StatelessWidget {
  final List<WeeklyDiaryItem> diaries;
  final int talkSeconds;
  final DashboardPalette palette;
  final void Function(WeeklyDiaryItem diary) onDiaryTap;

  const WeeklyDiarySection({
    super.key,
    required this.diaries,
    required this.talkSeconds,
    required this.palette,
    required this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoSize = AppSettings.scaleFont(140).clamp(140.0, 180.0);

    return WeeklySectionCard(
      title: '聲影日記',
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diaries.isEmpty)
            Text(
              '這週還沒有寫日記，下週拍張照片聊聊天吧！',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                color: palette.body,
              ),
            )
          else
            SizedBox(
              height: photoSize + AppSettings.scaleFont(16) * 1.6 + 8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: diaries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _photoCard(diaries[index], photoSize),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: palette.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.mic_none_rounded, color: palette.onSoft, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '本週對話時長　${formatDuration(talkSeconds)}',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(18),
                      fontWeight: FontWeight.bold,
                      color: palette.onSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(WeeklyDiaryItem diary, double size) {
    return GestureDetector(
      onTap: () => onDiaryTap(diary),
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                diary.photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: size,
                  height: size,
                  color: palette.soft,
                  child: Icon(
                    Icons.photo_outlined,
                    size: 40,
                    color: palette.onSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${diary.date.month}/${diary.date.day}',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(16),
                fontWeight: FontWeight.bold,
                color: palette.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ⑥ 下週小目標 ─────────────────────────────────────────────────

class WeeklyGoalSection extends StatelessWidget {
  final String goal;
  final DashboardPalette palette;

  const WeeklyGoalSection({
    super.key,
    required this.goal,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return WeeklySectionCard(
      title: '下週小目標',
      palette: palette,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flag_rounded, size: 30, color: palette.onSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              goal,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(20),
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: palette.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
