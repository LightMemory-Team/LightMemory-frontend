import 'package:flutter/foundation.dart';

/// Demo 用的假扣點（點數商城兌換）
///
/// 後端還沒有兌換 API，兌換時先在 App 裡記下花掉多少點，
/// 所有讀總點數的地方都扣掉這個數字，首頁、成就牆、商城、結算卡片的點數才會一致：
/// - RewardsService.getSummary() 的 total_points
/// - 結算回傳 rewards 的 total_points（RewardsResult.fromJson）
///
/// 限制：只存在記憶體，重開 App 會回到後端的點數；登出時清掉（LogoutHelper）。
/// TODO：後端兌換 API 做好後刪除這個檔案，改由後端扣點、回傳扣完的 total_points。
class MockRedeemPoints {
  MockRedeemPoints._();

  /// 這次開 App 以來兌換花掉的點數；畫面可以監聽它，兌換後重新讀點數
  static final ValueNotifier<int> spent = ValueNotifier<int>(0);

  /// 後端的總點數扣掉兌換花掉的點數（最少 0）
  static int apply(int backendTotal) {
    final int result = backendTotal - spent.value;
    return result < 0 ? 0 : result;
  }

  static void spend(int points) => spent.value += points;

  static void reset() => spent.value = 0;
}
