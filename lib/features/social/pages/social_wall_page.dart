import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../widgets/post_card.dart';
import '../../home/widgets/top_bar.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 動態牆列表頁（計劃書版：所有使用者的貼文，可以按讚、留言）
///
/// 放在底部導覽列第 2 個分頁（原「資訊站」，名稱待定）。
class SocialWallPage extends StatefulWidget {
  const SocialWallPage({super.key});

  @override
  State<SocialWallPage> createState() => _SocialWallPageState();
}

class _SocialWallPageState extends State<SocialWallPage> {
  final SocialService _service = SocialService();

  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // ============================================================
  // 讀取貼文（S-2）
  // ============================================================

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = _posts.isEmpty;
      _errorMessage = null;
    });

    try {
      final posts = await _service.getPosts();

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取動態牆失敗: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '目前無法載入動態牆';
      });
    }
  }

  // ============================================================
  // 按讚／取消按讚（S-8）
  // ============================================================

  Future<void> _toggleLike(PostModel post) async {
    try {
      final updated = await _service.toggleLike(
        post.postId,
        like: !post.isLiked,
      );

      if (!mounted) return;

      _replacePost(updated);
    } catch (e) {
      debugPrint('❌ 按讚失敗: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('按讚失敗，請再試一次')),
      );
    }
  }

  void _updateCommentCount(int postId, int count) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    setState(() {
      _posts[index] = _posts[index].copyWith(commentCount: count);
    });
  }

  void _replacePost(PostModel updated) {
    final index = _posts.indexWhere((p) => p.postId == updated.postId);
    if (index == -1) return;

    setState(() {
      _posts[index] = updated;
    });
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

        final pageBg = isDark
            ? const Color(0xFF121212)
            : Theme.of(context).scaffoldBackgroundColor;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : AppTheme.colorScheme.onSurface);
        final subColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast
                  ? Colors.black
                  : AppTheme.colorScheme.onSurfaceVariant);
        final accentGreen = isDark
            ? const Color(0xFF4CAF50)
            : AppTheme.primaryColor;

        return Scaffold(
          backgroundColor: pageBg,
          // 共用頂部列：左邊設定、中間標題、右邊通知，跟其他頁面一致
          appBar: const TopBar(),
          body: SafeArea(
            child: RefreshIndicator(
              color: accentGreen,
              onRefresh: _loadPosts,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  // ==============================================
                  // 標題（名稱待定）
                  // ==============================================
                  Text(
                    '動態牆',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontTitle),
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '點擊貼文，看看大家的留言，也留下你的鼓勵',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._buildContent(subColor, accentGreen),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContent(Color subColor, Color accentGreen) {
    // 載入中
    if (_isLoading) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator(color: accentGreen)),
        ),
      ];
    }

    // 載入失敗
    if (_errorMessage != null) {
      return [
        _buildMessage(
          icon: Icons.cloud_off_outlined,
          title: _errorMessage!,
          subtitle: '請確認網路後再試一次',
          subColor: subColor,
          accentGreen: accentGreen,
          showRetry: true,
        ),
      ];
    }

    // 沒有貼文
    if (_posts.isEmpty) {
      return [
        _buildMessage(
          icon: Icons.forum_outlined,
          title: '目前還沒有貼文',
          subtitle: '到聲影日記寫一篇日記，分享到動態牆吧！',
          subColor: subColor,
          accentGreen: accentGreen,
        ),
      ];
    }

    // 貼文列表
    return _posts
        .map(
          (post) => PostCard(
            key: ValueKey(post.postId),
            post: post,
            onLikeTap: () => _toggleLike(post),
            onCommentCountChanged: (count) =>
                _updateCommentCount(post.postId, count),
          ),
        )
        .toList();
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color subColor,
    required Color accentGreen,
    bool showRetry = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 56, color: subColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontBody),
              fontWeight: FontWeight.bold,
              color: subColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
              color: subColor,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('重新載入'),
            ),
          ],
        ],
      ),
    );
  }
}