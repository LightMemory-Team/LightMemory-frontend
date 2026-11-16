import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../core/services/reminder_service.dart';
import '../features/auth/services/logout_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 每日提醒的設定；讀到之前用預設值（關閉、晚上 8:00）
  ReminderSettings _reminder = ReminderSettings.defaults;
  bool _isUpdatingReminder = false;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final settings = await ReminderService.load();
    if (mounted) setState(() => _reminder = settings);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontSize: AppSettings.scaleFont(16)),
          ),
        ),
      );
  }

  /// 打開時先要通知權限；沒給就把開關關回去並說明
  Future<void> _onReminderToggled(bool on) async {
    if (_isUpdatingReminder) return;
    setState(() => _isUpdatingReminder = true);
    try {
      if (on) {
        final ok = await ReminderService.enable(_reminder.time);
        if (!mounted) return;
        _showMessage(
          ok
              ? '已設定每天 ${ReminderService.formatTime(_reminder.time)} 提醒'
              : '需要允許通知才能提醒您，請到手機的「設定」開啟通知',
        );
      } else {
        await ReminderService.disable();
        if (!mounted) return;
        _showMessage('已關閉每日提醒');
      }
    } catch (e) {
      debugPrint('[SettingsScreen] 設定提醒失敗：$e');
      if (mounted) _showMessage('提醒設定失敗，請稍後再試一次');
    } finally {
      await _loadReminder();
      if (mounted) setState(() => _isUpdatingReminder = false);
    }
  }

  Future<void> _onPickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder.time,
      helpText: '選擇每天提醒的時間',
      cancelText: '取消',
      confirmText: '確定',
    );
    if (picked == null || !mounted) return;
    try {
      await ReminderService.updateTime(picked);
      await _loadReminder();
      if (!mounted) return;
      _showMessage('已設定每天 ${ReminderService.formatTime(picked)} 提醒');
    } catch (e) {
      debugPrint('[SettingsScreen] 更改提醒時間失敗：$e');
      if (mounted) _showMessage('提醒設定失敗，請稍後再試一次');
    }
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
        final bool isDark = AppSettings.isDarkMode.value;
        final bool isHighContrast = AppSettings.isHighContrast.value;
        final int currentLevel = AppSettings.fontSizeLevel.value;

        final Color bgColor = isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF8FAF9);
        final Color cardBgColor = isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        final Color appBarBgColor = isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        final Color themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);

        final Color primaryTextColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));

        final Color secondaryTextColor = isDark
            ? const Color(0xFFB0B0B0)
            : (isHighContrast
                  ? const Color(0xFF333333)
                  : const Color(0xFF757575));

        final Color borderColor = isDark
            ? const Color(0xFF333333)
            : (isHighContrast
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFE8ECE9));

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: appBarBgColor,
            elevation: 0.5,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeGreen),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '設定',
              style: TextStyle(
                color: themeGreen,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 分類標題：顯示
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  '顯示',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              ),

              // 顯示設定卡片
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Material(
                  // ListTile 的水波紋要畫在 Material 上，否則會被卡片底色蓋住
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      // 1. 字體大小調節區塊
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '字體大小',
                                    style: TextStyle(
                                      fontSize: AppSettings.scaleFont(17),
                                      fontWeight: isHighContrast
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppSettings.fontSizeLabel,
                                    style: TextStyle(
                                      fontSize: AppSettings.scaleFont(14),
                                      color: themeGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 步進按鈕組：− 數字 +
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFF1F8F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF444444)
                                      : const Color(0xFFB7D5C2),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_rounded,
                                      color: themeGreen,
                                      size: 22,
                                    ),
                                    onPressed: currentLevel > 1
                                        ? () {
                                            AppSettings.fontSizeLevel.value--;
                                          }
                                        : null,
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$currentLevel',
                                      style: TextStyle(
                                        fontSize: AppSettings.scaleFont(18),
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_rounded,
                                      color: themeGreen,
                                      size: 22,
                                    ),
                                    onPressed: currentLevel < 5
                                        ? () {
                                            AppSettings.fontSizeLevel.value++;
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: borderColor,
                      ),

                      // 2. 深色模式開關
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          '深色模式',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(17),
                            fontWeight: isHighContrast
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          '夜間保護視力',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(13),
                            color: secondaryTextColor,
                          ),
                        ),
                        value: isDark,
                        activeColor: themeGreen,
                        onChanged: (val) {
                          AppSettings.isDarkMode.value = val;
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: borderColor,
                      ),

                      // 3. 高對比度開關
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          '高對比度',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(17),
                            fontWeight: isHighContrast
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          '提升文字清晰度',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(13),
                            color: secondaryTextColor,
                          ),
                        ),
                        value: isHighContrast,
                        activeColor: themeGreen,
                        onChanged: (val) {
                          AppSettings.isHighContrast.value = val;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 分類標題：提醒
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  '提醒',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              ),

              // 每日提醒卡片：開關＋提醒時間
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                ),
                child: Material(
                  // ListTile 的水波紋要畫在 Material 上，否則會被卡片底色蓋住
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          '每日提醒',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(17),
                            fontWeight: isHighContrast
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        subtitle: Text(
                          ReminderService.isSupported
                              ? '每天固定時間提醒您寫日記、玩遊戲'
                              : '網頁版不支援提醒，請在手機 App 設定',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(13),
                            color: secondaryTextColor,
                          ),
                        ),
                        value: _reminder.enabled,
                        activeColor: themeGreen,
                        onChanged:
                            ReminderService.isSupported && !_isUpdatingReminder
                            ? _onReminderToggled
                            : null,
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: borderColor,
                      ),
                      ListTile(
                        enabled:
                            ReminderService.isSupported && _reminder.enabled,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Icon(Icons.alarm_rounded, color: themeGreen),
                        title: Text(
                          '提醒時間',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(17),
                            fontWeight: isHighContrast
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ReminderService.formatTime(_reminder.time),
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(16),
                                fontWeight: FontWeight.w600,
                                color: _reminder.enabled
                                    ? themeGreen
                                    : secondaryTextColor,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                        onTap: _onPickReminderTime,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 分類標題：帳號
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  '帳號',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              ),

              // 帳號設定卡片
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      '登出',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(17),
                        fontWeight: isHighContrast
                            ? FontWeight.w900
                            : FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () => LogoutHelper.confirmAndLogout(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
