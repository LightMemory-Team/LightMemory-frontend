import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../models/post_model.dart';

/// 社群動態與語音加油資料服務
///
/// 動態牆（S-2、S-8、S-11、S-13、S-14）：欣紜，已串接真實後端（筠淇）
/// 分享、語音加油（S-1、S-5、S-6、S-7）：分享組（Wen），目前仍是 mock
class SocialService {
  // ============================================================
  // 假資料開關
  //
  // false：呼叫真實後端（正式使用）
  // true ：使用下方的假資料（後端沒開、想單純看畫面時暫時改成 true）
  // ============================================================

  static const bool useMockWall = false;

  static const Duration _timeout = Duration(seconds: 15);

  // ============================================================
  // 共用：送出請求與解析回應
  //
  // 動態牆 API 成功時回傳 {"data": ...}，沒有 success 欄位，
  // 所以不能用遊戲用的 parseEnvelope，改看 HTTP 狀態碼判斷成功與否；
  // 失敗時沿用 api_response.dart 的 parseApiError 解析 {"error": {code, message}}。
  // ============================================================

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConstants.serverUrl}$path')
        .replace(queryParameters: query);
  }

  /// 成功回傳 data 那一層；204（沒有內容）回傳 null；失敗丟出 ApiException
  dynamic _handleResponse(http.Response response) {
    final int status = response.statusCode;

    if (status == 204) return null;

    // 用 bodyBytes 解碼，避免中文變亂碼
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (status >= 200 && status < 300) {
      return json?['data'];
    }

    debugPrint('❌ 動態牆 API 失敗（$status）：${utf8.decode(response.bodyBytes)}');

    throw json != null
        ? parseApiError(json, status)
        : ApiException(statusCode: status, message: '發生錯誤（$status）');
  }

  // ============================================================
  // 動態牆（欣紜）
  // ============================================================

  /// S-2：動態牆列表（所有人的貼文，依分享時間由新到舊）
  Future<List<PostModel>> getPosts({int page = 1, int pageSize = 20}) async {
    if (useMockWall) return _mockGetPosts(page: page);

    final response = await http
        .get(
          _uri('/api/social/posts/', {
            'page': '$page',
            'page_size': '$pageSize',
          }),
          headers: await authHeaders(),
        )
        .timeout(_timeout);

    final data = _handleResponse(response);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }

  /// S-11：單則貼文詳情（之後從通知點進來用）
  Future<PostModel> getPost(int postId) async {
    if (useMockWall) return _mockGetPost(postId);

    final response = await http
        .get(_uri('/api/social/posts/$postId/'), headers: await authHeaders())
        .timeout(_timeout);

    return PostModel.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  /// S-8：按讚（like: true）／取消按讚（like: false）
  ///
  /// 回傳更新後的貼文，畫面直接用回傳的 likeCount、isLiked 更新。
  Future<PostModel> toggleLike(int postId, {required bool like}) async {
    if (useMockWall) return _mockToggleLike(postId, like: like);

    final uri = _uri('/api/social/posts/$postId/like/');
    final headers = await authHeaders();

    final response = like
        ? await http.post(uri, headers: headers).timeout(_timeout)
        : await http.delete(uri, headers: headers).timeout(_timeout);

    return PostModel.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  /// S-13：留言列表（依留言時間由舊到新）
  Future<List<CommentModel>> getComments(
    int postId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    if (useMockWall) return _mockGetComments(postId, page: page);

    final response = await http
        .get(
          _uri('/api/social/posts/$postId/comments/', {
            'page': '$page',
            'page_size': '$pageSize',
          }),
          headers: await authHeaders(),
        )
        .timeout(_timeout);

    final data = _handleResponse(response);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(CommentModel.fromJson)
        .toList();
  }

  /// S-14：新增文字留言（1～200 字）
  Future<CommentModel> submitTextComment(int postId, String text) async {
    if (useMockWall) return _mockSubmitTextComment(postId, text);

    final response = await http
        .post(
          _uri('/api/social/posts/$postId/comments/'),
          headers: await authHeaders(),
          body: jsonEncode({'text': text.trim()}),
        )
        .timeout(_timeout);

    return CommentModel.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  // ============================================================
  // 動態牆假資料（useMockWall = true 時才會用到）
  // ============================================================

  static final List<Map<String, dynamic>> _mockPosts = [
    {
      'post_id': 8,
      'post_type': 'diary',
      'diary_id': 31,
      'author': {'user_id': 5, 'display_name': '林奶奶', 'avatar_url': null},
      'is_mine': false,
      'title': '花燈圈圈樂 ✨',
      'photo_url': 'https://picsum.photos/seed/30/400/300',
      'post_text': '這個週末跟朋友去逛花燈，玩得很開心。',
      'hashtags': ['#花燈', '#朋友聚會', '#長者生活'],
      'category': 'entertainment',
      'date': '2026-10-11',
      'posted_at': '2026-10-11T09:00:00+08:00',
      'like_count': 1,
      'is_liked': false,
      'comment_count': 2,
      'voice_reply_count': 0,
      'share_url': null,
      'is_share_enabled': null,
      'invite_text': '',
      'suggested_replies': ['花燈一定很漂亮吧！', '看起來好熱鬧，下次帶我去～'],
    },
    {
      'post_id': 7,
      'post_type': 'diary',
      'diary_id': 29,
      'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
      'is_mine': true,
      'title': '早晨公園散步 🌳',
      'photo_url': 'https://picsum.photos/seed/41/400/300',
      'post_text': '今天早上去公園散步，遇到好多一起運動的老朋友，空氣很好。',
      'hashtags': ['#散步', '#公園', '#運動'],
      'category': 'health',
      'date': '2026-10-10',
      'posted_at': '2026-10-10T07:30:00+08:00',
      'like_count': 3,
      'is_liked': false,
      'comment_count': 1,
      'voice_reply_count': 0,
      'share_url': 'https://example.com/share/Ab12Cd34Ef56Gh78Ij90Kl/',
      'is_share_enabled': true,
      'invite_text': '今天去公園散步，點進來看看吧！',
      'suggested_replies': ['公園空氣一定很好！', '下次一起去走走～'],
    },
    {
      'post_id': 6,
      'post_type': 'diary',
      'diary_id': 27,
      'author': {'user_id': 8, 'display_name': '陳爺爺', 'avatar_url': null},
      'is_mine': false,
      'title': '孫子來家裡玩 🎈',
      'photo_url': 'https://picsum.photos/seed/52/400/300',
      'post_text': '孫子放假來家裡玩，一起包水餃，雖然形狀歪歪的，但吃起來特別香。',
      'hashtags': ['#家人', '#包水餃', '#天倫之樂'],
      'category': 'family',
      'date': '2026-10-08',
      'posted_at': '2026-10-08T18:20:00+08:00',
      'like_count': 5,
      'is_liked': true,
      'comment_count': 0,
      'voice_reply_count': 0,
      'share_url': null,
      'is_share_enabled': null,
      'invite_text': '',
      'suggested_replies': ['水餃看起來好好吃！', '跟孫子一起真溫馨～'],
    },
  ];

  static final Map<int, List<Map<String, dynamic>>> _mockComments = {
    8: [
      {
        'comment_id': 1,
        'sender_name': '陳爺爺',
        'author': {'user_id': 8, 'display_name': '陳爺爺', 'avatar_url': null},
        'is_mine': false,
        'text': '花燈好漂亮！',
        'created_at': '2026-10-11T10:00:00+08:00',
      },
      {
        'comment_id': 2,
        'sender_name': '我',
        'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
        'is_mine': true,
        'text': '看起來好熱鬧，下次一起去～',
        'created_at': '2026-10-11T11:30:00+08:00',
      },
    ],
    7: [
      {
        'comment_id': 3,
        'sender_name': '林奶奶',
        'author': {'user_id': 5, 'display_name': '林奶奶', 'avatar_url': null},
        'is_mine': false,
        'text': '早上散步對身體很好喔！',
        'created_at': '2026-10-10T09:00:00+08:00',
      },
    ],
    6: [],
  };

  static int _nextCommentId = 100;

  Map<String, dynamic> _findMockPost(int postId) {
    return _mockPosts.firstWhere(
      (post) => post['post_id'] == postId,
      orElse: () => throw Exception('找不到這則貼文'),
    );
  }

  Future<List<PostModel>> _mockGetPosts({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (page > 1) return [];
    return _mockPosts.map(PostModel.fromJson).toList();
  }

  Future<PostModel> _mockGetPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PostModel.fromJson(_findMockPost(postId));
  }

  Future<PostModel> _mockToggleLike(int postId, {required bool like}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final post = _findMockPost(postId);
    final bool wasLiked = post['is_liked'] == true;

    if (like && !wasLiked) {
      post['is_liked'] = true;
      post['like_count'] = (post['like_count'] as int) + 1;
    } else if (!like && wasLiked) {
      post['is_liked'] = false;
      post['like_count'] = (post['like_count'] as int) - 1;
    }

    return PostModel.fromJson(post);
  }

  Future<List<CommentModel>> _mockGetComments(int postId, {int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _findMockPost(postId);
    if (page > 1) return [];
    final comments = _mockComments[postId] ?? [];
    return comments.map(CommentModel.fromJson).toList();
  }

  Future<CommentModel> _mockSubmitTextComment(int postId, String text) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final String trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw Exception('留言不可為空，且不超過 200 字');
    }

    final post = _findMockPost(postId);

    final Map<String, dynamic> comment = {
      'comment_id': _nextCommentId++,
      'sender_name': '我',
      'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
      'is_mine': true,
      'text': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    };

    _mockComments.putIfAbsent(postId, () => []).add(comment);
    post['comment_count'] = (post['comment_count'] as int) + 1;

    return CommentModel.fromJson(comment);
  }

  // ============================================================
  // 分享、語音加油（分享組 Wen，動態牆這次不使用，請勿修改）
  // ============================================================

  /// S-1：分享日記到社群動態
  Future<PostModel> shareDiary(int diaryId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return PostModel.fromJson({
      'post_id': 8,
      'diary_id': diaryId,
      'title': '高雄營隊趣聊記 🎉',
      'photo_url': 'https://picsum.photos/seed/32/400/300',
      'post_text': '我們在高雄小學，和孩子們一起參加三天的營隊，大家圍坐聊天，分享今天的活動點滴，暖心又充實。',
      'hashtags': ['#高雄營隊', '#小學活動', '#親子互動'],
      'category': 'entertainment',
      'date': '2026-09-22',
      'posted_at': '2026-09-22T02:40:00Z',
      'like_count': 0,
      'is_liked': false,
      'voice_reply_count': 0,
      'share_url': 'https://example.com/share/Zk3v9QpX2mLw7RtA5nHc8Q/',
      'invite_text': '王奶奶今天在高雄營隊記錄了一段開心的回憶，點進來看看她說了什麼吧！',
      'suggested_replies': ['營隊一定很有趣吧！', '看到你和孩子們相處真溫馨～', '下次也帶我一起去！'],
    });
  }

  /// S-5：某貼文的語音加油列表
  Future<List<VoiceReplyModel>> getVoiceReplies(int postId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      VoiceReplyModel.fromJson({
        'voice_reply_id': 12,
        'sender_name': '孫女小玲',
        'audio_url': 'https://example.com/reply12.mp3',
        'transcribed_text': '',
        'is_transcribed': false,
        'created_at': '2026-09-09T08:10:00Z',
      }),
    ];
  }

  /// S-6：App 內送出語音加油
  Future<VoiceReplyModel> submitVoiceReply(int postId, XFile audio) async {
    await Future.delayed(const Duration(seconds: 1));
    return VoiceReplyModel.fromJson({
      'voice_reply_id': 13,
      'sender_name': '孫女小玲',
      'audio_url': 'https://example.com/reply13.mp3',
      'transcribed_text': '',
      'is_transcribed': false,
      'created_at': '2026-09-22T09:00:00Z',
    });
  }

  /// S-7：語音加油一鍵轉文字
  Future<VoiceReplyModel> transcribeVoiceReply(int voiceReplyId) async {
    await Future.delayed(const Duration(seconds: 1));
    return VoiceReplyModel.fromJson({
      'voice_reply_id': voiceReplyId,
      'sender_name': '孫女小玲',
      'audio_url': 'https://example.com/reply12.mp3',
      'transcribed_text': '看到你用心陪伴孩子真令人感動',
      'is_transcribed': true,
      'created_at': '2026-09-09T08:10:00Z',
    });
  }
}