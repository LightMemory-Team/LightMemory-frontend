import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../models/diary_model.dart';
import '../services/diary_service.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';
import '../../home/widgets/top_bar.dart';

/// 動態回顧頁（對照比賽版 review.html）：
/// 上方「昨天／去年的今天」切換，下方列出那天的日記卡片。
/// 卡片直接顯示完整內文，語音也在卡片上播放，不另外彈出視窗。
/// 依 10/7 會議決議，只顯示日記內容，不顯示按讚、留言，也不跳轉動態牆。
class DiaryReviewPage extends StatefulWidget {
  const DiaryReviewPage({super.key});

  @override
  State<DiaryReviewPage> createState() => _DiaryReviewPageState();
}

class _DiaryReviewPageState extends State<DiaryReviewPage> {
  final DiaryService _diaryService = DiaryService();

  bool _isLoading = true;
  String? _errorMessage;
  DiaryReviewResult? _result;

  /// 0：昨天，1：去年的今天
  int _tabIndex = 0;

  static const List<String> _tabLabels = ['昨天', '去年的今天'];

  // ── 語音播放：整頁共用一個播放器，同一時間只會播一篇 ──
  final AudioPlayer _player = AudioPlayer();
  int? _currentDiaryId; // 目前載入的是哪一篇的錄音
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  // 每次按播放或切換分頁都 +1；舊的播放請求晚回來時，
  // 比對編號就知道它已經過期，不會把畫面改回轉圈或跳出錯誤
  int _playRequestId = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 播完後保留音檔，再按一次「播放語音」可以從頭重播，不用重新下載
    _player.setReleaseMode(ReleaseMode.stop);
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    _loadReview();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// 按播放鍵：同一篇就暫停／繼續；換一篇就先停掉原本的，從頭播新的
  Future<void> _onPlayTap(DiaryReviewItem entry) async {
    final url = entry.audioUrl;
    if (url == null || _isAudioLoading) return;

    if (_currentDiaryId == entry.diaryId) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      return;
    }

    final requestId = ++_playRequestId;
    setState(() {
      _currentDiaryId = entry.diaryId;
      _isAudioLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    try {
      await _player.stop();
      // 網路慢或網址失效時，最多等 15 秒，避免一直轉圈
      await _player.play(UrlSource(url)).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[DiaryReviewPage] 播放語音例外: $e');
      // 這段期間已經換播別篇或切了分頁，舊請求的錯誤不用理會
      if (!mounted || requestId != _playRequestId) return;
      await _player.stop();
      if (!mounted) return;
      setState(() => _currentDiaryId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('語音播放失敗，請稍後再試')),
      );
    } finally {
      if (mounted && requestId == _playRequestId) {
        setState(() => _isAudioLoading = false);
      }
    }
  }

