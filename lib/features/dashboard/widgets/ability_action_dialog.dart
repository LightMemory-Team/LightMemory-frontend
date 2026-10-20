import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/ability_catalog.dart';
import 'dashboard_palette.dart';

/// 週報表點某一項能力時的選擇
enum AbilityAction { play, explain }

/// 週報表「本週 vs 上週」點單項能力時開的彈窗：
/// 「前往遊玩」或「查看說明」，右上角可以關掉，點外面也會關。
/// 關掉時回傳 null。
class AbilityActionDialog extends StatelessWidget {
  final CognitiveAbility ability;
  final DashboardPalette palette;

  const AbilityActionDialog({
    super.key,
    required this.ability,
    required this.palette,
  });

  static Future<AbilityAction?> show(
    BuildContext context, {
    required CognitiveAbility ability,
    required DashboardPalette palette,
  }) {
    return showDialog<AbilityAction>(
      context: context,
      builder: (_) => AbilityActionDialog(ability: ability, palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: palette.isHighContrast
            ? BorderSide(color: palette.title, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: palette.soft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ability.icon, size: 40, color: palette.onSoft),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ability.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(24),
                    fontWeight: FontWeight.bold,
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '想做什麼呢？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    color: palette.body,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, AbilityAction.play),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(
                      // 語言是聲影日記，不是遊戲
                      ability.id == 'language' ? '去寫日記' : '前往遊玩',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, AbilityAction.explain),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.primary,
                      side: BorderSide(color: palette.primary, width: 2),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 26),
                    label: Text(
                      '查看說明',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              iconSize: 28,
              constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
              tooltip: '關閉',
              icon: Icon(Icons.close_rounded, color: palette.body),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
