import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/social/pages/post_detail_page.dart';

void main() {
  group('PostDetailPage.postIdFromTargetUrl（從通知 target_url 取貼文 ID）', () {
    test('後端目前的格式 /posts/<id>/', () {
      expect(PostDetailPage.postIdFromTargetUrl('/posts/12/'), 12);
    });

    test('較長的 API 路徑也相容', () {
      expect(PostDetailPage.postIdFromTargetUrl('/api/social/posts/12/'), 12);
    });

    test('前端風格路徑', () {
      expect(PostDetailPage.postIdFromTargetUrl('/posts/7'), 7);
      expect(PostDetailPage.postIdFromTargetUrl('/post/8/comments'), 8);
    });

    test('網址含 query 或完整網域也能取到', () {
      expect(PostDetailPage.postIdFromTargetUrl('https://example.com/api/social/posts/33/?from=push'), 33);
    });

    test('沒有 posts/ 時取最後一組數字', () {
      expect(PostDetailPage.postIdFromTargetUrl('/wall/5'), 5);
    });

    test('空字串或沒有數字回傳 null', () {
      expect(PostDetailPage.postIdFromTargetUrl(''), isNull);
      expect(PostDetailPage.postIdFromTargetUrl('/api/social/posts/'), isNull);
    });
  });
}
