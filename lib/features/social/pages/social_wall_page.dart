import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../widgets/post_card.dart';
import '../../auth/pages/auth_gate.dart';
import '../../home/widgets/top_bar.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/network/error_message.dart';
import '../../../core/services/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 動態牆列表頁
///
/// 10/21 會議決定：帳戶隔離（只看得到自己分享的貼文）、拿掉按讚，保留留言與刪除。
/// 放在底部導覽列第 2 個分頁「動態牆」（原「資訊站」位置）。
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

  /// 沒有 token，或 token 過期（後端回 401）時為 true，顯示「前往登入」
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // ============================================================
  // 讀取貼文（S-2，只拿自己的）
  // ============================================================

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = _posts.isEmpty;
      _errorMessage = null;
      _needsLogin = false;
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

      final bool needsLogin =
          e is NotLoggedInException ||
          (e is ApiException && e.statusCode == 401);

      setState(() {
        _isLoading = false;
        _needsLogin = needsLogin;
        // 錯誤訊息統一用 friendlyErrorMessage，跟全 App 一致
        _errorMessage = needsLogin
            ? '登入狀態已失效'
            : friendlyErrorMessage(e, fallback: '目前無法載入動態牆');
      });
    }
  }

  // ============================================================
  // 前往登入：跟設定頁的登出一樣，清掉 token 後交給 AuthGate
  // ============================================================

  Future<void> _goToLogin() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  // ============================================================
  // 留言數更新、刪除貼文後移除
  // ============================================================

  void _updateCommentCount(int postId, int count) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    setState(() {
      _posts[index] = _posts[index].copyWith(commentCount: count);
    });
  }

  /// 貼文刪除成功後，從列表移除
  void _removePost(int postId) {
    setState(() {
      _posts.removeWhere((p) => p.postId == postId);
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

        // 背景用米白色（參考比賽版），讓白色卡片跟背景區分得出來
        // 直接指定顏色，不依賴外層主題，避免預覽時變成預設的紫粉色
        final pageBg = isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF5F4EE);
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
                    '你分享的日記都在這裡，點開可以看看收到的留言',
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

    // 沒登入或登入過期：引導重新登入（按「重新載入」也不會好）
    if (_needsLogin) {
      return [
        _buildMessage(
          icon: Icons.lock_outline,
          title: _errorMessage ?? '登入狀態已失效',
          subtitle: '請重新登入後再查看動態牆',
          subColor: subColor,
          accentGreen: accentGreen,
          buttonText: '前往登入',
          onButtonPressed: _goToLogin,
        ),
      ];
    }

    // 其他載入失敗（例如網路斷線）
    if (_errorMessage != null) {
      return [
        _buildMessage(
          icon: Icons.cloud_off_outlined,
          title: _errorMessage!,
          subtitle: '請確認網路後再試一次',
          subColor: subColor,
          accentGreen: accentGreen,
          buttonText: '重新載入',
          onButtonPressed: _loadPosts,
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
            onCommentCountChanged: (count) =>
                _updateCommentCount(post.postId, count),
            onDeleted: () => _removePost(post.postId),
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
    String? buttonText,
    VoidCallback? onButtonPressed,
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
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}