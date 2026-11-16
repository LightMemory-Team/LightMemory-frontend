import 'package:flutter/material.dart';

import '../../../app_settings.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/error_message.dart';
import '../../../theme/app_theme.dart';
import '../../diary/widgets/audio_player_widget.dart';
import '../models/post_model.dart';
import '../services/social_service.dart';

/// 動態牆貼文展開後的「語音加油」區：親友在分享頁錄的語音。
///
/// 每則顯示暱稱、時間、秒數、播放鍵，以及「轉文字」按鈕；
/// 轉文字由長輩自己按（後端跑 Whisper，轉過一次就存起來，之後直接顯示文字）
class VoiceReplySection extends StatefulWidget {
  final int postId;

  /// 貼文上的語音加油數（voice_reply_count），標題用
  final int count;

  final Color titleColor;
  final Color bodyColor;
  final Color accentColor;
  final Color chipBg;

  /// 測試時可以換掉
  final SocialService? service;

  const VoiceReplySection({
    super.key,
    required this.postId,
    required this.count,
    required this.titleColor,
    required this.bodyColor,
    required this.accentColor,
    required this.chipBg,
    this.service,
  });

  @override
  State<VoiceReplySection> createState() => _VoiceReplySectionState();
}

class _VoiceReplySectionState extends State<VoiceReplySection> {
  late final SocialService _service = widget.service ?? SocialService();

  List<VoiceReplyModel> _replies = [];
  bool _isLoading = true;
  String? _error;

  /// 正在轉文字的語音 id
  final Set<int> _transcribing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final replies = await _service.getVoiceReplies(widget.postId);
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[VoiceReplySection] 讀取語音加油失敗：$e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = friendlyErrorMessage(e, fallback: '語音加油讀取失敗，請稍後再試');
      });
    }
  }

  Future<void> _transcribe(VoiceReplyModel reply) async {
    if (_transcribing.contains(reply.voiceReplyId)) return;
    setState(() => _transcribing.add(reply.voiceReplyId));
    try {
      final text = await _service.transcribeVoiceReply(reply.voiceReplyId);
      if (!mounted) return;
      setState(() {
        _replies = [
          for (final r in _replies)
            r.voiceReplyId == reply.voiceReplyId
                ? r.copyWith(transcribedText: text)
                : r,
        ];
      });
    } catch (e) {
      debugPrint('[VoiceReplySection] 轉文字失敗：$e');
      if (!mounted) return;
      final message = e is ApiException && e.message.isNotEmpty
          ? e.message
          : '這段語音暫時轉不出文字，可以先直接播放聽聽看';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _transcribing.remove(reply.voiceReplyId));
    }
  }

  /// 收到時間 → 11/14 10:20
  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final count = _isLoading ? widget.count : _replies.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.record_voice_over_outlined,
              size: 20,
              color: widget.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              '語音加油（$count）',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
                fontWeight: FontWeight.bold,
                color: widget.titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildBody(),
      ],
    );
  }

  List<Widget> _buildBody() {
    if (_isLoading) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: widget.accentColor,
              ),
            ),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        Text(
          _error!,
          style: TextStyle(
            fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
            color: widget.bodyColor,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _load,
            child: Text(
              '重新載入',
              style: TextStyle(color: widget.accentColor),
            ),
          ),
        ),
      ];
    }
    if (_replies.isEmpty) {
      return [
        Text(
          '目前還沒有收到語音加油',
          style: TextStyle(
            fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
            color: widget.bodyColor,
          ),
        ),
      ];
    }
    return [for (final reply in _replies) _buildItem(reply)];
  }

  Widget _buildItem(VoiceReplyModel reply) {
    final isTranscribing = _transcribing.contains(reply.voiceReplyId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: widget.chipBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reply.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(AppTheme.fontBody - 1),
                    fontWeight: FontWeight.bold,
                    color: widget.titleColor,
                  ),
                ),
              ),
              Text(
                reply.durationSec > 0
                    ? '${_formatTime(reply.createdAt)}・${reply.durationSec} 秒'
                    : _formatTime(reply.createdAt),
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
                  color: widget.bodyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (reply.audioUrl.isNotEmpty)
                AudioPlayerWidget(audioUrl: reply.audioUrl),
              const Spacer(),
              if (!reply.isTranscribed)
                TextButton.icon(
                  onPressed: isTranscribing ? null : () => _transcribe(reply),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accentColor,
                    minimumSize: const Size(48, 44),
                  ),
                  icon: isTranscribing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.accentColor,
                          ),
                        )
                      : const Icon(Icons.subtitles_outlined, size: 20),
                  label: Text(
                    isTranscribing ? '轉文字中…' : '轉文字',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontCaption),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (reply.isTranscribed) ...[
            const SizedBox(height: 6),
            Text(
              '「${reply.transcribedText.trim()}」',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                height: 1.4,
                color: widget.titleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
