import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/rewards_models.dart';
import '../services/rewards_service.dart';
import '../widgets/achievement_card.dart';

/// 成就牆（依〈點數與成就系統規格〉前端分頁＋11/9 會議）
///
/// - 上方：已解鎖數／總數、目前點數
/// - 類別按鈕：探索類、訓練類、里程碑類（三個一排，點了切換）
/// - 成就列表：已解鎖在前（最新解鎖的最上面），未解鎖灰階並顯示進度
///
/// 入口：首頁點數點擊、會員頁「我的成就與點數」
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final RewardsService _service = RewardsService();

  RewardsSummary? _summary;
  List<AchievementCategory> _categories = [];

  /// 目前選到第幾個類別
  int _selectedIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// 總覽和成就清單同時讀取
  Future<void> _loadAll() async {
    setState(() {
      _isLoading = _categories.isEmpty;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getSummary(),
        _service.getAchievements(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as RewardsSummary;
        _categories = results[1] as List<AchievementCategory>;
        if (_selectedIndex >= _categories.length) _selectedIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取成就牆失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入成就');
      });
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
        final colors = RewardsColors.of(
          isDark: AppSettings.isDarkMode.value,
          isHighContrast: AppSettings.isHighContrast.value,
        );

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            // 左上角用文字「返回」（跟註冊頁、忘記密碼、商城一樣）
            leadingWidth: 88,
            leading: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: colors.green),
              child: Text(
                '返回',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech, color: RewardsColors.gold),
                const SizedBox(width: 6),
                Text(
                  '我的成就',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(20),
                    fontWeight: FontWeight.bold,
                    color: colors.green,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(child: _buildBody(colors)),
        );
      },
    );
  }

  Widget _buildBody(RewardsColors colors) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.green));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: colors.subtitle),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  color: colors.subtitle,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
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

    final AchievementCategory? selected =
        _categories.isEmpty ? null : _categories[_selectedIndex];

    return RefreshIndicator(
      color: colors.green,
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSummaryCard(colors),
          const SizedBox(height: 16),

          // 類別按鈕：三個一排
          if (_categories.isNotEmpty)
            Row(
              children: [
                for (int i = 0; i < _categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _buildCategoryButton(i, colors)),
                ],
              ],
            ),
          const SizedBox(height: 16),

          // 成就列表
          if (selected == null || selected.achievements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                '目前還沒有成就',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(17),
                  color: colors.subtitle,
                ),
              ),
            )
          else
            ...selected.sortedAchievements.map(
              (a) => AchievementCard(key: ValueKey(a.code), achievement: a),
            ),
        ],
      ),
    );
  }

  /// 上方總覽：已解鎖數／總數、目前點數
  Widget _buildSummaryCard(RewardsColors colors) {
    final summary = _summary;

    // 後端沒給總數時，用清單自己算
    final int unlocked = summary?.achievementsUnlocked ??
        _categories.fold(0, (sum, c) => sum + c.unlockedCount);
    final int total = (summary != null && summary.achievementsTotal > 0)
        ? summary.achievementsTotal
        : _categories.fold(0, (sum, c) => sum + c.achievements.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF25382E) : const Color(0xFF2E6342),
        borderRadius: BorderRadius.circular(22),
        border: colors.isHighContrast ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, size: 30, color: RewardsColors.gold),
              const SizedBox(width: 8),
              Text(
                '已解鎖 $unlocked / $total 個成就',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 24, color: Color(0xFFF5C542)),
                const SizedBox(width: 8),
                Text(
                  '目前點數 ${summary.totalPoints} 點',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(17),
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 類別按鈕：選到的綠底白字，沒選到的白底綠字；下面顯示解鎖數
  Widget _buildCategoryButton(int index, RewardsColors colors) {
    final category = _categories[index];
    final bool isSelected = index == _selectedIndex;

    final Color bg = isSelected ? colors.green : colors.cardBg;
    final Color fg = isSelected ? Colors.white : colors.green;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.isHighContrast ? colors.title : colors.green,
              width: colors.isHighContrast ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  category.label,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${category.unlockedCount} / ${category.achievements.length}',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(14),
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}