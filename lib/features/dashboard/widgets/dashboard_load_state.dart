import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import 'dashboard_palette.dart';

/// 讀取中／讀不到資料時的畫面，儀表板跟週報表共用。
/// 依長者介面規範不出現「錯誤」「失敗」字樣。
class DashboardLoadState extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;
  final DashboardPalette palette;

  const DashboardLoadState({
    super.key,
    required this.isLoading,
    required this.onRetry,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: palette.primary));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: palette.body),
            const SizedBox(height: 16),
            Text(
              '資料暫時讀不到，請稍後再試一次',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                color: palette.title,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '再試一次',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
