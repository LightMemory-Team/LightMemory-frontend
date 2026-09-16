## 蘇蘇（市場買菜：完整遊戲流程／串接後端 API／教學彈窗／暫停選單）— 2026/09/16

### 新增檔案
- `lib/features/game/market_shopping/models/market_shopping_models.dart`：資料結構（MarketFood、PurchasedItem、ShoppingQuestion、GameSession、ItemAnswerResult、ChangeAnswerResult）
- `lib/features/game/market_shopping/pages/market_shopping_game_page.dart`：主控制器，管理遊戲階段（loading／memorize／play／checkout／error）與三支 API 的呼叫時機
- `lib/features/game/market_shopping/pages/market_shopping_memorize_page.dart`：記憶購物清單畫面（平滑倒數進度條、「我記住了！」可跳過倒數）
- `lib/features/game/market_shopping/pages/market_shopping_play_page.dart`：選菜畫面（點擊選取、確認後顯示對錯、菜籃預覽）
- `lib/features/game/market_shopping/pages/market_shopping_checkout_page.dart`：結帳找零畫面（easy/medium 顯示總花費、hard 顯示明細自行加總）
- `lib/features/game/market_shopping/pages/market_shopping_result_page.dart`：結算頁（本次/最高正確率、歷史成績折線圖）
- `lib/features/game/market_shopping/widgets/game_in_progress_top_bar.dart`：遊戲進行中頂部列（暫停／標題／通知）
- `lib/features/game/market_shopping/widgets/game_pause.dart`：暫停選單（暫時版，見下方待處理）
- `lib/features/game/market_shopping/widgets/market_shopping_tutorial_dialog.dart`：玩法教學彈窗（4頁，含真實截圖）
- `lib/features/game/market_shopping/services/market_shopping_service.dart`：呼叫後端3支 API
- `lib/features/game/market_shopping/services/sound_player.dart`：音效播放（一般點擊／答對／答錯）
- `lib/features/game/market_shopping/services/tutorial_preference.dart`：教學是否看過的記錄（目前未使用，見下方）
- `assets/images/game/market_shopping/`：8種食材圖片（tomato/egg/tofu/cabbage/pork/cucumber/onion/spinach）＋3張教學截圖

### 修改檔案
- `lib/screens/game_home_screen.dart`：`DomainCard` 的 `onTap` 加上 `domain.id == 'math'` 判斷，跳轉到 `MarketShoppingGamePage`

### 目前狀態
- 核心流程已完整串接真實後端 API，可連續破關跑完整場 10 題（開始遊戲→記憶清單→選菜→結帳找零→結算頁）
- 已測試：Android 模擬器與 Chrome 皆正常運作，含答對／答錯／錯滿3次跳題／整場結束等分支情況

### 待後端補的 API
- 已提需求：`GET /api/games/market-shopping/history/`（查詢歷史成績），用於結算頁的歷史折線圖與最高正確率。**這支 API 做出來之前，結算頁的歷史成績只會顯示「本次」一個點，最高正確率也只是本次分數，不是真正歷史最高**，這是已知功能缺口不是 bug

