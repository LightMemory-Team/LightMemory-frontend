import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'features/auth/pages/identity_select_page.dart';
import 'features/diary/pages/diary_upload_page.dart';
import 'features/diary/pages/diary_chat_page.dart';
import 'core/constants/route_constants.dart';
import 'screens/market_sort_game_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '憶智防線',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.gameMarketSort:
            return MaterialPageRoute(
              builder: (_) => const MarketSortGameScreen(),
            );
          case AppRoutes.voiceDiaryUpload:
            return MaterialPageRoute(builder: (_) => const DiaryUploadPage());
          case AppRoutes.voiceDiaryChat:
            final diaryId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => DiaryChatPage(diaryId: diaryId),
            );
          // voiceDiaryLoading、voiceDiaryFinish
          // 等做到對應頁面時會再補進這裡
          default:
            return null;
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}