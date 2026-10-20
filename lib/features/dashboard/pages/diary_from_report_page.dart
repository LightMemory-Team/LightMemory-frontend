import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../diary/pages/diary_home_page.dart';
import '../widgets/dashboard_palette.dart';

/// 週報表點「語言」→「前往遊玩」時開的頁面：直接放聲影日記首頁，
/// 下面加一顆「回到週報表」。
///
/// 聲影日記平常是底部導覽的分頁，頂部列左上角是設定齒輪、沒有返回鍵，
/// 單獨開出來時長輩會找不到回去的路，所以在這裡補一顆大按鈕；
/// 不改聲影日記本身，也不改 main_screen.dart。
class DiaryFromReportPage extends StatelessWidget {
  const DiaryFromReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final palette = DashboardPalette.current();
        return Scaffold(
          backgroundColor: palette.background,
          body: const DiaryHomePage(),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 26),
                  label: Text(
                    '回到週報表',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
