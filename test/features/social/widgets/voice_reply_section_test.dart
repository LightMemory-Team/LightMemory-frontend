// 動態牆「語音加油」：讀列表、轉文字、讀取失敗；以及 API 網址與回應解析

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/features/social/models/post_model.dart';
import 'package:light_memory/features/social/services/social_service.dart';
import 'package:light_memory/features/social/widgets/voice_reply_section.dart';

http.Response _json(int status, Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _reply({int id = 12, String text = ''}) => {
  'voice_reply_id': id,
  'nickname': '小玲',
  'audio_url': 'https://example.com/a.webm',
  'duration_sec': 8,
  'transcribed_text': text,
  'created_at': '2026-11-14T10:20:00+08:00',
};

/// 假後端：記下打了哪些網址
class _FakeBackend {
  final List<String> calls = [];
  List<Map<String, dynamic>> replies = [_reply()];
  int listStatus = 200;
  int transcribeStatus = 200;

  MockClient client() => MockClient((req) async {
    calls.add('${req.method} ${req.url.path}');
    if (req.url.path.endsWith('/voice-replies/') && req.method == 'GET') {
      if (listStatus != 200) {
        return _json(listStatus, {
          'success': false,
          'data': null,
          'error': {'code': 'POST_NOT_FOUND', 'message': '找不到這篇日記'},
        });
      }
      return _json(200, {
        'success': true,
        'data': {'items': replies},
        'error': null,
      });
    }
    if (req.url.path.endsWith('/transcribe/')) {
      if (transcribeStatus != 200) {
        return _json(transcribeStatus, {
          'success': false,
          'data': null,
          'error': {
            'code': 'TRANSCRIBE_FAILED',
            'message': '這段語音暫時轉不出文字，可以先直接播放聽聽看',
          },
        });
      }
      return _json(200, {
        'success': true,
        'data': {'voice_reply_id': 12, 'transcribed_text': '阿嬤妳拍得好漂亮，加油！'},
        'error': null,
      });
    }
    return http.Response('{}', 404);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  group('VoiceReplyModel.fromJson', () {
    test('讀暱稱、秒數、還沒轉文字', () {
      final r = VoiceReplyModel.fromJson(_reply());
      expect(r.voiceReplyId, 12);
      expect(r.nickname, '小玲');
      expect(r.senderName, '小玲');
      expect(r.durationSec, 8);
      expect(r.isTranscribed, isFalse);
    });

    test('舊欄位 sender_name 也讀得到；沒有暱稱時顯示「親友」', () {
      expect(VoiceReplyModel.fromJson({'sender_name': '孫女'}).nickname, '孫女');
      expect(VoiceReplyModel.fromJson({}).nickname, '親友');
    });

    test('copyWith 只改轉出來的文字', () {
      final r = VoiceReplyModel.fromJson(_reply()).copyWith(transcribedText: '加油');
      expect(r.isTranscribed, isTrue);
      expect(r.nickname, '小玲');
    });
  });

  test('SocialService：列表與轉文字打對的網址', () async {
    final backend = _FakeBackend();
    await http.runWithClient(() async {
      final service = SocialService();
      final replies = await service.getVoiceReplies(5);
      expect(replies.single.nickname, '小玲');
      final text = await service.transcribeVoiceReply(12);
      expect(text, '阿嬤妳拍得好漂亮，加油！');
    }, backend.client);

    expect(backend.calls, [
      'GET /api/social/posts/5/voice-replies/',
      'POST /api/social/voice-replies/12/transcribe/',
    ]);
  });

  Widget wrap() => const MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: VoiceReplySection(
          postId: 5,
          count: 1,
          titleColor: Colors.black,
          bodyColor: Colors.black54,
          accentColor: Color(0xFF2E6342),
          chipBg: Color(0xFFE3EDE5),
        ),
      ),
    ),
  );

  testWidgets('顯示語音加油，按「轉文字」後顯示文字並隱藏按鈕', (tester) async {
    final backend = _FakeBackend();
    await http.runWithClient(() async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('語音加油（1）'), findsOneWidget);
      expect(find.text('小玲'), findsOneWidget);
      expect(find.textContaining('8 秒'), findsOneWidget);

      await tester.tap(find.text('轉文字'));
      await tester.pumpAndSettle();

      expect(find.text('「阿嬤妳拍得好漂亮，加油！」'), findsOneWidget);
      expect(find.text('轉文字'), findsNothing);
    }, backend.client);
  });

  testWidgets('已經轉過的直接顯示文字，沒有「轉文字」按鈕', (tester) async {
    final backend = _FakeBackend()..replies = [_reply(text: '加油喔')];
    await http.runWithClient(() async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('「加油喔」'), findsOneWidget);
      expect(find.text('轉文字'), findsNothing);
    }, backend.client);
  });

  testWidgets('轉文字失敗：顯示後端訊息，按鈕還在可以再試', (tester) async {
    final backend = _FakeBackend()..transcribeStatus = 502;
    await http.runWithClient(() async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('轉文字'));
      await tester.pumpAndSettle();

      expect(find.text('這段語音暫時轉不出文字，可以先直接播放聽聽看'), findsOneWidget);
      expect(find.text('轉文字'), findsOneWidget);
    }, backend.client);
  });

  testWidgets('讀取失敗：顯示訊息與重新載入', (tester) async {
    final backend = _FakeBackend()..listStatus = 404;
    await http.runWithClient(() async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('重新載入'), findsOneWidget);
    }, backend.client);
  });
}
