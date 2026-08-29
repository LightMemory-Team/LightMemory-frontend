import 'package:flutter/material.dart';
import '../app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            ],
          ),
        );
      },
    );
  }
}
