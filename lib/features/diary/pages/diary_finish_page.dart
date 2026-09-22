import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _onShareTap() async {
    final diary = widget.diary;
    final buffer = StringBuffer();
    if (diary.inviteText != null && diary.inviteText!.isNotEmpty) {
      buffer.writeln(diary.inviteText);
    } else {
      buffer.writeln(diary.title ?? '聲影日記');
      buffer.writeln(diary.postText ?? '');
    }
    if (diary.shareUrl != null && diary.shareUrl!.isNotEmpty) {
      buffer.writeln(diary.shareUrl);
    }
    await Share.share(buffer.toString().trim());
  }

  void _onBackHomeTap() {
    Navigator.popUntil(context, (route) => route.isFirst);
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
                  // ── 分享卡片 ──
                  Container(
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

                  // ── 分享區 ──
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onShareTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                      ),
                      child: Text(
                        '分享日記',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSettings.scaleFont(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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