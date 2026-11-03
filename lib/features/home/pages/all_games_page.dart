import 'package:flutter/material.dart';

import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/home_models.dart';
import '../services/game_launcher.dart';
import '../services/home_service.dart';
import '../widgets/game_card.dart';
import '../widgets/top_bar.dart';

/// 全部遊戲頁：首頁「大腦訓練遊戲」點「查看全部」進來
///
/// - 列出 5 款遊戲，兩欄排列，卡片跟首頁同一個元件
/// - 本週還沒玩的排前面（跟首頁一致）
/// - 點任一款直接進遊戲；玩完回來重新整理「本週還沒玩」標籤
class AllGamesPage extends StatefulWidget {
  const AllGamesPage({super.key});

  @override
  State<AllGamesPage> createState() => _AllGamesPageState();
}

class _AllGamesPageState extends State<AllGamesPage> {
  final HomeService _service = HomeService();

  List<HomeGame> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = _games.isEmpty;
      _errorMessage = null;
    });

    try {
      final games = await _service.getGames();
      if (!mounted) return;

      // 本週還沒玩的排前面，其他維持後端給的順序
      final sorted = [
        ...games.where((g) => !g.playedThisWeek),
        ...games.where((g) => g.playedThisWeek),
      ];

      setState(() {
        _games = sorted;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取遊戲列表失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入遊戲');
      });
    }
  }

  Future<void> _onGameTap(HomeGame game) async {
    await openGame(context, game.id);
    // 玩完回來，重新整理「本週還沒玩」標籤
    if (mounted) _loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) {
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final subColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF595959);
        final green = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(title: '大腦訓練遊戲', showBackButton: true),
          body: SafeArea(child: _buildBody(subColor, green)),
        );
      },
    );
  }

  Widget _buildBody(Color subColor, Color green) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: green));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: subColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  color: subColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadGames,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 130, // 跟首頁遊戲卡片同高
      ),
      itemBuilder: (context, index) {
        final game = _games[index];
        return GameCard(game: game, onTap: () => _onGameTap(game));
      },
    );
  }
}