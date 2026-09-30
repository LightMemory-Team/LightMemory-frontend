import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/diary_model.dart';
import '../models/diary_reply_model.dart';
import '../services/diary_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/record_button.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app_settings.dart';
import '../../home/widgets/top_bar.dart';

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? audioUrl;

  const _ChatMessage.ai(this.text)
      : isUser = false,
        audioUrl = null;
  const _ChatMessage.user(this.text, {this.audioUrl}) : isUser = true;
}

class DiaryChatPage extends StatefulWidget {
  final DiaryModel initialDiary;

  const DiaryChatPage({super.key, required this.initialDiary});

  @override
  State<DiaryChatPage> createState() => _DiaryChatPageState();
}

class _DiaryChatPageState extends State<DiaryChatPage> {
  final DiaryService _diaryService = DiaryService();
  final AudioPlayer _replyPlayer = AudioPlayer();
  final GlobalKey<State<RecordButton>> _recordButtonKey =
      GlobalKey<State<RecordButton>>();
  final ScrollController _scrollController = ScrollController();

  static const int _minFirstReplySeconds = 15;
  static const int _maxShortAttempts = 3;
  static const int _targetReplies = 4;
  static const int _minRepliesToFinalize = 2;

  bool _isSubmitting = false;
  bool _isTyping = false;
  bool _isDone = false;
  RecordButtonState _recordState = RecordButtonState.idle;

  late String? _photoUrl;
  final List<_ChatMessage> _messages = [];
  int _roundIndex = 1;
  int _replyCount = 0;
  int _firstRoundShortAttempts = 0;
  bool _isFinalizable = false;

  int get _diaryId => widget.initialDiary.diaryId;

  @override
  void initState() {
    super.initState();
    // D-4（單篇日記詳情）後端還沒提供，這裡不再另外呼叫 API 讀歷史對話，
    // 直接用上一頁建立日記時（D-3）拿到的資料組出聊天室的起始畫面。
    _photoUrl = widget.initialDiary.photoUrl;
    _messages.add(_ChatMessage.ai(widget.initialDiary.firstQuestion));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetRecordButton() {
    (_recordButtonKey.currentState as dynamic)?.resetToIdle();
  }

  Future<void> _onRoundComplete(XFile audioFile, int elapsedSeconds) async {
    debugPrint(
      '[DiaryChatPage] onRoundComplete: roundIndex=$_roundIndex, elapsedSeconds=$elapsedSeconds',
    );
    // 只有第一輪才檢查最低時長，第二輪之後不管多短都直接送出
    if (_roundIndex == 1 && elapsedSeconds < _minFirstReplySeconds) {
      _firstRoundShortAttempts++;
      if (_firstRoundShortAttempts < _maxShortAttempts) {
        setState(() {
          _messages.add(
            _ChatMessage.ai(
              '再多說一點好嗎？可以講講照片裡有誰、在哪裡、發生了什麼事～（剛剛錄了 $elapsedSeconds 秒）',
            ),
          );
        });
        _scrollToBottom();
        _resetRecordButton();
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _diaryService.submitReply(
        _diaryId,
        audio: audioFile,
        roundIndex: _roundIndex,
        isForced: _firstRoundShortAttempts >= _maxShortAttempts,
      );
      // 後端沒聽到聲音時回傳的是空字串而不是 null，
      // 兩種情況都要顯示提示，避免出現只有播放鍵的空白氣泡
      final transcript = result.transcript?.trim() ?? '';
      await _handleReplyResult(
        userText: transcript.isEmpty ? '（沒有聽清楚）' : transcript,
        audioUrl: result.audioUrl,
        result: result,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('送出失敗，請再試一次（$e）')));
      _resetRecordButton();
    }
  }

  Future<void> _onSkipTap() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await _diaryService.skipReply(
        _diaryId,
        roundIndex: _roundIndex,
      );
      await _handleReplyResult(
        userText: '（已跳過本題）',
        audioUrl: null,
        result: result,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('跳過失敗，請再試一次（$e）')));
    }
  }

  Future<void> _handleReplyResult({
    required String userText,
    String? audioUrl,
    required ReplySubmitResult result,
  }) async {
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage.user(userText, audioUrl: audioUrl));
      _replyCount = result.replyCount;
      _isFinalizable = result.isFinalizable;
      _isSubmitting = false;
      _firstRoundShortAttempts = 0;
    });
    _scrollToBottom();

    if (result.isDone || result.aiReply == null) {
      setState(() => _isDone = true);
      _goToLoadingPage();
      return;
    }

    // 模擬 AI「思考中」的短暫停頓，跟比賽版一致
    setState(() => _isTyping = true);
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage.ai(result.aiReply!));
      _roundIndex += 1;
    });
    _scrollToBottom();
    _resetRecordButton();
  }

  Future<void> _onFinalizeTap() async {
    if (_isSubmitting) return;
    _goToLoadingPage();
  }

  void _goToLoadingPage() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.voiceDiaryLoading,
      arguments: _diaryId,
    );
  }

  Future<void> _playAudio(String url) async {
    await _replyPlayer.stop();
    await _replyPlayer.play(UrlSource(url));
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
        final isHighContrast = AppSettings.isHighContrast.value;

        final bgColor = isDark
            ? const Color(0xFF121212)
            : AppTheme.backgroundColor;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final subtitleColor = isDark
            ? const Color(0xFFCCCCCC)
            : AppTheme.colorScheme.onSurfaceVariant;

        final canSkip = _replyCount >= 2 &&
            _replyCount < _targetReplies &&
            !_isSubmitting &&
            !_isTyping &&
            _recordState == RecordButtonState.idle;
        final canFinalizeEarly = _replyCount >= _minRepliesToFinalize &&
            !_isSubmitting &&
            !_isTyping &&
            _recordState == RecordButtonState.idle;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(title: '聲影日記', showBackButton: true),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      Text(
                        '跟我聊聊這張照片吧',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(AppTheme.fontTitle),
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI 會陪你聊 4 段小對話，聊完會自動生成今天的日記',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_photoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusCard,
                          ),
                          child: Image.network(
                            _photoUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return const ChatBubble(
                          isUser: false,
                          text: '',
                          isTyping: true,
                        );
                      }
                      final message = _messages[index];
                      return ChatBubble(
                        isUser: message.isUser,
                        text: message.text,
                        onPlayTap: message.audioUrl == null
                            ? null
                            : () => _playAudio(message.audioUrl!),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      RecordButton(
                        key: _recordButtonKey,
                        isFirstRound: _roundIndex == 1,
                        onRoundComplete: _onRoundComplete,
                        onStateChanged: (s) {
                          setState(() => _recordState = s);
                          // 錄音狀態一變，下方的提示文字、「這題跳過」、
                          // 「生成日記」按鈕可能出現或消失，對話區的高度會跟著變，
                          // 這時再捲一次到底，避免最新的 AI 問題被錄音區擋住
                          _scrollToBottom();
                        },
                        onError: (msg) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      if (canSkip)
                        OutlinedButton(
                          onPressed: _onSkipTap,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF4A4A4A)
                                  : AppTheme.colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                            ),
                          ),
                          child: Text(
                            '這題跳過',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: AppSettings.scaleFont(13),
                            ),
                          ),
                        ),
                      if (canFinalizeEarly) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _onFinalizeTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                            ),
                            child: Text(
                              '生成日記（已錄 $_replyCount 段，可繼續或直接生成）',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSettings.scaleFont(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}