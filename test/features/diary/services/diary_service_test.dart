import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_memory/core/network/api_response.dart';
import 'package:light_memory/features/diary/services/diary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 後端 F7：回覆日記驗證 round_index。
// 400 INVALID_ROUND_INDEX、409 ROUND_ALREADY_ANSWERED 都要能被前端正確處理。

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<T> _withMock<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

XFile _audio() => XFile.fromData(
      utf8.encode('fake-audio'),
      name: 'a.webm',
      mimeType: 'audio/webm',
    );

Map<String, dynamic> _conflict() => {
      'error': {
        'code': 'ROUND_ALREADY_ANSWERED',
        'message': '這一輪已經回答過了',
      },
    };

/// GET diary/<id>/ 的回應：[answeredRounds] 輪已回答，
/// 還沒問完就帶 pending_question。
Map<String, dynamic> _detail({
  required int answeredRounds,
  String? pendingQuestion,
  String status = 'processing',
}) =>
    {
      'data': {
        'diary_id': 7,
        'date': '2026-11-09',
        'created_at': '2026-11-09T08:00:00+08:00',
        'status': status,
        'photo_url': null,
        'first_question': '今天做了什麼？',
        'replies': [
          for (var i = 1; i <= answeredRounds; i++)
            {
              'round_index': i,
              'question': '問題$i',
              'transcript': '第$i輪的回答',
              'audio_url': 'https://example.com/r$i.webm?sig=x',
              'is_skipped': false,
            },
        ],
        'pending_question': pendingQuestion,
        'reply_count': answeredRounds,
        'is_finalizable': answeredRounds >= 2,
        'is_done': status == 'done',
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  group('submitReply 成功', () {
    test('201 照常解析，只打一次 replies/', () async {
      final calls = <String>[];
      final result = await _withMock(
        (request) async {
          calls.add('${request.method} ${request.url.path}');
          return _json({
            'data': {
              'round_index': 1,
              'transcript': '今天去散步',
              'audio_url': 'https://example.com/a.webm?sig=1',
              'ai_reply': '有遇到誰嗎？',
              'reply_count': 1,
              'is_finalizable': false,
              'is_done': false,
            },
          }, 201);
        },
        () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 1),
      );

      expect(calls, ['POST /api/diary/7/replies/']);
      expect(result.transcript, '今天去散步');
      expect(result.aiReply, '有遇到誰嗎？');
      expect(result.isDone, isFalse);
    });
  });

  group('submitReply 400 INVALID_ROUND_INDEX', () {
    test('丟 ApiException 並保留 code 與 HTTP 狀態碼', () async {
      final calls = <String>[];
      await expectLater(
        _withMock(
          (request) async {
            calls.add('${request.method} ${request.url.path}');
            return _json({
              'error': {
                'code': 'INVALID_ROUND_INDEX',
                'message': 'round_index 必須是 1～4 的整數',
              },
            }, 400);
          },
          () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 9),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'INVALID_ROUND_INDEX')
              .having((e) => e.message, 'message', contains('1～4')),
        ),
      );
      // 這種錯誤不是重試能解決的，不應該去抓詳情
      expect(calls, ['POST /api/diary/7/replies/']);
    });
  });

  group('submitReply 409 ROUND_ALREADY_ANSWERED', () {
    test('改抓日記詳情，把已回答的那一輪還原成成功結果', () async {
      final calls = <String>[];
      final result = await _withMock(
        (request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.method == 'POST') return _json(_conflict(), 409);
          return _json(_detail(answeredRounds: 2, pendingQuestion: '第三題'));
        },
        () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 2),
      );

      expect(calls, ['POST /api/diary/7/replies/', 'GET /api/diary/7/']);
      expect(result.roundIndex, 2);
      expect(result.transcript, '第2輪的回答');
      expect(result.audioUrl, 'https://example.com/r2.webm?sig=x');
      expect(result.aiReply, '第三題');
      expect(result.replyCount, 2);
      expect(result.isFinalizable, isTrue);
      expect(result.isDone, isFalse);
    });

    test('第 4 輪重送：isDone 是 true，沒有下一題', () async {
      final result = await _withMock(
        (request) async {
          if (request.method == 'POST') return _json(_conflict(), 409);
          // 4 輪答完但還沒 finalize：詳情的 is_done 是 false，要靠回覆數判斷
          return _json(_detail(answeredRounds: 4, pendingQuestion: null));
        },
        () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 4),
      );

      expect(result.isDone, isTrue);
      expect(result.aiReply, isNull);
      expect(result.replyCount, 4);
    });

    test('詳情裡找不到那一輪（不應發生）：把原本的 409 丟出去', () async {
      await expectLater(
        _withMock(
          (request) async {
            if (request.method == 'POST') return _json(_conflict(), 409);
            return _json(_detail(answeredRounds: 1, pendingQuestion: '第二題'));
          },
          () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 3),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.code, 'code', 'ROUND_ALREADY_ANSWERED'),
        ),
      );
    });
  });

  group('其他錯誤', () {
    test('DIARY_ALREADY_FINALIZED 等既有錯誤碼一樣帶 code，且不會去抓詳情', () async {
      final calls = <String>[];
      await expectLater(
        _withMock(
          (request) async {
            calls.add(request.method);
            return _json({
              'error': {
                'code': 'DIARY_ALREADY_FINALIZED',
                'message': '這篇日記已經完成了',
              },
            }, 400);
          },
          () => DiaryService().submitReply(7, audio: _audio(), roundIndex: 1),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'DIARY_ALREADY_FINALIZED')
              .having((e) => e.toString(), 'toString', '這篇日記已經完成了'),
        ),
      );
      expect(calls, ['POST']);
    });

    test('token 過期的 {"detail": ...} 格式仍取得訊息與 401', () async {
      await expectLater(
        _withMock(
          (request) async => _json({'detail': 'Token is expired'}, 401),
          () => DiaryService().finalizeDiary(7),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Token is expired'),
        ),
      );
    });
  });

  group('getDiaryDetail', () {
    test('GET diary/<id>/，photo_url 為 null 也能解析', () async {
      final diary = await _withMock(
        (request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/diary/7/');
          return _json(_detail(answeredRounds: 1, pendingQuestion: '第二題'));
        },
        () => DiaryService().getDiaryDetail(7),
      );

      expect(diary.diaryId, 7);
      expect(diary.photoUrl, '');
      expect(diary.replies.single.transcript, '第1輪的回答');
      expect(diary.pendingQuestion, '第二題');
    });
  });

  group('finalizeDiary', () {
    test('已完成再送回 200（原本是 201）也視為成功', () async {
      final diary = await _withMock(
        (request) async => _json(
          _detail(answeredRounds: 4, status: 'done'),
          200,
        ),
        () => DiaryService().finalizeDiary(7),
      );
      expect(diary.diaryId, 7);
    });
  });
  // 後端「日記上傳限制」：靠副檔名或 Content-Type 判斷是不是圖片。
  // Flutter Web 的檔名常沒有副檔名，要明確帶 Content-Type。
  group('photoMediaType', () {
    XFile photo(String name, {String? mime}) =>
        // VM 上 XFile.name 取的是 path 的檔名（name 參數只有 Web 才用），
        // 所以兩個都帶，行為與手機、Web 一致。
        XFile.fromData(utf8.encode('x'), name: name, path: name, mimeType: mime);

    test('用選圖器給的 mimeType', () {
      expect(photoMediaType(photo('blob', mime: 'image/png')).mimeType, 'image/png');
    });

    test('mimeType 大小寫與空白會正規化', () {
      expect(
        photoMediaType(photo('blob', mime: ' IMAGE/WebP ')).mimeType,
        'image/webp',
      );
    });

    test('mimeType 不是 image/* 時改看副檔名', () {
      expect(
        photoMediaType(photo('a.png', mime: 'application/octet-stream')).mimeType,
        'image/png',
      );
    });

    test('沒有 mimeType：依副檔名（含大寫）', () {
      expect(photoMediaType(photo('a.PNG')).mimeType, 'image/png');
      expect(photoMediaType(photo('a.webp')).mimeType, 'image/webp');
      expect(photoMediaType(photo('a.heic')).mimeType, 'image/heic');
      expect(photoMediaType(photo('a.heif')).mimeType, 'image/heif');
      expect(photoMediaType(photo('a.jpg')).mimeType, 'image/jpeg');
      expect(photoMediaType(photo('a.jpeg')).mimeType, 'image/jpeg');
    });

    test('沒有 mimeType 也沒有副檔名（Web）：當 JPEG', () {
      expect(photoMediaType(photo('f4b2c9d0-1e')).mimeType, 'image/jpeg');
      expect(photoMediaType(photo('')).mimeType, 'image/jpeg');
    });

    test('mimeType 只有「image/」沒有子類型：不採用，改看副檔名', () {
      expect(photoMediaType(photo('a.png', mime: 'image/')).mimeType, 'image/png');
    });
  });

  group('createDiary 上傳照片', () {
    test('檔名沒有副檔名也會在 multipart 帶 Content-Type', () async {
      late http.Request sent;
      await _withMock(
        (request) async {
          sent = request;
          return _json(_detail(answeredRounds: 0, pendingQuestion: '第一題'), 201);
        },
        () => DiaryService().createDiary(
          XFile.fromData(utf8.encode('img'), name: 'blob-no-ext', mimeType: 'image/png'),
        ),
      );

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/diary/');
      expect(sent.body.toLowerCase(), contains('content-type: image/png'));
      expect(sent.body, contains('name="photo"'));
    });

    test('沒有 mimeType 也沒副檔名：帶 image/jpeg', () async {
      late http.Request sent;
      await _withMock(
        (request) async {
          sent = request;
          return _json(_detail(answeredRounds: 0, pendingQuestion: '第一題'), 201);
        },
        () => DiaryService().createDiary(
          XFile.fromData(utf8.encode('img'), name: 'blob-no-ext'),
        ),
      );
      expect(sent.body.toLowerCase(), contains('content-type: image/jpeg'));
    });

    test('後端 400 IMAGE_TOO_LARGE：丟 ApiException，帶 code 與中文訊息', () async {
      await expectLater(
        _withMock(
          (request) async => _json({
            'error': {
              'code': 'IMAGE_TOO_LARGE',
              'message': '這張照片太大了（不能超過 10MB），換一張試試看吧',
            },
          }, 400),
          () => DiaryService().createDiary(
            XFile.fromData(utf8.encode('img'), name: 'a.jpg'),
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'IMAGE_TOO_LARGE')
              .having((e) => e.message, 'message', contains('10MB')),
        ),
      );
    });
  });

  group('photoUploadErrorMessage', () {
    test('有錯誤碼的 4xx：直接顯示後端的中文訊息', () {
      final e = ApiException(
        statusCode: 400,
        code: 'IMAGE_TOO_LARGE',
        message: '這張照片太大了（不能超過 10MB），換一張試試看吧',
      );
      expect(photoUploadErrorMessage(e), '這張照片太大了（不能超過 10MB），換一張試試看吧');
    });

    test('INVALID_IMAGE 也直接顯示', () {
      final e = ApiException(
        statusCode: 400,
        code: 'INVALID_IMAGE',
        message: '這個檔案不是照片，請重新選擇',
      );
      expect(photoUploadErrorMessage(e), '這個檔案不是照片，請重新選擇');
    });

    test('5xx 或沒有錯誤碼：維持原本的「照片儲存失敗」', () {
      expect(
        photoUploadErrorMessage(
          ApiException(statusCode: 500, code: 'SERVER_ERROR', message: 'boom'),
        ),
        '照片儲存失敗，請再試一次',
      );
      expect(
        photoUploadErrorMessage(ApiException(statusCode: 502, message: '發生錯誤（502）')),
        '照片儲存失敗，請再試一次',
      );
    });

    test('連不上後端：顯示連線失敗', () {
      expect(
        photoUploadErrorMessage(http.ClientException('Failed to fetch')),
        '連線失敗，請檢查網路後再試一次',
      );
    });

    test('沒預期到的錯誤：照片儲存失敗', () {
      expect(photoUploadErrorMessage(StateError('x')), '照片儲存失敗，請再試一次');
    });
  });
}
