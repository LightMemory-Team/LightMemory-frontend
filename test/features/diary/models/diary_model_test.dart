import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/diary/models/diary_model.dart';

// 後端 F5：日記照片改成簽名網址，簽名失敗時 photo_url 會是 null。
// 這些測試確認 null 不會讓整個月曆／日記詳情 parse 失敗。

Map<String, dynamic> _summaryJson({Object? photoUrl}) => {
      'diary_id': 1,
      'date': '2026-11-09',
      'title': '散步',
      'photo_url': photoUrl,
      'post_text': '今天去公園走走',
      'created_at': '2026-11-09T08:00:00+08:00',
    };

Map<String, dynamic> _detailJson({Object? photoUrl}) => {
      'diary_id': 1,
      'date': '2026-11-09',
      'created_at': '2026-11-09T08:00:00+08:00',
      'status': 'processing',
      'photo_url': photoUrl,
    };

void main() {
  group('DiarySummaryModel.photoUrl', () {
    test('簽名失敗（null）時不丟例外，photoUrl 是空字串', () {
      final model = DiarySummaryModel.fromJson(_summaryJson(photoUrl: null));
      expect(model.photoUrl, '');
    });

    test('簽名網址與舊的完整網址原樣保留', () {
      const signed =
          'https://storage.googleapis.com/b/voice-diary/images/a.jpg?X-Goog-Signature=abc';
      expect(
        DiarySummaryModel.fromJson(_summaryJson(photoUrl: signed)).photoUrl,
        signed,
      );
    });
  });

  group('DiaryModel.photoUrl', () {
    test('簽名失敗（null）時不丟例外，photoUrl 是空字串', () {
      final model = DiaryModel.fromJson(_detailJson(photoUrl: null));
      expect(model.photoUrl, '');
      expect(model.diaryId, 1);
    });

    test('有網址時原樣保留', () {
      final model = DiaryModel.fromJson(
        _detailJson(photoUrl: 'https://example.com/a.jpg?sig=1'),
      );
      expect(model.photoUrl, 'https://example.com/a.jpg?sig=1');
    });
  });

  group('DiaryReviewItem', () {
    test('photo_url、audio_url 都是 null 時不丟例外，audioUrl 為 null', () {
      final item = DiaryReviewItem.fromJson({
        'diary_id': 2,
        'date': '2026-11-08',
        'title': '昨天',
        'photo_url': null,
        'audio_url': null,
        'post_text': '',
      });
      expect(item.photoUrl, '');
      expect(item.audioUrl, isNull);
    });
  });
}
