import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../widgets/post_card.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/error_message.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 單篇貼文頁：從通知點進來，顯示對應的動態牆貼文，留言預設展開
class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  /// 從通知的 target_url 取出貼文 ID。後端目前的格式是 /posts/{貼文 id}/（例如 /posts/12/ → 12）；
  /// 也相容 /api/social/posts/12/ 這類較長的路徑。取不到（空字串、格式不認得）回傳 null。
  static int? postIdFromTargetUrl(String targetUrl) {
    final match =
        RegExp(r'posts?/(\d+)').firstMatch(targetUrl) ??
        RegExp(r'(\d+)(?!.*\d)').firstMatch(targetUrl);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final SocialService _service = SocialService();

  PostModel? _post;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _post == null;
      _errorMessage = null;
    });
    try {
      final post = await _service.getPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取貼文失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is ApiException && e.statusCode == 404
            ? '這則貼文已經不存在'
            : friendlyErrorMessage(e, fallback: '目前無法載入貼文');
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
        final isDark = AppSettings.isDarkMode.value;
        final pageBg = isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F4EE);
        final accentGreen = isDark
            ? const Color(0xFF4CAF50)
            : AppTheme.primaryColor;
        final subColor = isDark
            ? const Color(0xFFCCCCCC)
            : AppTheme.colorScheme.onSurfaceVariant;

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: accentGreen),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '動態牆',
              style: TextStyle(
                color: accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
          ),
          body: SafeArea(child: _buildBody(accentGreen, subColor)),
        );
      },
    );
  }

  Widget _buildBody(Color accentGreen, Color subColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentGreen));
    }

    final post = _post;
    if (post == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56, color: subColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '目前無法載入貼文',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                  fontWeight: FontWeight.bold,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '重新載入',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        PostCard(
          key: ValueKey(post.postId),
          post: post,
          initiallyExpanded: true,
          onCommentCountChanged: (count) {
            setState(() => _post = post.copyWith(commentCount: count));
          },
          // 貼文刪除後沒有東西可看，回到上一頁
          onDeleted: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