### 給接手組員的提醒
- `game_pause.dart` 是暫時版本，因為原本說好共用的正式暫停選單一直沒等到，介面（`show()` 的四個參數 `onResume`／`onTutorial`／`onRestart`／`onExit`）已對齊組員說好的呼叫方式，之後拿到正式版可直接整份取代，不用改任何呼叫端
- `tutorial_preference.dart` 目前是孤兒程式碼沒被呼叫，原設計是「只有第一次玩才顯示教學」，後來邏輯改成「每次開局都顯示」（`market_shopping_game_page.dart` 的 `_startGame()` 直接顯示，沒檢查 `hasSeenTutorial()`），如果之後想改回只顯示一次，邏輯都還在，加回判斷即可
- 圖片路徑寫法：`Image.asset('images/game/market_shopping/xxx.png')`，**不要**加 `assets/` 前綴（`pubspec.yaml` 用 `assets/images/` 宣告資料夾後會自動處理，多加會導致雙重路徑 404，Chrome 可能正常但 Android 建置會出問題）
- 後端數字欄位可能是 double 不是 int（例如 accuracy），`market_shopping_models.dart` 檔案最下面有共用轉型函式 `_toInt` / `_toIntOrNull`，之後新增欄位記得套用同樣寫法避免 `type 'double' is not a subtype of type 'int?'` 錯誤
- 錯誤次數是選菜＋找零共用一個計數器（規格書明定），`ItemAnswerResult` 一定要有 `isCompleted` 欄位，否則玩家可能卡在已結束的 session 還被要求作答，導致 `SESSION_COMPLETED` 錯誤
- 選菜卡片視覺是「整片變色」簡化設計（未選＝木盒棕、選中＝深綠、答對＝綠、答錯＝橘），如果要統一六大類別遊戲風格可以參考這個配色邏輯
- Android 模擬器圖片顯示不出來但 Chrome 正常時，先懷疑 Gradle 快取（`C:\Users\<帳號>\.gradle\caches`）卡住舊版本，`flutter clean` 未必清得掉，需要手動刪除該資料夾後重新建置（會需要 5-8 分鐘重建快取，屬正常現象）

## Wen（新手教學：引導頁／首頁教練標記／教學狀態判斷）— 2026/09/02
...
## Wen（新手教學：引導頁／首頁教練標記／教學狀態判斷）— 2026/09/02

### 新增檔案
- `lib/features/auth/pages/tutorial_intro_page.dart`：新手教學引導頁（Logo、插圖、標題說明、「開始導覽」／「跳過教學」按鈕）
- `lib/features/auth/models/tutorial_step_model.dart`：教學步驟資料結構（步驟序號、對應底部導覽分頁 index、圖示、標題、說明文字、按鈕文字）
- `lib/features/auth/models/tutorial_mock_data.dart`：五步教學假資料（首頁／聲影日記／資訊站／儀表板／會員）
- `lib/features/auth/services/tutorial_service.dart`：教學完成狀態的資料服務（目前用記憶體變數模擬 `has_completed_tutorial`）
- `lib/features/auth/widgets/tutorial_overlay.dart`：教練標記（coach mark）疊加層，含半透明遮罩挖洞效果與提示框

### 修改檔案
- `lib/screens/main_screen.dart`：新增 `startTutorial` 參數；新增 `GlobalKey` 定位五個底部導覽 icon；新增教學播放狀態管理（目前步驟、目標位置量測、下一步／完成教學邏輯）；`build()` 改用 `Stack` 疊加教學 overlay
- `lib/core/constants/route_constants.dart`：新增 `AppRoutes.tutorial`（`/tutorial`）

### 目前狀態
- 全部使用假資料（`tutorial_mock_data.dart` 的 `mockTutorialSteps`，`TutorialService` 的記憶體變數），尚未接上真實 API
- 教學播放順序（首頁→聲影日記→資訊站→儀表板→會員）與 `MainScreen` 底部導覽的實際 index 順序不同，已在 `TutorialStepModel` 用獨立的 `pageIndex` 欄位對應，避免切換到錯誤分頁
- 已測試：Chrome 瀏覽器正常顯示，5 步教學可依序切換分頁並正確挖洞定位、跳過教學與完成教學皆會標記狀態

### 待後端確認（給後端組看，詳見「新手教學_API需求文件.md」）
- 使用者資料表是否可新增 `has_completed_tutorial`（boolean）欄位
- 讀取方式：建議合併進會員資料 API 一起回傳，不另開新 endpoint
- 寫回方式：完成／跳過教學時要呼叫哪一支 API
- 家屬版之後是否需要獨立的教學狀態欄位（`has_completed_tutorial_elder` / `_family`）

