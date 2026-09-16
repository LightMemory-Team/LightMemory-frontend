import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'go_to_market_game_page.dart';

class GoToMarketTutorialPage extends StatefulWidget {
  const GoToMarketTutorialPage({super.key});

  @override
  State createState() => _GoToMarketTutorialPageState();
}

class _GoToMarketTutorialPageState extends State {
  // 0: 簡單難度教學, 1: 中等難度教學, 2: 高階難度教學
  int stage = 0;
  final int totalStages = 3;

  // 步驟：stage 0, 1 為 0~2 (共 3 步)；stage 2 為 0~3 (共 4 步)
  int step = 0;

  bool showStageBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _triggerStageBanner();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _triggerStageBanner() {
    setState(() {
      showStageBanner = true;
    });
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          showStageBanner = false;
        });
      }
    });
  }

  String get stageTitle {
    switch (stage) {
      case 0:
        return '簡單難度教學';
      case 1:
        return '中等難度教學';
      case 2:
        return '高階難度教學';
      default:
        return '';
    }
  }

  String get stepBadgeText {
    switch (step) {
      case 0:
        return '第一步';
      case 1:
        return '第二步';
      case 2:
        return '第三步';
      case 3:
        return '第四步';
      default:
        return '';
    }
  }

  String get instructionText {
    if (stage == 0) {
      switch (step) {
        case 0:
          return '注意看！圖案出現在正中間';
        case 1:
          return '剛剛的圖案出現在哪裡？';
        case 2:
          return '請點擊剛剛圖案出現的正中間！';
      }
    } else if (stage == 1) {
      switch (step) {
        case 0:
          return '注意看！圖案會隨機出現在四個角落';
        case 1:
          return '剛剛的圖案出現在哪裡？';
        case 2:
          return '請點擊剛剛圖案出現的角落！';
      }
    } else {
      switch (step) {
        case 0:
          return '記清楚！只需要點擊「目標物」，不要點到「干擾物」喔！';
        case 1:
          return '注意看！請專注記住「目標物」的位置';
        case 2:
          return '剛剛的「目標物」出現在哪裡？';
        case 3:
          return '請點擊剛剛「目標物」的位置，不要點「干擾物」喔！';
      }
    }
    return '';
  }

  bool get canGoPrev => !(stage == 0 && step == 0);

  void _nextStep() {
    AudioService.playClick();
    if (showStageBanner) {
      _bannerTimer?.cancel();
      setState(() {
        showStageBanner = false;
      });
      return;
    }

    int maxStep = (stage == 2) ? 3 : 2;

    setState(() {
      if (step < maxStep) {
        step++;
      } else {
        if (stage < totalStages - 1) {
          stage++;
          step = 0;
          _triggerStageBanner();
        } else {
          _showCompletionDialog();
        }
      }
    });
  }

  void _prevStep() {
    AudioService.playClick();
    if (showStageBanner) {
      _bannerTimer?.cancel();
      setState(() {
        showStageBanner = false;
      });
    }

    setState(() {
      if (step > 0) {
        step--;
      } else if (stage > 0) {
        stage--;
        step = (stage == 2) ? 3 : 2;
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F9F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(36, 32, 36, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Color(0xFF2D5A43),
              ),
              SizedBox(height: 16),
              Text(
                '全難度教學完成！',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5A43),
                ),
              ),
              SizedBox(height: 14),
              Text(
                '您已經學會所有的規則囉！\n接下來共有 20 道題目，準備好挑戰了嗎？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Color(0xFF2C3E35),
                  height: 1.4,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(
            bottom: 28,
            left: 24,
            right: 24,
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2D5A43), width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                AudioService.playClick();
                Navigator.of(dialogContext).pop();
                setState(() {
                  stage = 0;
                  step = 0;
                  _triggerStageBanner();
                });
              },
              child: const Text(
                '再看一次教學',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5A43),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A43),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: () {
                AudioService.playClick();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const GoToMarketGamePage(),
                  ),
                );
              },
              child: const Text(
                '開始挑戰 20 題',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 大魚圖案
  Widget _buildFishImage({double width = 280, double height = 92}) {
    return Image.asset(
      'assets/images/fish.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  // 魚骨頭圖案
  Widget _buildFishBoneImage({double width = 175, double height = 100}) {
    return Image.asset(
      'assets/images/fish_bone.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          size: Size(width, height),
          painter: _FishBonePainter(),
        );
      },
    );
  }

  // 虛線導引框
  Widget _buildUnifiedGuideTarget({
    required bool showFish,
    double boxWidth = 200,
    double boxHeight = 90,
  }) {
    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showFish) _buildFishImage(width: 170, height: 64),
          CustomPaint(
            size: Size(boxWidth, boxHeight),
            painter: _DottedBorderPainter(
              color: const Color(0xFF4C7B5D),
              strokeWidth: 2.6,
              gap: 5.0,
              borderRadius: 16.0,
            ),
          ),
          const Icon(
            Icons.touch_app,
            size: 52,
            color: Color(0xFF1B2C22),
            shadows: [
              Shadow(
                blurRadius: 8.0,
                color: Colors.white,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF2D5A43),
                          size: 34,
                        ),
                        onPressed: () {
                          AudioService.playClick();
                          Navigator.of(context).maybePop();
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '來去菜市場',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5A43),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 右側略過教學按鈕
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: const Color(0xFFE8EFE9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          AudioService.playClick();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const GoToMarketGamePage(),
                            ),
                          );
                        },
                        child: const Text(
                          '略過教學',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5A43),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EFE9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          stageTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5A43),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        '1/20',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A43),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            value: 1 / 20,
                            backgroundColor: Color(0xFFDDE5DF),
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF2D5A43),
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(child: _buildStageContent()),
                  const SizedBox(height: 20),
                  Text(
                    instructionText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2D24),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.chevron_left, size: 26),
                        label: const Text(
                          '上一步',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D5A43),
                          disabledForegroundColor: const Color(0xFFA5B8AC),
                          side: BorderSide(
                            color: canGoPrev
                                ? const Color(0xFF2D5A43)
                                : const Color(0xFFD1DDD5),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: canGoPrev ? _prevStep : null,
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.chevron_right,
                          size: 26,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '下一步',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5A43),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _nextStep,
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (showStageBanner)
              GestureDetector(
                onTap: _nextStep,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 52,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A43),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stageTitle,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '請注意看題目說明與指引',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFFE0EFE6),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    if (stage == 2 && step == 0) {
      return _buildIdentificationCards();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A43),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            stepBadgeText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 700,
          height: 310,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 680,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8775),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 4.0,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8775),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (stage == 0 && step == 0)
                _buildFishImage(width: 280, height: 92),
              if (stage == 0 && step == 2)
                _buildUnifiedGuideTarget(showFish: true),
              if (stage == 1 && step == 0)
                Positioned(
                  top: 15,
                  right: 40,
                  child: _buildFishImage(width: 260, height: 86),
                ),
              if (stage == 1 && step == 2)
                Positioned(
                  top: 20,
                  right: 70,
                  child: _buildUnifiedGuideTarget(showFish: true),
                ),
              if (stage == 2 && step == 1) ...[
                Positioned(
                  top: 15,
                  right: 40,
                  child: _buildFishImage(width: 260, height: 86),
                ),
                Positioned(
                  bottom: 12,
                  left: 60,
                  child: _buildFishBoneImage(width: 165, height: 95),
                ),
              ],
              if (stage == 2 && step == 3)
                Positioned(
                  top: 20,
                  right: 70,
                  child: _buildUnifiedGuideTarget(showFish: true),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 260,
          height: 310,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '目標物',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5A43),
                  ),
                ),
              ),
              _buildFishImage(width: 230, height: 85),
              const Text(
                '請記住它！',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6E7E75),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Container(
          width: 260,
          height: 310,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEBEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '干擾物',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC75454),
                  ),
                ),
              ),
              _buildFishBoneImage(width: 175, height: 95),
              const Text(
                '請忽略它！',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6E7E75),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2.6,
    this.gap = 5.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double length = draw ? 7.0 : gap;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FishBonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.2);
    canvas.rotate(-0.32);

    final Path headPath = Path()
      ..moveTo(0, 26)
      ..lineTo(36, 0)
      ..lineTo(36, 52)
      ..close();
    canvas.drawPath(headPath, strokePaint);
    canvas.drawCircle(const Offset(24, 20), 4.0, fillPaint);

    canvas.drawLine(const Offset(36, 26), const Offset(110, 26), strokePaint);

    for (int i = 0; i < 4; i++) {
      double x = 48.0 + (i * 14.0);
      double h = 18.0 - (i * 2.0);
      canvas.drawLine(Offset(x, 26 - h), Offset(x - 4, 26 + h), strokePaint);
    }

    final Path tailPath = Path()
      ..moveTo(110, 26)
      ..lineTo(132, 9)
      ..lineTo(124, 26)
      ..lineTo(132, 43)
      ..close();
    canvas.drawPath(tailPath, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
