/// 新手教學狀態的資料服務
/// 畫面（TutorialIntroPage、MainScreen）只跟這個 service 要資料，
/// 不會直接處理「怎麼判斷使用者看過教學」這件事，
/// 之後後端 API 確定後，只需要修改這個檔案內部，呼叫端完全不用改。
class TutorialService {
  // 暫時用靜態變數模擬「是否已完成教學」的狀態（假資料）
  // 注意：這只存在記憶體裡，App 重新啟動（網頁重新整理）就會重置回 false
  static bool _hasCompletedTutorial = false;

  /// 查詢使用者是否已經看過新手教學
  ///
  /// 之後後端 API 確定後（等後端回覆是合併進 GET /api/member/profile，
  /// 還是獨立開 GET /api/tutorial/status），這裡會改成類似：
  ///   final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/member/profile'));
  ///   final data = jsonDecode(response.body);
  ///   return data['has_completed_tutorial'] as bool;
  static Future<bool> hasCompletedTutorial() async {
    // 模擬網路延遲，讓呼叫端（畫面）的寫法提前跟真實 API 呼叫一致
    await Future.delayed(const Duration(milliseconds: 200));
    return _hasCompletedTutorial;
  }

  /// 標記使用者已完成（或跳過）教學
  /// 「完成教學」跟「跳過教學」都呼叫這個方法，統一寫入同一個狀態，
  /// 避免跳過教學的使用者之後又被重複打斷
  ///
  /// 之後後端 API 確定後，這裡會改成類似：
  ///   await http.patch(
  ///     Uri.parse('${ApiConstants.baseUrl}/member/profile'),
  ///     body: jsonEncode({'has_completed_tutorial': true}),
  ///   );
  static Future<void> markTutorialCompleted() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _hasCompletedTutorial = true;
  }
}