### 給接手組員的提醒
- `TutorialOverlay` 是獨立元件，之後如果別的頁面也要做類似的教練標記引導，可以直接複用，不用重寫挖洞邏輯
- 若要接真實 API，只需修改 `tutorial_service.dart` 內部實作，`MainScreen` 與 `TutorialIntroPage` 呼叫端完全不用改
- `main_screen.dart` 目前是直接切換分頁 widget（非 `IndexedStack`），如果之後遊戲頁或聲影日記頁需要保留頁面狀態（例如遊戲進行到一半），要留意切分頁時狀態會重置的問題

## 欣紜（架構更新：建立 core 核心層與全域常數定義）— 2026/08/31

### 本次異動目標
- 統一前端專案目錄架構，建立 lib/core 共用核心層，解決組員間目錄結構不一致問題。
- 集中管理全域路由路徑與後端 API 網址常數。
- 修復 welcome_page.dart 結尾缺少括號與分號的語法問題。

### 新增與變更檔案
- `lib/core/`：建立共用核心層
  - `constants/route_constants.dart`：定義全 App 頁面路徑常數（AppRoutes）。
  - `constants/api_constants.dart`：定義後端 API 基礎 URL 與請求路由常數（待後端 API 文件提供後更新端點）。
  - `network/`：預留全域網路請求模組。
  - `theme/`：預留全域主題與色票定義。
  - `utils/`：預留共用工具函式庫。
- `lib/features/auth/pages/welcome_page.dart`：修復結尾語法錯誤，恢復可編譯狀態。

### 開發與調用規範
1. 頁面跳轉：
   - 請統一使用 `AppRoutes.xxx` 進行導航，避免手寫字串造成拼字錯誤。
   - 範例：`Navigator.pushNamed(context, AppRoutes.settings);`
2. API 呼叫：
   - 後續所有網路請求端點請統一從 `ApiConstants` 取用路徑。

---

## Wen（遊戲首頁：頂部列／今日進度卡／六大認知領域卡片／底部任務按鈕）— 2026/08/29

### 新增檔案
- `lib/features/game/models/cognitive_domain_model.dart`：認知領域資料結構（id、title、icon、是否今日推薦）
- `lib/features/game/models/game_mock_data.dart`：六大認知領域假資料（語言／工作記憶／注意力／執行功能／視覺空間／數學）
- `lib/features/game/widgets/game_top_bar.dart`：遊戲首頁頂部列（首頁圖示、通知鈴鐺含紅點提示）
- `lib/features/game/widgets/training_progress_card.dart`：今日訓練進度卡片（完成數／總數、百分比、進度條）
- `lib/features/game/widgets/domain_card.dart`：單一認知領域卡片（圖示、標題、今日推薦標籤、按壓效果）
- `lib/features/game/widgets/game_bottom_actions.dart`：底部「每日任務」「我的成就」按鈕
- `lib/screens/game_home_screen.dart`：組裝以上元件成完整遊戲首頁畫面

### 目前狀態
- 全部使用假資料（`game_mock_data.dart` 裡的 `mockCognitiveDomains`），尚未接上真實 API
- 六宮格使用 `LayoutBuilder` 動態計算卡片尺寸，確保 2 欄 3 列剛好填滿畫面、不需捲動
- 已測試：Chrome 瀏覽器正常顯示、圖示置中、進度條與百分比正確反映假資料數值

### 待後端確認（給後端組看）
- 需要欄位：`completed_count`、`total_count`（今日訓練進度）、六大領域各自的 `is_recommended`（今日推薦邏輯，可能由 AI 依表現動態決定）
- 通知紅點 `hasUnreadNotification` 需要對應的未讀通知數量 API

### 給接手組員的提醒
- 六個小元件都是獨立檔案，直接 import 使用即可，不用改內部邏輯
- 卡片點擊（`DomainCard` 的 `onTap`）與底部按鈕點擊目前都只有 `// TODO` 佔位，尚未串接路由，前端路由方案（Navigator 或 go_router）待團隊會議討論後補上
- 若要接真實 API，只需修改 `game_mock_data.dart` 或改為呼叫真正的 service，`game_home_screen.dart` 與六個元件完全不用動