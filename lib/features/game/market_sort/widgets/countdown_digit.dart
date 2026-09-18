import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// 全螢幕倒數畫面用的大數字元件，共用元件，3/2/1都用同一份、只換number參數
/// 對應Stitch定案的倒數畫面稿：置中大數字、細線圈框、上方「準備開始」小字
class CountdownDigit extends StatelessWidget {
  final int number;

  const CountdownDigit({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '準備開始',
              style: TextStyle(fontSize: 28, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Container(
              width: 160,
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 1.5),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}