// 動態牆貼文卡片的「分享」按鈕：自己的貼文才有，點了開分享面板

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:light_memory/features/social/models/post_model.dart';
import 'package:light_memory/features/social/widgets/post_card.dart';

const _url = 'https://lightmemory.example/share/abc123/';

PostModel _post({String? shareUrl = _url, bool? isShareEnabled = true}) =>
    PostModel.fromJson({
      'post_id': 1,
      'diary_id': 9,
      'is_mine': true,
      'title': '菜市場',
      'photo_url': '',
      'post_text': '今天去買菜',
      'date': '2026-11-14',
      'posted_at': '2026-11-14T10:00:00+08:00',
      'comment_count': 2,
      'share_url': shareUrl,
      'is_share_enabled': isShareEnabled,
      'invite_text': '玉蘭今天的聲影日記發布囉～',
    });

Future<void> _pump(WidgetTester tester, PostModel post) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ListView(children: [PostCard(post: post)])),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('自己的貼文有分享連結：顯示「分享」，點了開面板', (tester) async {
    await _pump(tester, _post());

    expect(find.text('分享'), findsOneWidget);

    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();

    expect(find.text('分享給親友'), findsOneWidget);
    expect(find.text('傳到 LINE'), findsOneWidget);
    expect(find.text('分享到 Facebook'), findsOneWidget);
    expect(find.text('複製連結'), findsOneWidget);
  });

  testWidgets('複製連結：把分享連結放進剪貼簿並提示', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await _pump(tester, _post());
    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('複製連結'));
    await tester.pumpAndSettle();

    expect(copied, _url);
    expect(find.text('連結已複製，可以貼到 LINE 或訊息裡'), findsOneWidget);
    // 面板已關閉
    expect(find.text('分享給親友'), findsNothing);
  });

  testWidgets('沒有分享連結（別人的貼文）不顯示「分享」', (tester) async {
    await _pump(tester, _post(shareUrl: null, isShareEnabled: null));
    expect(find.text('分享'), findsNothing);
  });

  testWidgets('分享已關閉不顯示「分享」', (tester) async {
    await _pump(tester, _post(isShareEnabled: false));
    expect(find.text('分享'), findsNothing);
  });
}