  /// 切換「昨天／去年的今天」時，原本的卡片不見了，聲音也一起停掉
  Future<void> _onTabTap(int index) async {
    if (index == _tabIndex) return;
    // 讓還在載入中的播放請求過期，切回來時按鈕不會卡在轉圈
    _playRequestId++;
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _tabIndex = index;
      _currentDiaryId = null;
      _isAudioLoading = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _loadReview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _diaryService.getDiaryReview();
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DiaryReviewPage] 讀取動態回顧例外: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '讀取失敗，請檢查網路或登入狀態後再試一次';
      });
    }
  }

  /// 後端給的 date 是 YYYY-MM-DD，列表上方顯示成「2026年10月13日 星期二」
  String _formatDateWithWeekday(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('y年M月d日 EEEE', 'zh_TW').format(parsed);
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
        final colors = _ReviewColors.current();

        return Scaffold(
          backgroundColor: colors.background,
          appBar: const TopBar(title: '動態回顧', showBackButton: true),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildTabBar(colors),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildContent(colors)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 上方切換：昨天／去年的今天 ──

  Widget _buildTabBar(_ReviewColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.tabBarBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        children: List.generate(_tabLabels.length, (index) {
          final selected = index == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabels[index],
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(15),
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : colors.subtitle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── 主要內容：讀取中／讀取失敗／空狀態／日記列表 ──

  Widget _buildContent(_ReviewColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(15),
                  color: colors.body,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '重新載入',
                  style: TextStyle(fontSize: AppSettings.scaleFont(15)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = _tabIndex == 0
        ? (_result?.yesterday ?? <DiaryReviewItem>[])
        : (_result?.lastYear ?? <DiaryReviewItem>[]);

    if (entries.isEmpty) {
      return _buildEmptyState(colors);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _buildSectionLabel(
          _formatDateWithWeekday(entries.first.date),
          colors,
        ),
        const SizedBox(height: 12),
        for (final entry in entries) ...[
          _buildDiaryCard(entry, colors),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  /// 「2026年10月13日 星期二」日期標籤。
  /// 上方切換鈕已經寫了「昨天／去年的今天」，這裡只放日期，不再重複。
  Widget _buildSectionLabel(String date, _ReviewColors colors) {
    return Text(
      date,
      style: TextStyle(
        fontSize: AppSettings.scaleFont(14),
        fontWeight: FontWeight.bold,
        color: colors.subtitle,
      ),
    );
  }

  Widget _buildEmptyState(_ReviewColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 56,
            color: colors.subtitle.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '這天還沒有日記',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(17),
              fontWeight: FontWeight.bold,
              color: colors.body,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '快去記錄今天的故事吧！',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              color: colors.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  // ── 日記卡片 ──

  Widget _buildPhoto(String photoUrl, _ReviewColors colors) {
    final placeholder = Container(
      color: colors.chipBackground,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: colors.chipText.withValues(alpha: 0.5),
      ),
    );
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: photoUrl.isEmpty
          ? placeholder
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }

  Widget _buildDiaryCard(DiaryReviewItem entry, _ReviewColors colors) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoto(entry.photoUrl, colors),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期只顯示在上方的日期標籤，卡片裡不再重複
                if (entry.title.isNotEmpty) ...[
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(18),
                      fontWeight: FontWeight.w900,
                      color: colors.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // 內文完整顯示，不截斷（原本點開彈窗才看得到全文，現在不需要彈窗）
                Text(
                  entry.postText,
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(15),
                    height: 1.7,
                    color: colors.body,
                  ),
                ),
                if (entry.audioUrl != null) ...[
                  const SizedBox(height: 14),
                  _buildPlayRow(entry, colors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 「播放語音／暫停」按鈕；正在播這一篇時，右邊顯示播放時間
  Widget _buildPlayRow(DiaryReviewItem entry, _ReviewColors colors) {
    final isCurrent = _currentDiaryId == entry.diaryId;
    final isLoading = isCurrent && _isAudioLoading;
    final isPlaying = isCurrent && _isPlaying;

    final Widget icon = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 22,
          );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => _onPlayTap(entry),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primaryColor,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
          icon: icon,
          label: Text(
            isPlaying ? '暫停' : '播放語音',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(15),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isCurrent && _duration > Duration.zero)
          Text(
            '${_formatTime(_position)} / ${_formatTime(_duration)}',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(14),
              color: colors.subtitle,
            ),
          ),
      ],
    );
  }
}

/// 這頁用到的顏色，淺色／深色／高對比各一組
/// （深色沿用完成頁的配色：背景 0xFF121212、卡片 0xFF1E1E1E、標籤 0xFF25382E／0xFFB8E6D0）
class _ReviewColors {
  final Color background;
  final Color card;
  final Color border;
  final Color title;
  final Color body;
  final Color subtitle;
  final Color chipBackground;
  final Color chipText;
  final Color tabBarBackground;

  const _ReviewColors({
    required this.background,
    required this.card,
    required this.border,
    required this.title,
    required this.body,
    required this.subtitle,
    required this.chipBackground,
    required this.chipText,
    required this.tabBarBackground,
  });

  factory _ReviewColors.current() {
    final isDark = AppSettings.isDarkMode.value;
    final isHighContrast = AppSettings.isHighContrast.value;
    if (isDark) {
      return const _ReviewColors(
        background: Color(0xFF121212),
        card: Color(0xFF1E1E1E),
        border: Color(0xFF3A3A3A),
        title: Colors.white,
        body: Colors.white,
        subtitle: Color(0xFFCCCCCC),
        chipBackground: Color(0xFF25382E),
        chipText: Color(0xFFB8E6D0),
        tabBarBackground: Color(0xFF1E1E1E),
      );
    }
    return _ReviewColors(
      background: AppTheme.backgroundColor,
      card: AppTheme.cardColor,
      border: AppTheme.colorScheme.outlineVariant,
      title: AppTheme.primaryColor,
      body: isHighContrast ? Colors.black : const Color(0xFF1E1E1E),
      subtitle: isHighContrast
          ? const Color(0xFF333333)
          : AppTheme.colorScheme.onSurfaceVariant,
      chipBackground: AppTheme.colorScheme.secondaryContainer,
      chipText: AppTheme.colorScheme.onSecondaryContainer,
      tabBarBackground: AppTheme.colorScheme.surfaceContainerHighest,
    );
  }
}
