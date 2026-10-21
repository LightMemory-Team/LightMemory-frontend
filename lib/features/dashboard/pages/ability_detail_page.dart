import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../home/widgets/top_bar.dart';
import '../models/ability_catalog.dart';
import '../widgets/dashboard_palette.dart';

/// 單項能力的說明頁：標題 → 遊戲畫面 → 說明文字，左右箭頭（或手指
/// 左右滑）切換能力，最後一個再往右會回到第一個。
///
/// 兩個入口：
/// - 六大能力說明選單：最下面是「六大能力選單」，回到六宮格
/// - 週報表點某一項能力（[fromWeeklyReport] = true）：最下面改成
///   「回到週報表」，回去時週報表停在原本捲到的位置
/// 兩種都是把這頁關掉（Navigator.pop），只是按鈕文字不同。
class AbilityDetailPage extends StatefulWidget {
  final String initialAbilityId;
  final bool fromWeeklyReport;

  const AbilityDetailPage({
    super.key,
    required this.initialAbilityId,
    this.fromWeeklyReport = false,
  });

  @override
  State<AbilityDetailPage> createState() => _AbilityDetailPageState();
}

class _AbilityDetailPageState extends State<AbilityDetailPage> {
  // PageView 不設上限、用取餘數對應到六項能力，才能無限循環；
  // 起始頁放在很中間，往左往右都滑不到底
  static const int _loopOffset = 600;

  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = kAbilities.indexWhere(
      (a) => a.id == widget.initialAbilityId,
    );
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(
      initialPage: _loopOffset * kAbilities.length + _currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int delta) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 1)
        : const Duration(milliseconds: 350);
    if (delta > 0) {
      _pageController.nextPage(duration: duration, curve: Curves.easeOutCubic);
    } else {
      _pageController.previousPage(
        duration: duration,
        curve: Curves.easeOutCubic,
      );
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

        return Scaffold(
          backgroundColor: palette.background,
          appBar: const TopBar(title: '六大能力說明', showBackButton: true),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _ArrowButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: '上一項',
                          palette: palette,
                          onTap: () => _goTo(-1),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (page) => setState(
                              () => _currentIndex = page % kAbilities.length,
                            ),
                            itemBuilder: (context, page) => _AbilityPage(
                              ability: kAbilities[page % kAbilities.length],
                              palette: palette,
                            ),
                          ),
                        ),
                        _ArrowButton(
                          icon: Icons.chevron_right_rounded,
                          tooltip: '下一項',
                          palette: palette,
                          onTap: () => _goTo(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPageDots(palette),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBottomButton(palette),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageDots(DashboardPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kAbilities.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? palette.primary : palette.soft,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton(DashboardPalette palette) {
    final label = widget.fromWeeklyReport ? '回到週報表' : '六大能力選單';
    final icon = widget.fromWeeklyReport
        ? Icons.arrow_back_rounded
        : Icons.grid_view_rounded;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: TextStyle(
            fontSize: AppSettings.scaleFont(20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 左右切換的大箭頭：圓形、有底色和外框，點擊範圍 52×52
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final DashboardPalette palette;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.card,
        shape: CircleBorder(
          side: BorderSide(
            color: palette.isHighContrast ? palette.title : palette.primary,
            width: 2,
          ),
        ),
        elevation: palette.isDark ? 0 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Icon(icon, size: 40, color: palette.primary),
          ),
        ),
      ),
    );
  }
}

/// 一項能力的內容：標題、遊戲畫面、說明文字
class _AbilityPage extends StatelessWidget {
  final CognitiveAbility ability;
  final DashboardPalette palette;

  const _AbilityPage({required this.ability, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ability.icon, size: 32, color: palette.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ability.title,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(28),
                    fontWeight: FontWeight.bold,
                    color: palette.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(flex: 5, child: _buildScreenshot()),
          const SizedBox(height: 16),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Text(
                ability.description,
                // 置中時最後一行常常只剩一兩個字，靠左比較好讀
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  height: 1.5,
                  color: palette.title,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshot() {
    final path = ability.screenshotPath;
    final placeholder = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(20),
        border: palette.cardBorder,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 48, color: palette.onSoft),
          const SizedBox(height: 8),
          Text(
            '${ability.screenshotLabel}\n（圖片待補）',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              color: palette.onSoft,
            ),
          ),
        ],
      ),
    );
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
