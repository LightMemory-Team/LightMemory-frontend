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
///
/// 11/03 新增搜尋：關鍵字（標題、內容、標籤）＋日期（只列出有貼文的日期）。
/// 目前是前端搜尋，只會搜已經載入的貼文（S-2 一次 20 則）；
/// 之後後端支援搜尋參數時，再改成把關鍵字、日期傳給後端。
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

  // ---------- 搜尋 ----------
  final TextEditingController _searchController = TextEditingController();

  /// 選到的日期（格式跟貼文的 date 一樣：2026-10-20），null 代表全部日期
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    // 打字時馬上重新篩選
    _searchController.addListener(() => setState(() {}));
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  // 搜尋：關鍵字＋日期
  // ============================================================

  String get _keyword => _searchController.text.trim().toLowerCase();

  /// 有沒有在搜尋（有打關鍵字，或有選日期）
  bool get _isSearching => _keyword.isNotEmpty || _selectedDate != null;

  /// 下拉選單的日期：只列出有貼文的日期，新的在前面
  List<String> get _availableDates {
    final dates = _posts.map((p) => p.date).where((d) => d.isNotEmpty).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// 篩選後的貼文：關鍵字搜標題、內容、標籤；日期要完全一樣
  List<PostModel> get _filteredPosts {
    final keyword = _keyword;
    return _posts.where((post) {
      if (_selectedDate != null && post.date != _selectedDate) return false;
      if (keyword.isEmpty) return true;
      final text = [
        post.title,
        post.postText,
        ...post.hashtags,
      ].join(' ').toLowerCase();
      return text.contains(keyword);
    }).toList();
  }

  void _clearSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.clear();
      _selectedDate = null;
    });
  }

  /// 2026-10-20 → 2026年10月20日
  String _formatDate(String date) {
    final DateTime? parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.year}年${parsed.month}月${parsed.day}日';
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

        final colors = _SearchColors(
          isDark: isDark,
          isHighContrast: isHighContrast,
          titleColor: titleColor,
          subColor: subColor,
          accentGreen: accentGreen,
        );

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

                  ..._buildContent(colors),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContent(_SearchColors colors) {
    final subColor = colors.subColor;
    final accentGreen = colors.accentGreen;

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

    // 沒有貼文（沒東西好搜，不顯示搜尋框）
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

    final filtered = _filteredPosts;

    return [
      // 搜尋框＋日期
      _buildSearchField(colors),
      const SizedBox(height: 10),
      _buildDateDropdown(colors),
      const SizedBox(height: 12),

      // 搜尋中：顯示找到幾篇
      if (_isSearching && filtered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '找到 ${filtered.length} 篇日記',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
              fontWeight: FontWeight.bold,
              color: accentGreen,
            ),
          ),
        ),

      // 找不到
      if (filtered.isEmpty)
        _buildMessage(
          icon: Icons.search_off,
          title: '找不到符合的日記',
          subtitle: '換個關鍵字或日期試試看',
          subColor: subColor,
          accentGreen: accentGreen,
          buttonText: '清除搜尋',
          onButtonPressed: _clearSearch,
        )
      else
        // 貼文列表
        ...filtered.map(
          (post) => PostCard(
            key: ValueKey(post.postId),
            post: post,
            onCommentCountChanged: (count) =>
                _updateCommentCount(post.postId, count),
            onDeleted: () => _removePost(post.postId),
          ),
        ),
    ];
  }

  /// 🔍 搜尋框：搜標題、內容、標籤；右邊 ✕ 一鍵清除
  Widget _buildSearchField(_SearchColors colors) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontSize: AppSettings.scaleFont(AppTheme.fontBody),
        color: colors.isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: '搜尋標題、內容或標籤',
        hintStyle: TextStyle(
          color: colors.isDark ? const Color(0xFF999999) : Colors.black38,
        ),
        prefixIcon: Icon(Icons.search, color: colors.subColor),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: '清除',
                icon: Icon(Icons.close, color: colors.subColor),
                onPressed: () => _searchController.clear(),
              ),
        filled: true,
        fillColor: colors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          borderSide: BorderSide(color: colors.border, width: colors.isHighContrast ? 2 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          borderSide: BorderSide(color: colors.accentGreen, width: 2),
        ),
      ),
    );
  }

  /// 📅 日期下拉選單：只列出有貼文的日期
  Widget _buildDateDropdown(_SearchColors colors) {
    final dates = _availableDates;
    // 選到的日期如果已經沒有貼文（例如剛刪掉），就當成全部日期
    final String? value = dates.contains(_selectedDate) ? _selectedDate : null;

    final textStyle = TextStyle(
      fontSize: AppSettings.scaleFont(AppTheme.fontBody),
      color: colors.isDark ? Colors.white : Colors.black87,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: colors.border, width: colors.isHighContrast ? 2 : 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: value,
          dropdownColor: colors.fieldBg,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.subColor),
          menuMaxHeight: 360,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: colors.subColor),
                  const SizedBox(width: 10),
                  Text('全部日期', style: textStyle),
                ],
              ),
            ),
            ...dates.map(
              (date) => DropdownMenuItem<String?>(
                value: date,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 20, color: colors.accentGreen),
                    const SizedBox(width: 10),
                    Text(_formatDate(date), style: textStyle),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (date) => setState(() => _selectedDate = date),
        ),
      ),
    );
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

/// 搜尋區的顏色：跟著深色模式、高對比切換
class _SearchColors {
  final bool isDark;
  final bool isHighContrast;
  final Color titleColor;
  final Color subColor;
  final Color accentGreen;

  const _SearchColors({
    required this.isDark,
    required this.isHighContrast,
    required this.titleColor,
    required this.subColor,
    required this.accentGreen,
  });

  Color get fieldBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get border => isHighContrast
      ? (isDark ? Colors.white : Colors.black)
      : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0));
}