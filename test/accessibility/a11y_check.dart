import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 無障礙檢查工具：在 widget test 裡對「目前畫面」跑 Flutter 內建的四項 guideline。
///
/// 預設只收集、印出報告，不會讓測試失敗（現況有不少違規，先看清單再逐項修）。
/// 要讓違規直接讓測試失敗，加上 `--dart-define=A11Y_STRICT=true`。
///
/// 用法：
/// ```dart
/// final a11y = A11yReport('冰箱盤點');
/// ...
/// await a11y.check(tester, '作答畫面');
/// ...
/// a11y.finish();   // 印出報告；strict 模式下有違規會失敗
/// ```
///
/// 檢查項目：
/// - androidTapTarget：可點擊區 ≥ 48dp
/// - iOSTapTarget：可點擊區 ≥ 44pt
/// - labeledTapTarget：可點擊的東西都有文字標籤（讀屏軟體才讀得出來）
/// - textContrast：文字對比 ≥ 4.5:1（只看文字，不看圖示）
const bool a11yStrict = bool.fromEnvironment('A11Y_STRICT');

class A11yViolation {
  final String screen;
  final String guideline;
  final String reason;

  const A11yViolation(this.screen, this.guideline, this.reason);
}

class A11yReport {
  final String game;
  final List<A11yViolation> violations = [];
  final List<String> checkedScreens = [];

  A11yReport(this.game);

  /// 檢查目前畫面。[screen] 是畫面名稱，會出現在報告裡。
  /// 只會擷取一次當下的畫面，呼叫前請先 pump 到畫面穩定。
  Future<void> check(WidgetTester tester, String screen) async {
    final handle = tester.ensureSemantics();
    try {
      // 語意樹要等下一個 frame 才會建好；剛開啟語意就檢查會拿到空的樹，
      // guideline 會空過而漏報。零時長的 pump 只排一個 frame，不會讓計時器往前走。
      await tester.pump();
      checkedScreens.add(screen);
      final guidelines = <String, AccessibilityGuideline>{
        'androidTapTarget': androidTapTargetGuideline,
        'iOSTapTarget': iOSTapTargetGuideline,
        'labeledTapTarget': labeledTapTargetGuideline,
        'textContrast': textContrastGuideline,
      };
      for (final entry in guidelines.entries) {
        try {
          final result = await entry.value.evaluate(tester);
          if (!result.passed) {
            violations.add(A11yViolation(screen, entry.key, result.reason ?? ''));
          }
        } catch (e) {
          // 個別 guideline 在某些畫面（例如沒有東西可截圖）會丟例外，
          // 記下來但不要讓整個測試中斷
          violations.add(A11yViolation(screen, entry.key, '檢查本身出錯：$e'));
        }
      }
    } finally {
      handle.dispose();
    }
  }

  /// 印出報告，並寫到 build/a11y_report 資料夾。
  /// strict 模式下有違規會讓測試失敗。
  void finish() {
    final buf = StringBuffer()
      ..writeln('===== 無障礙檢查：$game =====')
      ..writeln('檢查過的畫面（${checkedScreens.length}）：${checkedScreens.join('、')}');
    if (violations.isEmpty) {
      buf.writeln('沒有違規');
    } else {
      buf.writeln('違規 ${violations.length} 項：');
      for (final v in violations) {
        final reason = v.reason.replaceAll('\n', ' ');
        buf.writeln('- [${v.screen}] ${v.guideline}: $reason');
      }
    }
    // ignore: avoid_print
    print(buf);
    try {
      final dir = Directory('build/a11y_report')..createSync(recursive: true);
      File('${dir.path}/$game.txt').writeAsStringSync(buf.toString());
    } catch (_) {}
    if (a11yStrict && violations.isNotEmpty) {
      fail('$game 有 ${violations.length} 項無障礙違規（見上方報告）');
    }
  }
}
