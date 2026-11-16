import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/home/models/notification_model.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('讀取後端欄位 id、message、notification_type、target_url、is_read、created_at', () {
      final n = AppNotification.fromJson({
        'id': 12,
        'message': '小明在你的「書法練習」留言',
        'notification_type': 'comment',
        'target_url': '/posts/7/',
        'is_read': true,
        'created_at': '2026-11-02T02:30:00Z',
      });

      expect(n.id, 12);
      expect(n.message, '小明在你的「書法練習」留言');
      expect(n.type, 'comment');
      expect(n.targetUrl, '/posts/7/');
      expect(n.isRead, isTrue);
      // 程式會轉成本地時區，所以比較是不是同一個時刻，不比較時區
      expect(n.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 2, 2, 30)), isTrue);
    });

    test('欄位缺少時用預設值：未讀、空字串、沒有時間', () {
      final n = AppNotification.fromJson({'id': 1});

      expect(n.message, '');
      expect(n.type, '');
      expect(n.targetUrl, '');
      expect(n.isRead, isFalse);
      expect(n.createdAt, isNull);
    });

    test('id 是字串數字也能讀；null 或亂字串變成 0', () {
      expect(AppNotification.fromJson({'id': '5'}).id, 5);
      expect(AppNotification.fromJson({'id': null}).id, 0);
      expect(AppNotification.fromJson({'id': 'abc'}).id, 0);
    });

    test('created_at 格式錯誤時為 null，不會丟例外', () {
      expect(AppNotification.fromJson({'id': 1, 'created_at': 'not-a-date'}).createdAt, isNull);
    });
  });

  test('created_at 帶時區（+08:00）也能正確解析', () {
    final n = AppNotification.fromJson({'id': 1, 'created_at': '2026-11-02T09:00:00+08:00'});
    expect(n.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 2, 1)), isTrue);
  });

  test('只有 comment、voice_reply 類型會跳轉到貼文', () {
    for (final type in ['like', 'family_reply', 'diary_reminder', 'game_reminder', '']) {
      expect(AppNotification.fromJson({'id': 1, 'notification_type': type}).opensPost, isFalse, reason: type);
    }
    expect(AppNotification.fromJson({'id': 1, 'notification_type': 'comment'}).opensPost, isTrue);
    expect(AppNotification.fromJson({'id': 1, 'notification_type': 'voice_reply'}).opensPost, isTrue);
  });

  test('copyWith 只改已讀狀態，其他欄位不變', () {
    final n = AppNotification.fromJson({'id': 3, 'message': 'hi', 'target_url': '/x/1/'});
    final read = n.copyWith(isRead: true);

    expect(read.isRead, isTrue);
    expect(read.id, 3);
    expect(read.message, 'hi');
    expect(read.targetUrl, '/x/1/');
  });
}
