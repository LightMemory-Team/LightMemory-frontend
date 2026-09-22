import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/diary_service.dart';
import '../../../theme/app_theme.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app_settings.dart';
import '../../home/widgets/top_bar.dart';

class DiaryUploadPage extends StatefulWidget {
  const DiaryUploadPage({super.key});

  @override
  State<DiaryUploadPage> createState() => _DiaryUploadPageState();
}

class _DiaryUploadPageState extends State<DiaryUploadPage> {
  final DiaryService _diaryService = DiaryService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedPhoto;
  bool _isSubmitting = false;

  static const double _zoneRadius = 20;
  static const double _zoneHeight = 240;

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (photo == null) return;
    setState(() => _selectedPhoto = photo);
  }

  void _removePhoto() {
    setState(() => _selectedPhoto = null);
  }

  void _showSourcePicker() {
    if (_selectedPhoto != null || _isSubmitting) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppSettings.isDarkMode.value
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = AppSettings.isDarkMode.value;
        final itemColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: itemColor),
                title: Text('拍照', style: TextStyle(color: itemColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: itemColor),
                title: Text('從相簿選擇', style: TextStyle(color: itemColor)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    if (_selectedPhoto == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final diary = await _diaryService.createDiary(_selectedPhoto!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('照片已儲存！'),
            ],
          ),
          backgroundColor: AppTheme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 900),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.voiceDiaryChat,
        arguments: diary.diaryId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('照片儲存失敗，請再試一次'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorScheme;
    final hasPhoto = _selectedPhoto != null;

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
        final zoneBg = isDark
            ? const Color(0xFF1E1E1E)
            : colorScheme.surfaceContainerLow;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final subtitleColor = isDark
            ? const Color(0xFFCCCCCC)
            : colorScheme.onSurfaceVariant;
        final disabledBg = isDark
            ? const Color(0xFF333333)
            : colorScheme.surfaceContainerHigh;
        final disabledText = isDark
            ? const Color(0xFF888888)
            : colorScheme.onSurfaceVariant;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(title: '聲影日記', showBackButton: true),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '上傳今日照片',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontTitle),
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '為您的日記添加一張精彩的回憶',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: _zoneHeight,
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _showSourcePicker,
                      child: hasPhoto
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _zoneRadius,
                                  ),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedPhoto!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_selectedPhoto!.path),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: Colors.black54,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _isSubmitting
                                          ? null
                                          : _removePhoto,
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : CustomPaint(
                              painter: _DashedBorderPainter(
                                color: colorScheme.primary.withOpacity(0.5),
                                radius: _zoneRadius,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: zoneBg,
                                  borderRadius: BorderRadius.circular(
                                    _zoneRadius,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: subtitleColor,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '點擊新增照片',
                                        style: TextStyle(
                                          fontSize: AppSettings.scaleFont(
                                            AppTheme.fontBody,
                                          ),
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: !hasPhoto || _isSubmitting
                          ? null
                          : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: disabledBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_outlined,
                                  size: 20,
                                  color: hasPhoto
                                      ? Colors.white
                                      : disabledText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '保存照片',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppSettings.scaleFont(16),
                                    color: hasPhoto
                                        ? Colors.white
                                        : disabledText,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                      ),
                      child: Text(
                        '返回',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSettings.scaleFont(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashGap = 4,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashWidth != oldDelegate.dashWidth ||
        dashGap != oldDelegate.dashGap ||
        radius != oldDelegate.radius;
  }
}