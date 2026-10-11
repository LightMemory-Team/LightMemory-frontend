import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diary_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';
import '../../home/widgets/top_bar.dart';

class DiaryFinishPage extends StatefulWidget {
  final DiaryModel diary;

  const DiaryFinishPage({super.key, required this.diary});

  @override
  State<DiaryFinishPage> createState() => _DiaryFinishPageState();
}

class _DiaryFinishPageState extends State<DiaryFinishPage> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  // 儲存圖片用：把分享卡片包在 RepaintBoundary 裡，才能轉成圖片
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;

  // LINE、Facebook 的品牌色（對照比賽版分享頁）
  static const Color _lineGreen = Color(0xFF06C755);
  static const Color _facebookBlue = Color(0xFF1877F2);

  // 後端 finalize 還沒回傳 share_url 前，Facebook／複製連結先顯示這句提示
  static const String _shareUrlPendingMessage = '分享連結準備中，之後就能使用';

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-TW');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // AI 產生的貼文可能帶 emoji 跟 hashtag，直接朗讀會唸出雜音，先清乾淨
  // （對照比賽版 share.js 的 cleanForSpeech）
  String _cleanForSpeech(String raw) {
    return raw
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'#[^\s#]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _onSpeakTap() async {
    if (_isSpeaking) {
      try {
        await _tts.stop();
      } catch (e) {
        debugPrint('[DiaryFinishPage] _tts.stop() 例外: $e');
      }
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    final text = _cleanForSpeech(widget.diary.postText ?? '');
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[DiaryFinishPage] _tts.speak() 例外: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  // ── 分享 ──

  bool get _hasShareUrl =>
      widget.diary.shareUrl != null && widget.diary.shareUrl!.isNotEmpty;

  /// 組出要分享出去的文字：有邀請文字就用邀請文字，沒有就用標題＋內文；
  /// 有 share_url 時接在最後面
  String _buildShareText() {
    final diary = widget.diary;
    final buffer = StringBuffer();
    if (diary.inviteText != null && diary.inviteText!.isNotEmpty) {
      buffer.writeln(diary.inviteText);
    } else {
      buffer.writeln(diary.title ?? '聲影日記');
      buffer.writeln(diary.postText ?? '');
    }
    if (_hasShareUrl) {
      buffer.writeln(diary.shareUrl);
    }
    return buffer.toString().trim();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// LINE 分享：使用 LINE 官方的分享網址，
  /// 手機上會直接開啟 LINE App，電腦上會開啟 LINE 的網頁分享頁
  Future<void> _onLineShareTap() async {
    final uri = Uri.parse(
      'https://line.me/R/share?text=${Uri.encodeComponent(_buildShareText())}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showMessage('無法開啟 LINE，請確認已安裝 LINE');
    } catch (e) {
      debugPrint('[DiaryFinishPage] LINE 分享例外: $e');
      _showMessage('無法開啟 LINE，請確認已安裝 LINE');
    }
  }

  /// Facebook 分享需要一個可以點開的網址，後端提供 share_url 之後會自動生效
  Future<void> _onFacebookShareTap() async {
    if (!_hasShareUrl) {
      _showMessage(_shareUrlPendingMessage);
      return;
    }
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(widget.diary.shareUrl!)}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showMessage('無法開啟 Facebook，請稍後再試');
    } catch (e) {
      debugPrint('[DiaryFinishPage] Facebook 分享例外: $e');
      _showMessage('無法開啟 Facebook，請稍後再試');
    }
  }

  /// 複製連結同樣需要 share_url，後端提供之後會自動生效
  Future<void> _onCopyLinkTap() async {
    if (!_hasShareUrl) {
      _showMessage(_shareUrlPendingMessage);
      return;
    }
    await Clipboard.setData(ClipboardData(text: widget.diary.shareUrl!));
    _showMessage('連結已複製，可以貼到 LINE 或訊息裡');
  }

  /// 把分享卡片轉成 PNG 圖片並下載
  /// （目前在 Chrome 上會直接下載成檔案；手機上存進相簿之後另外處理）
  Future<void> _onSaveImageTap() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('找不到分享卡片');

      // pixelRatio 設 3，存出來的圖片才夠清楚
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('圖片轉換失敗');

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'lightmemory_diary_${widget.diary.diaryId}.png';
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: fileName,
      );
      await file.saveTo(fileName);
      _showMessage('圖片已儲存');
    } catch (e) {
      debugPrint('[DiaryFinishPage] 儲存圖片例外: $e');
      _showMessage('圖片儲存失敗，請再試一次');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onBackHomeTap() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// 分享區的按鈕：有 background 就是實心按鈕，沒有就是外框按鈕
  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color foreground,
    Color? background,
  }) {
    // 字級調大時用 FittedBox 縮小內容，避免兩顆並排的按鈕文字被截斷
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.bold,
              fontSize: AppSettings.scaleFont(15),
            ),
          ),
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return SizedBox(
      height: 56,
      child: background != null
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                shape: shape,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: foreground, width: 2),
                shape: shape,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: content,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diary = widget.diary;
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;

        final bgColor = isDark ? const Color(0xFF121212) : AppTheme.backgroundColor;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
        final titleColor = isDark ? Colors.white : AppTheme.primaryColor;
        final bodyColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
        final subtitleColor = isDark
            ? const Color(0xFFCCCCCC)
            : AppTheme.colorScheme.onSurfaceVariant;
        final dividerColor = isDark
            ? const Color(0xFF3A3A3A)
            : AppTheme.colorScheme.outlineVariant;
        final tagBgColor = isDark ? const Color(0xFF25382E) : AppTheme.colorScheme.secondaryContainer;
        final tagTextColor = isDark ? const Color(0xFFB8E6D0) : AppTheme.colorScheme.onSecondaryContainer;
        // 外框按鈕的顏色：深色模式下深綠太暗，改用亮一點的綠（與底部導覽列一致）
        final outlineButtonColor =
            isDark ? const Color(0xFF4CAF50) : AppTheme.primaryColor;

        final dateText = diary.createdAt != null
            ? DateFormat('y年M月d日', 'zh_TW').format(diary.createdAt!)
            : '';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(title: '聲影日記', showBackButton: true),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 分享卡片（包在 RepaintBoundary 裡，才能存成圖片）──
                  RepaintBoundary(
                    key: _cardKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: diary.photoUrl != null
                                ? Image.network(
                                    diary.photoUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 200,
                                    color: tagBgColor,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 48,
                                      color: tagTextColor.withOpacity(0.5),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diary.title ?? '',
                                  style: TextStyle(
                                    fontSize: AppSettings.scaleFont(22),
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  diary.postText ?? '',
                                  style: TextStyle(
                                    fontSize: AppSettings.scaleFont(15),
                                    color: bodyColor,
                                    height: 1.7,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: AppSettings.scaleFont(12),
                                    color: subtitleColor,
                                  ),
                                ),
                                if (diary.hashtags != null &&
                                    diary.hashtags!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: diary.hashtags!
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tagBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize:
                                                    AppSettings.scaleFont(13),
                                                fontWeight: FontWeight.bold,
                                                color: tagTextColor,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: dividerColor, width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '聲影日記',
                                  style: TextStyle(
                                    fontSize: AppSettings.scaleFont(12),
                                    fontWeight: FontWeight.bold,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 朗讀 ──
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _onSpeakTap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                      ),
                      icon: Icon(
                        _isSpeaking ? Icons.pause : Icons.volume_up,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        _isSpeaking ? '朗讀中…（再按一次停止）' : '朗讀',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSettings.scaleFont(15),
                        ),
                      ),
                    ),
                  ),

                  // ── 分享區（對照比賽版分享頁的 2 × 2 排列）──
                  const SizedBox(height: 24),
                  Text(
                    '分享這則日記',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSettings.scaleFont(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShareButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'LINE 分享',
                          onPressed: _onLineShareTap,
                          foreground: Colors.white,
                          background: _lineGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareButton(
                          icon: Icons.thumb_up_alt_outlined,
                          label: 'Facebook',
                          onPressed: _onFacebookShareTap,
                          foreground: Colors.white,
                          background: _facebookBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShareButton(
                          icon: Icons.download_rounded,
                          label: _isSaving ? '儲存中…' : '儲存圖片',
                          onPressed: _isSaving ? null : _onSaveImageTap,
                          foreground: outlineButtonColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShareButton(
                          icon: Icons.link_rounded,
                          label: '複製連結',
                          onPressed: _onCopyLinkTap,
                          foreground: outlineButtonColor,
                        ),
                      ),
                    ],
                  ),

                  // ── 回首頁 ──
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _onBackHomeTap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                      ),
                      child: Text(
                        '回首頁',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSettings.scaleFont(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}