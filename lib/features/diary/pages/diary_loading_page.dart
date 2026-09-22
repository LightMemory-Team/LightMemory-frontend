import 'package:flutter/material.dart';
import '../models/diary_model.dart';
import '../services/diary_service.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app_settings.dart';

class DiaryLoadingPage extends StatefulWidget {
  final int diaryId;

  const DiaryLoadingPage({super.key, required this.diaryId});

  @override
  State<DiaryLoadingPage> createState() => _DiaryLoadingPageState();
}

class _DiaryLoadingPageState extends State<DiaryLoadingPage>
    with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  late final AnimationController _gearController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _finalize();
  }

  @override
  void dispose() {
    _gearController.dispose();
    super.dispose();
  }

  Future<void> _finalize() async {
    setState(() => _hasError = false);
    try {
      final diary = await _diaryService.finalizeDiary(widget.diaryId);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.voiceDiaryFinish,
        arguments: diary,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 跟比賽版一樣，這是一個滿版色塊的 loading 畫面，不用跟隨深色模式，
    // 但文字大小仍套用使用者的字級偏好，維持無障礙一致性。
    return Scaffold(
      backgroundColor: const Color(0xFF6B9A7A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 90,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 52),
                if (!_hasError) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _gearController,
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '語言認知計算中請稍後',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: AppSettings.scaleFont(20),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '恭喜完成！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w200,
                      fontSize: AppSettings.scaleFont(15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '記錄也是改變生命力量的一部分。為你的持之以恆鼓掌！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.7,
                      fontSize: AppSettings.scaleFont(12),
                    ),
                  ),
                ] else ...[
                  Text(
                    '生成日記失敗，請再試一次',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSettings.scaleFont(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _finalize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                    ),
                    child: const Text('重試'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}