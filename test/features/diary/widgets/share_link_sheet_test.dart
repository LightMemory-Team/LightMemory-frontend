// 親友分享連結：分享文字、LINE／Facebook 網址（日記完成頁與動態牆共用）

import 'package:flutter_test/flutter_test.dart';

import 'package:light_memory/features/diary/widgets/share_link_sheet.dart';

void main() {
  const url = 'https://lightmemory.example/share/abc123/';

  group('ShareLinks.buildShareText', () {
    test('有邀請文字時用邀請文字，最後接連結', () {
      expect(
        ShareLinks.buildShareText(
          shareUrl: url,
          inviteText: '玉蘭今天的聲影日記發布囉～',
          title: '菜市場',
          postText: '今天去買菜',
        ),
        '玉蘭今天的聲影日記發布囉～\n$url',
      );
    });

    test('沒有邀請文字時用標題＋內文', () {
      expect(
        ShareLinks.buildShareText(shareUrl: url, title: '菜市場', postText: '今天去買菜'),
        '菜市場\n今天去買菜\n$url',
      );
    });

    test('連標題都沒有時用「聲影日記」', () {
      expect(ShareLinks.buildShareText(shareUrl: url), '聲影日記\n$url');
    });
  });

  test('LINE 用「傳送文字」網址（R/msg/text），不用會跳首頁的 R/share', () {
    final uri = ShareLinks.lineUri('加油 $url');
    expect(uri.toString(), startsWith('https://line.me/R/msg/text/?'));
    expect(Uri.decodeComponent(uri.query), '加油 $url');
  });

  test('Facebook 分享網址帶上編碼後的連結', () {
    final uri = ShareLinks.facebookUri(url);
    expect(uri.host, 'www.facebook.com');
    expect(uri.queryParameters['u'], url);
  });
}
