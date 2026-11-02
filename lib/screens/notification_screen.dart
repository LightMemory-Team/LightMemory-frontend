import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../core/network/error_message.dart';
import '../features/home/models/notification_model.dart';
import '../features/home/services/notification_service.dart';
import '../features/social/pages/post_detail_page.dart';

/// 最新通知頁（GET /api/notifications/、PATCH /api/notifications/）
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMarkingRead = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _notifications.isEmpty;
      _errorMessage = null;
    });
    try {
      final list = await _service.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      // 右上角鈴鐺的紅點數字跟列表同步
      AppSettings.unreadNotificationCount.value = list
          .where((n) => !n.isRead)
          .length;
    } catch (e) {
      debugPrint('❌ 讀取通知失敗: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入通知');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_isMarkingRead) return;
    setState(() => _isMarkingRead = true);
    try {
      await _service.markAllRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
      // 點擊後將未讀數歸零，紅點即刻消失
      AppSettings.unreadNotificationCount.value = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已將所有通知標記為已讀'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('❌ 全部已讀失敗: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyErrorMessage(e, fallback: '標記已讀失敗，請稍後再試')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMarkingRead = false);
    }
  }

  /// 點通知：comment 類型跳到對應的動態牆貼文（留言展開），並把這則標為已讀
  void _openNotification(AppNotification item) {
    if (!item.opensPost) return;
    final postId = PostDetailPage.postIdFromTargetUrl(item.targetUrl);
    if (postId == null) {
      debugPrint('通知 ${item.id} 的 target_url 無法解析出貼文：「${item.targetUrl}」');
      return;
    }
    if (!item.isRead) _markRead(item);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PostDetailPage(postId: postId)),
    );
  }

  /// 單筆已讀：先讓畫面變已讀、鈴鐺數字減 1；失敗就還原
  Future<void> _markRead(AppNotification item) async {
    _setRead(item.id, true);
    final count = AppSettings.unreadNotificationCount.value;
    if (count > 0) AppSettings.unreadNotificationCount.value = count - 1;
    try {
      await _service.markRead(item.id);
    } catch (e) {
      debugPrint('❌ 標記單筆已讀失敗: $e');
      if (!mounted) return;
      _setRead(item.id, false);
      AppSettings.unreadNotificationCount.value = AppSettings.unreadNotificationCount.value + 1;
    }
  }

  void _setRead(int id, bool isRead) {
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(isRead: isRead) : n)
          .toList();
    });
  }

  /// 把 created_at 轉成「剛剛／N 分鐘前／N 小時前／昨天／M/d」
  String _timeText(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;
    if (days == 0) return '${diff.inHours} 小時前';
    if (days == 1) return '昨天';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
        AppSettings.unreadNotificationCount,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;
        final unreadCount = AppSettings.unreadNotificationCount.value;

        // 深淺色模式色彩適配
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final cardBgColor = isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF1F8F4);
        final cardBorderColor = isDark
            ? const Color(0xFF333333)
            : (isHighContrast
                  ? const Color(0xFF2E6342)
                  : const Color(0xFFC8E6C9));
        final themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);

        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final messageColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast
                  ? const Color(0xFF212121)
                  : const Color(0xFF424242));
        final timeColor = isDark
            ? const Color(0xFF9E9E9E)
            : (isHighContrast
                  ? const Color(0xFF424242)
                  : const Color(0xFF757575));

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeGreen),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '最新通知',
              style: TextStyle(
                color: themeGreen,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
            // 右上方「全部已讀」按鈕
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: unreadCount > 0 && !_isMarkingRead
                      ? _markAllRead
                      : null,
                  child: Text(
                    '全部已讀',
                    style: TextStyle(
                      color: unreadCount > 0
                          ? themeGreen
                          : (isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFFBDBDBD)),
                      fontSize: AppSettings.scaleFont(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _buildBody(
            themeGreen: themeGreen,
            titleColor: titleColor,
            messageColor: messageColor,
            timeColor: timeColor,
            cardBgColor: cardBgColor,
            cardBorderColor: cardBorderColor,
            isDark: isDark,
            isHighContrast: isHighContrast,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required Color themeGreen,
    required Color titleColor,
    required Color messageColor,
    required Color timeColor,
    required Color cardBgColor,
    required Color cardBorderColor,
    required bool isDark,
    required bool isHighContrast,
  }) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: themeGreen));
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: timeColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  color: messageColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '再試一次',
                  style: TextStyle(fontSize: AppSettings.scaleFont(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 空狀態也包在 ListView 裡，才能下拉重新整理
    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: themeGreen,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.notifications_none_rounded, size: 48, color: timeColor),
            const SizedBox(height: 12),
            Text(
              '目前沒有新通知',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                color: messageColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: themeGreen,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openNotification(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardBorderColor,
                  width: isHighContrast ? 2.0 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? themeGreen.withValues(alpha: 0.2)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: themeGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 未讀的通知前面加紅點
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 7, right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(15),
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : (isHighContrast
                                            ? FontWeight.w900
                                            : FontWeight.bold),
                                  color: item.isRead
                                      ? messageColor
                                      : titleColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _timeText(item.createdAt),
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(12),
                              color: timeColor,
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
      ),
    );
  }
}
