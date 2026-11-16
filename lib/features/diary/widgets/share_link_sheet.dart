import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';

/// 親友分享連結（LINE／Facebook／複製連結）的共用邏輯。
/// 日記完成頁、動態牆貼文卡片都用這一份，分享出去的文字與網址格式一致
class ShareLinks {
  ShareLinks._();

  // LINE、Facebook 的品牌色（對照比賽版分享頁）
  static const Color lineGreen = Color(0xFF06C755);
  static const Color facebookBlue = Color(0xFF1877F2);

  /// 組出要分享出去的文字：有邀請文字就用邀請文字，沒有就用標題＋內文，
  /// 最後接上親友分享頁的連結
  static String buildShareText({
    required String shareUrl,
    String inviteText = '',
    String title = '',
    String postText = '',
  }) {
    final buffer = StringBuffer();
    if (inviteText.isNotEmpty) {
      buffer.writeln(inviteText);
    } else {
      buffer.writeln(title.isNotEmpty ? title : '聲影日記');
      if (postText.isNotEmpty) buffer.writeln(postText);
    }
    buffer.writeln(shareUrl);
    return buffer.toString().trim();
  }

  /// LINE 的「傳送文字」網址：手機會直接開 LINE 選聊天室。
  /// 不用 `line.me/R/share`：比賽版實測會跳到 LINE 首頁
  static Uri lineUri(String text) =>
      Uri.parse('https://line.me/R/msg/text/?${Uri.encodeComponent(text)}');

  static Uri facebookUri(String shareUrl) => Uri.parse(
    'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
  );

  /// 開啟 LINE；打不開時回傳 false
  static Future<bool> openLine(String text) => _launch(lineUri(text));

  /// 開啟 Facebook 分享；打不開時回傳 false
  static Future<bool> openFacebook(String shareUrl) =>
      _launch(facebookUri(shareUrl));

  static Future<void> copyLink(String shareUrl) =>
      Clipboard.setData(ClipboardData(text: shareUrl));

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[ShareLinks] 開啟 $uri 例外: $e');
      return false;
    }
  }
}

/// 從下方滑出的分享面板：傳到 LINE、分享到 Facebook、複製連結。
/// 動態牆貼文卡片的「分享」按鈕使用；提示訊息顯示在原本頁面的 SnackBar
Future<void> showShareLinkSheet(
  BuildContext context, {
  required String shareUrl,
  required String shareText,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void showMessage(String message) {
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final isDark = AppSettings.isDarkMode.value;
      final titleColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
      final bodyColor = isDark
          ? const Color(0xFFCCCCCC)
          : AppTheme.colorScheme.onSurfaceVariant;

      Future<void> close() async => Navigator.of(sheetContext).pop();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '分享給親友',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(20),
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '親友點開連結，就能看這篇日記、留言加油',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(15),
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 16),
              _ShareOption(
                icon: Icons.chat_bubble_outline,
                label: '傳到 LINE',
                background: ShareLinks.lineGreen,
                foreground: Colors.white,
                onTap: () async {
                  await close();
                  final ok = await ShareLinks.openLine(shareText);
                  if (!ok) showMessage('無法開啟 LINE，請確認已安裝 LINE');
                },
              ),
              const SizedBox(height: 10),
              _ShareOption(
                icon: Icons.thumb_up_alt_outlined,
                label: '分享到 Facebook',
                background: ShareLinks.facebookBlue,
                foreground: Colors.white,
                onTap: () async {
                  await close();
                  final ok = await ShareLinks.openFacebook(shareUrl);
                  if (!ok) showMessage('無法開啟 Facebook，請稍後再試');
                },
              ),
              const SizedBox(height: 10),
              _ShareOption(
                icon: Icons.link_rounded,
                label: '複製連結',
                foreground: isDark
                    ? const Color(0xFF4CAF50)
                    : AppTheme.primaryColor,
                onTap: () async {
                  await close();
                  await ShareLinks.copyLink(shareUrl);
                  showMessage('連結已複製，可以貼到 LINE 或訊息裡');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 分享面板裡的一個大按鈕；沒有底色時是外框按鈕
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? background;
  final Color foreground;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(17),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      height: 56,
      child: background != null
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                shape: shape,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground, width: 2),
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}
