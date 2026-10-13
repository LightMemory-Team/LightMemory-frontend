import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 動態牆貼文卡片（版面參考比賽版，功能為計劃書版）
///
/// 收合時：小圖在左，作者、標題、兩行內文、日期、按讚在右。
/// 點卡片或右上箭頭展開：顯示文字留言列表與留言輸入框。
class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLikeTap;

  /// 新增留言成功後，通知外層更新留言數
  final ValueChanged<int>? onCommentCountChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    this.onCommentCountChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final SocialService _service = SocialService();
  final TextEditingController _commentController = TextEditingController();

  bool _isExpanded = false;
  bool _hasLoadedComments = false;
  bool _isLoadingComments = false;
  bool _isSubmitting = false;
  String? _commentError;
  List<CommentModel> _comments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ============================================================
  // 展開／收合
  // ============================================================

  Future<void> _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // 第一次展開才讀取留言
    if (_isExpanded && !_hasLoadedComments) {
      await _loadComments();
    }
  }

  // ============================================================
  // 讀取留言（S-13）
  // ============================================================

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentError = null;
    });

    try {
      final comments = await _service.getComments(widget.post.postId);

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _hasLoadedComments = true;
        _isLoadingComments = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取留言失敗: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingComments = false;
        _commentError = '留言載入失敗';
      });
    }
  }

  // ============================================================
  // 送出留言（S-14）
  // ============================================================

  Future<void> _submitComment() async {
    final String text = _commentController.text.trim();

    if (text.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = await _service.submitTextComment(
        widget.post.postId,
        text,
      );

      if (!mounted) return;

      setState(() {
        _comments = [..._comments, comment];
        _isSubmitting = false;
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();

      widget.onCommentCountChanged?.call(widget.post.commentCount + 1);
    } catch (e) {
      debugPrint('❌ 送出留言失敗: $e');

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('留言送出失敗，請再試一次')),
      );
    }
  }

  // ============================================================
  // 日期格式
  // ============================================================

  /// 2026-10-11 → 2026年10月11日
  String _formatDate(String date) {
    final DateTime? parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.year}年${parsed.month}月${parsed.day}日';
  }

  /// 留言時間 → 10/11 10:00
  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $hour:$minute';
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = AppTheme.colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final cardBg = isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
        final titleColor = isDark
            ? const Color(0xFF4CAF50)
            : (isHighContrast ? Colors.black : AppTheme.primaryColor);
        final nameColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : colorScheme.onSurface);
        final bodyColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast ? Colors.black : colorScheme.onSurfaceVariant);
        final chipBg = isDark
            ? const Color(0xFF25382E)
            : colorScheme.secondaryContainer;
        final chipText = isDark
            ? const Color(0xFFB8E6D0)
            : colorScheme.onSecondaryContainer;
        final accentGreen = isDark
            ? const Color(0xFF4CAF50)
            : AppTheme.primaryColor;
        final dividerColor = isDark
            ? const Color(0xFF333333)
            : const Color(0xFFE5E5E5);

        final colors = _CardColors(
          titleColor: titleColor,
          nameColor: nameColor,
          bodyColor: bodyColor,
          chipBg: chipBg,
          chipText: chipText,
          accentGreen: accentGreen,
          isDark: isDark,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: isHighContrast
                ? Border.all(
                    color: isDark ? Colors.white : Colors.black,
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummary(post, colors),
              if (_isExpanded) ...[
                Divider(height: 1, thickness: 1, color: dividerColor),
                _buildCommentSection(colors),
              ],
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 收合時的摘要：小圖在左、文字在右
  // ============================================================

  Widget _buildSummary(PostModel post, _CardColors colors) {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片縮圖
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                height: 88,
                child: post.photoUrl.isEmpty
                    ? _buildPhotoPlaceholder(colors)
                    : Image.network(
                        post.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPhotoPlaceholder(colors),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // 作者、標題、內文、日期、按讚
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(post, colors),

                  const SizedBox(height: 2),

                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontBody + 2),
                      fontWeight: FontWeight.bold,
                      color: colors.titleColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    post.postText,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
                      color: colors.bodyColor,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(post.date),
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(
                              AppTheme.fontCaption,
                            ),
                            color: colors.bodyColor,
                          ),
                        ),
                      ),
                      _buildLikeChip(post, colors),
                      const SizedBox(width: 8),
                      _buildCommentChip(post, colors),
                    ],
                  ),
                ],
              ),
            ),

            // 展開箭頭
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 2),
              child: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 28,
                color: colors.bodyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(_CardColors colors) {
    return Container(
      color: colors.chipBg,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: colors.chipText,
      ),
    );
  }

  Widget _buildAuthorRow(PostModel post, _CardColors colors) {
    // 自己的貼文一律顯示「我」，不顯示本名
    final String name = post.isMine
        ? '我'
        : (post.author.displayName.isEmpty
              ? '使用者'
              : post.author.displayName);

    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
        fontWeight: FontWeight.w600,
        color: post.isMine ? colors.accentGreen : colors.nameColor,
      ),
    );
  }

  Widget _buildLikeChip(PostModel post, _CardColors colors) {
    return GestureDetector(
      onTap: widget.onLikeTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.chipBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: post.isLiked ? Colors.redAccent : colors.chipText,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likeCount}',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
                fontWeight: FontWeight.bold,
                color: colors.chipText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 留言數小標籤，樣式跟按讚一樣；點了會展開留言區
  Widget _buildCommentChip(PostModel post, _CardColors colors) {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.chipBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 19,
              color: colors.chipText,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.commentCount}',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
                fontWeight: FontWeight.bold,
                color: colors.chipText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 展開後：留言區
  // ============================================================

  Widget _buildCommentSection(_CardColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '留言（${widget.post.commentCount}）',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
              fontWeight: FontWeight.bold,
              color: colors.nameColor,
            ),
          ),

          const SizedBox(height: 10),

          _buildCommentList(colors),

          const SizedBox(height: 12),

          _buildCommentInput(colors),
        ],
      ),
    );
  }

  Widget _buildCommentList(_CardColors colors) {
    if (_isLoadingComments) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.accentGreen,
            ),
          ),
        ),
      );
    }

    if (_commentError != null) {
      return Column(
        children: [
          Text(
            _commentError!,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
              color: colors.bodyColor,
            ),
          ),
          TextButton(
            onPressed: _loadComments,
            child: Text(
              '重新載入',
              style: TextStyle(color: colors.accentGreen),
            ),
          ),
        ],
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '還沒有留言，留下第一則鼓勵吧！',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
            color: colors.bodyColor,
          ),
        ),
      );
    }

    return Column(
      children: _comments
          .map((comment) => _buildCommentItem(comment, colors))
          .toList(),
    );
  }

  /// 頭像顏色：只區分自己和別人，避免留言多時畫面太花
  /// 自己：主題綠色；別人：統一低調的灰綠色
  Color _avatarColor(CommentModel comment, _CardColors colors) {
    if (comment.isMine) return colors.accentGreen;

    return colors.isDark ? const Color(0xFF5F6F65) : const Color(0xFF8A9A8F);
  }

  Widget _buildCommentItem(CommentModel comment, _CardColors colors) {
    final bool isMine = comment.isMine;

    // 自己的留言一律顯示「我」，不顯示本名
    final String name = isMine
        ? '我'
        : (comment.author.displayName.isNotEmpty
              ? comment.author.displayName
              : (comment.senderName.isNotEmpty ? comment.senderName : '使用者'));
    final String initial = name.characters.first;

    final Color textColor = colors.isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _avatarColor(comment, colors),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(13),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 對話框寬度跟著文字長短，最寬到右邊留一點空間
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: colors.chipBg,
                borderRadius: BorderRadius.circular(14),
                // 自己的留言加綠色外框，低調但看得出來
                border: isMine
                    ? Border.all(color: colors.accentGreen, width: 1.5)
                    : null,
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
                        fontWeight: FontWeight.bold,
                        color: isMine ? colors.accentGreen : colors.chipText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(
                          AppTheme.fontBody - 1,
                        ),
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(
                            AppTheme.fontCaption - 2,
                          ),
                          color: colors.bodyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 右邊保留空間，避免長留言撐滿整排
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCommentInput(_CardColors colors) {
    final inputFill = colors.isDark
        ? const Color(0xFF2A2A2A)
        : AppTheme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            enabled: !_isSubmitting,
            maxLength: 200,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
              color: colors.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '留言鼓勵一下...',
              hintStyle: colors.isDark
                  ? const TextStyle(color: Color(0xFF999999))
                  : null,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _submitComment(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submitComment,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: colors.accentGreen,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// 卡片內共用的顏色，跟著深色模式、高對比切換
class _CardColors {
  final Color titleColor;
  final Color nameColor;
  final Color bodyColor;
  final Color chipBg;
  final Color chipText;
  final Color accentGreen;
  final bool isDark;

  const _CardColors({
    required this.titleColor,
    required this.nameColor,
    required this.bodyColor,
    required this.chipBg,
    required this.chipText,
    required this.accentGreen,
    required this.isDark,
  });
}