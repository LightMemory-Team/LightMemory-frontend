import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../game/models/cognitive_domain_model.dart';
import '../../game/widgets/domain_card.dart';
import '../../home/widgets/top_bar.dart';
import '../models/ability_catalog.dart';
import '../widgets/dashboard_palette.dart';
import 'ability_detail_page.dart';

/// 六大能力說明的選單：六個綠色按鈕，排版跟遊戲首頁的六宮格一樣
/// （同一個 DomainCard，2 欄 × 3 列填滿剩下的高度，不捲動）。
class AbilityMenuPage extends StatelessWidget {
  const AbilityMenuPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '想了解哪一項能力？點一下看看',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(18),
                      fontWeight: FontWeight.w600,
                      color: palette.body,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildGrid(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const rowCount = 3;
        const spacing = 16.0;

        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final itemHeight =
            (constraints.maxHeight - spacing * (rowCount - 1)) / rowCount;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kAbilities.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemBuilder: (context, index) {
            final ability = kAbilities[index];
            return DomainCard(
              domain: CognitiveDomain(
                id: ability.id,
                title: ability.title,
                icon: ability.icon,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AbilityDetailPage(initialAbilityId: ability.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
