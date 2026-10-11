/// cooking_prep 是「記憶配對」（memory_recall）這款遊戲的美術主題包裝
/// （切菜=basic、調味=intermediate、烹飪=advanced），題目/選項/難度/計分
/// 全部由後端決定（見 MemoryRecallService），這裡只負責「後端給的文字標籤
/// 要對應到哪張圖」，不再有任何本地隨機出題邏輯。
const String _base = 'assets/images/game/cooking_prep';

/// 後端目前實測會出現的所有文字標籤 → 圖片路徑。map 的 key 一定要是後端
/// round/ 回傳的 target_item／option_items 字串本身，不能是借用素材的
/// 「原本名稱」，不然對應不到會整張顯示 Icon 佔位（曾經在這裡發生過一次）。
///
/// 特別注意：
/// - basic 階段用「胡蘿蔔」，跟 advanced 階段的「紅蘿蔔塊」「紅蘿蔔片」
///   雖然指同一種菜，但字串完全不同、也不是同一個 key，各自對應各自的圖
/// - intermediate 目前對照的是「辣椒粉／鮮奶油／咖哩塊」這三個字串
///   （2026-10 使用者指示改的，取代先前實測到的鹽巴／黑糖／味精，已重新
///   實測 config/ 跟 round/ 確認過，兩邊都是這三個字串，一致）。
/// - advanced 高階物品庫實測確認是 3 組×每組 2 型態（馬鈴薯泥/塊、
///   紅蘿蔔片/塊、洋蔥圈/洋蔥絲），這 3 組 6 個字串都要能對應到圖；
///   紅蘿蔔片／洋蔥圈／洋蔥絲目前沒有專屬素材，先借用既有圖片頂著
///   （見下方個別註解）。⚠️ 2026-10 後端團隊說明＋實測證實：advanced
///   階段卡片的干擾物可能來自「任何階段」，不是只有同組（例如卡片可能
///   同時出現 advanced 的「紅蘿蔔片」跟 intermediate 的「鮮奶油」）——
///   這個 map 本來就收錄三個階段全部的字串，不受影響，但不要再假設
///   advanced 干擾物一定同組，也不要因此寫任何「同組才顯示」的篩選邏輯。
///   ⚠️ 2026-10-03 實測修正：這個 key 原本寫的是「紅蘿蔔泥」，但 config/
///   跟 round/ 實際回傳的都是「紅蘿蔔片」，對不到導致這個形狀每次出現
///   （實測約三成機率）畫面都顯示 Icon 佔位，已改正；以後改這批 key
///   要先用 curl 實測 config/ 或 round/ 原始回應，不要用猜的
const Map<String, String> kMemoryRecallItemImages = {
  // basic（種類）
  '馬鈴薯': '$_base/potato.png',
  '胡蘿蔔': '$_base/carrot.png',
  '洋蔥': '$_base/onion.png',

  // intermediate（調味料）—— key 一定要是後端 round/ 實際回傳的字串，
  // 不然對應不到會整張顯示 Icon 佔位（這裡曾經發生過一次，圖片全部
  // 消失就是這個原因）。這三張是語意正確對應（不是借用湊近似）。
  '辣椒粉': '$_base/chili_powder.png',
  '鮮奶油': '$_base/cream_carton.png',
  '咖哩塊': '$_base/curry_roux_cubes.png',

  // advanced（形狀，同類型分組，實測確認固定 3 組：馬鈴薯／紅蘿蔔／洋蔥，
  // 每組固定 2 型態，干擾物只會從同組抽，不會跨組。同樣地，key 是後端
  // 實際回傳的字串，不是圖片素材的名稱）
  '馬鈴薯塊': '$_base/potato_cubes.png',
  '馬鈴薯泥': '$_base/mashed_potato.png',
  '紅蘿蔔塊': '$_base/diced_carrots.png',
  '紅蘿蔔片': '$_base/carrot_sliced.png', // 沒有專屬「紅蘿蔔片」圖，借用切片圖頂著
  '洋蔥圈': '$_base/onion_pieces.png', // 沒有專屬「洋蔥圈」圖，借用洋蔥塊狀圖頂著
  '洋蔥絲': '$_base/onion_sliced.png', // 沒有專屬「洋蔥絲」圖，借用洋蔥切片圖頂著
};

/// 對應不到就回傳空字串，呼叫端的 Image.asset 要接 errorBuilder 顯示 Icon 佔位，
/// 不要讓空字串路徑直接讓 App 當掉。
String imagePathForMemoryRecallItem(String label) =>
    kMemoryRecallItemImages[label] ?? '';

/// 純粹裝飾用：basic（切菜）階段答對後，ChoppingRewardScene 要有「切好」的
/// after 圖片才有變身的感覺，但後端資料本身沒有「切好」這個狀態，這裡只是
/// 借用既有的「切好」美術素材讓動畫好看，不代表後端真的有這個概念。
/// 查不到就退回原圖（等於沒有變身效果，只有道具動畫），不影響正確性。
const Map<String, String> kChoppedFlavorImages = {
  '馬鈴薯': '$_base/potato_cubes.png',
  '胡蘿蔔': '$_base/carrot_sliced.png',
  '洋蔥': '$_base/onion_sliced.png',
};

String choppedFlavorImagePath(String label) =>
    kChoppedFlavorImages[label] ?? imagePathForMemoryRecallItem(label);

const String kCuttingBoardImagePath = '$_base/cutting_board.png';
const String kChoppingPropIconPath = '$_base/knife.png';
const String kCookingPropIconPath = '$_base/cooking_stock_pot.png';

/// 整場遊戲結束時（finish/ 呼叫完成），如果玩家有玩到烹飪（advanced）
/// 階段才播放一次的彩蛋圖片，不是進入 advanced 階段當下就播（見
/// cooking_prep_game_page.dart 的 _finishGame）。看完彩蛋直接進結算頁，
/// 不再搭配影片播放。
const String kCelebrationImagePath = '$_base/curry_finished.png';

/// 調味階段展示畫面（單獨展示物品用）的鍋子底圖，畫的是清水，跟答對後
/// 顯示的完整湯圖片是不同的東西。
const String kSeasoningPotImagePath = '$_base/cooking_stock_pot.png';

/// 調味階段答對後直接顯示的完整湯圖片（本身就含容器，不疊加鍋子圖或
/// 顏色濾鏡）。key 要跟 kMemoryRecallItemImages 的 intermediate key
/// 一致（辣椒粉／鮮奶油／咖哩塊）。
const Map<String, String> kSeasoningSoupImages = {
  '辣椒粉': '$_base/red_soup.png',
  '鮮奶油': '$_base/white_soup.png',
  '咖哩塊': '$_base/curry_soup.png',
};

