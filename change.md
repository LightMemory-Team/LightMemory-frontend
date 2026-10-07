## Wen（會議前後修正：來去菜市場教學頁方向／菜市場購物 session_id 檢查／整理菜籃改用共用暫停選單／舊色碼／遊戲首頁深色模式）— 2026/10/06–10/07

### 本次異動目標
- 以欣紜的 `fix/session-id-uuid`（JWT token、`session_id` 改 UUID 字串）為基礎，開 `fix/pre-meeting-1006` 處理整合後的待辦（見 `docs/frontend_todo.md`）。
- 修正來去菜市場教學頁用 Android 系統返回鍵離開時，遊戲首頁停在橫向的 bug。
- 暫停選單統一、舊色碼改用主題色，遊戲首頁補上深色模式（9/30 開會發現遊戲首頁完全沒套用深色模式和字級）。

### 修改檔案
- `lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart`
  - 新增 `openedFromGame` 參數，區分教學頁是從遊戲首頁還是從遊戲中（暫停選單、說明按鈕）打開。
  - 設回直向的動作移到 `dispose()`，系統返回鍵和手勢離開也會執行；從遊戲中打開、或正要換成遊戲頁時不設回直向。原本放在 `dispose()` 會出錯的原因：`pushReplacement` 換成遊戲頁時，教學頁的 `dispose()` 比遊戲頁的 `initState()` 晚執行，會把遊戲剛鎖好的橫向改回直向。
  - 「開始挑戰」「略過教學」共用 `_startGame()`：從遊戲中打開時改成返回並通知遊戲重新開始，修正原本會在遊戲頁上面再疊一個遊戲頁的問題。
  - `State` 補上型別 `State<GoToMarketTutorialPage>`。
- `lib/features/game/go_to_market/pages/go_to_market_game_page.dart`：暫停選單和說明按鈕打開教學時帶 `openedFromGame: true`；教學頁回傳 `true` 時呼叫 `_resetGame()`。
- `lib/features/game/market_shopping/models/market_shopping_models.dart`：`GameSession.fromJson` 拿不到 `session_id` 時直接丟出例外，不再用空字串繼續（原本下一步會打到 `/sessions//item-answers/`，只得到看不懂的 404）。錯誤畫面與「重試」按鈕沿用遊戲頁原本的 `catch`。
- `lib/screens/market_sort_game_screen.dart`：暫停選單從 `PauseModal`（畫面覆蓋層）改成共用的 `GamePause.show()`（對話框），移除 `_showPause`。四個按鈕的行為不變。用 Android 返回鍵關掉對話框時沒有按到任何按鈕，當作「繼續遊戲」，避免遊戲停在暫停狀態。
- `lib/features/game/market_sort/widgets/pause_modal.dart`：刪除，五款遊戲的暫停選單都改用 `GamePause`。
- `lib/features/game/market_sort/widgets/result_score_card.dart`、`result_history_chart.dart`：暫時測試色 `_testPrimaryColor`（`0xFF2E5940`）改用 `AppTheme.primaryColor`。
- 遊戲首頁深色模式、高對比、字級（配色沿用首頁 `home_screen.dart`、`game_card.dart` 的寫法）：
  - `lib/screens/game_home_screen.dart`：外層用 `ValueListenableBuilder` 監聽 `isDarkMode`，深色背景 `0xFF121212`。
  - `lib/features/game/widgets/game_top_bar.dart`：圖示深色改 `0xFF4CAF50`，高對比改純黑／純白。
  - `lib/features/game/widgets/domain_card.dart`：卡片深色底 `0xFF25382E`（按下 `0xFF32503F`）、文字 `0xFFB8E6D0`；高對比加外框；標題用 `FittedBox` 避免字放大時溢出。
  - `lib/features/game/widgets/training_progress_card.dart`：進度條舊主色 `0xFF5B9E87` 改用 `AppTheme.primaryColor`（深色模式用 `0xFF4CAF50`）；卡片套用深色與高對比；「今日已完成」那行改用 `Expanded`，字放大時自動換行。
  - `lib/features/game/widgets/game_bottom_actions.dart`：「我的成就」外框按鈕深色底改 `0xFF1E1E1E`、框線與字改亮綠；文字加 `Flexible` 避免溢出。
  - 4 個元件各自用 `ListenableBuilder` 監聽 `fontSizeLevel`、`isDarkMode`、`isHighContrast`，文字改用 `AppSettings.scaleFont()`。
- `docs/frontend_todo.md`：新增 G（聲影日記）、H（API 串接）兩段，勾選已完成項目，補上 `flutter analyze` 發現的 warning。

### 目前狀態
- 每項修改都跑過 `fvm flutter analyze`，0 error；剩下的 info／warning 都是原本就有的。
- 整理菜籃暫停選單、遊戲首頁深色模式已在 Chrome 測過。
- **來去菜市場教學頁的螢幕方向尚未實機測試**：Chrome 上螢幕方向不會變；這次 Android 模擬器因電腦記憶體不足沒跑起來。

### 已知延後項目
- 來去菜市場教學頁方向修正，待 Android 實機或模擬器測試以下四種情況：從遊戲首頁進入後用系統返回鍵離開、略過教學進入遊戲、遊戲中開說明再返回、遊戲中開說明再按開始挑戰。
- 遊戲首頁深色模式的字級目前用 `AppSettings.scaleFont()`，之後做字體縮放全域化時要一起改。
- 其餘待辦（登入／註冊／教學頁深色模式、聲影日記播放暫停與上傳提示、字體縮放全域化、頂部列統一、401 提示共用化等）見 `docs/frontend_todo.md`。

### 給接手組員的提醒
- 以後從遊戲中打開來去菜市場教學頁，要帶 `GoToMarketTutorialPage(openedFromGame: true)`，不然離開時會被設回直向。
- 暫停選單一律用 `GamePause.show()`，不要再各自刻。`GamePause` 是對話框，按鈕會先關掉對話框再執行 callback；用 Android 返回鍵關掉時四個 callback 都不會被呼叫，記得處理（可參考 `market_sort_game_screen.dart` 的 `_openPause()`）。
- 深色配色請沿用 `home_screen.dart`、`game_card.dart`：背景 `0xFF121212`、卡片 `0xFF25382E`、文字 `0xFFB8E6D0`、圖示 `0xFF4CAF50`。
- `api_constants.dart` 的 `serverUrl` 是 Cloudflare 臨時網址，每次後端重開都會變，換網址只在自己電腦改，不要 commit。

---

## Vevila（料理準備：對齊後端前測判斷／單題作答時限／錯誤碼，前測結束直接進正式賽）— 2026/10/05

### 本次異動目標
- 修正「前測（練習題）結束後直接跳出結算與歷史紀錄」：前測是給第一次玩的使用者練習，結束後應直接進正式賽。
- 後端組員對照 `games/memory_recall/views.py` 指出前端有幾個假設跟後端不一致，一併修正：前測由後端判斷、正式賽每題有作答時限、時間到是錯誤碼不是 `action`。

### 修改檔案
- `lib/features/game/cooking_prep/pages/cooking_prep_game_page.dart`
  - 移除本機旗標 `memory_recall_has_played`：後端不讀 `start/` 的 `is_pretest`，前測與否完全依資料庫判斷，改用 `start/` 回應的 `is_pretest`。
  - 前測結束：呼叫 `finish/` 後直接 `_startGame(showTutorial: false)` 開正式賽，不顯示結算、不寫進歷史成績、不再顯示一次教學。
  - 新增正式賽單題倒數條（`kRoundTimeoutSeconds = 10`，對應後端 `ROUND_TIMEOUT_SECONDS`）。從呼叫 `round/` 開始算、暫停不補償，跟後端計時一致；歸零時主動結算。
  - 依錯誤碼顯示結束原因：`ROUND_TIME_UP` →「本題超過作答時間」、`GAME_TIME_UP` 與本地整場倒數歸零 →「時間到！」，顯示 1.5 秒後才進結算，不會「突然結束」。
- `lib/features/game/cooking_prep/services/memory_recall_service.dart`：`startGame` 註解改為說明後端不讀 `isPretest`。
- `docs/cooking_prep_system.md`（新增）：料理準備前端完整系統說明（流程、狀態、計時、結算、錯誤處理、已知問題）。
- `docs/cooking_prep_frontend_spec.md`：更正 `session_id`（UUID 字串）、`action` 只有三種、完整錯誤碼、`finish/`／`result/` 回傳格式、`is_correct` 判定已確認正確、移除過時的 ver5 展示邏輯。

### 目前狀態
- `flutter analyze lib/features/game/cooking_prep` 0 error（只剩 service 原本就有的 1 個 info）。
- **尚未實機測試**：前測→正式賽銜接、單題超時、暫停後超時、整場時間到都還要跑一次確認。

### 已知延後項目
- 單題時限從 `round/` 開始算（物品展示時間也算在內）、暫停無效：需要後端調整（選項揭曉後才計時，或支援暫停），並建議在 `config/` 提供時限秒數。
- 中途離開（退出、重新開始）沒有呼叫 `finish/`。

### 給接手組員的提醒
- 後端正式上線把 `ROUND_TIMEOUT_SECONDS` 改成 20 時，前端 `kRoundTimeoutSeconds` 要一起改。
- 想重新測前測，清 App 資料沒用，要換一個後端沒有結束紀錄的帳號。

---

## Wen（前端整合：合併冰箱清點、料理準備／後端網址集中到 ApiConstants／修正冰箱清點 token 讀取）— 2026/10/05

### 本次異動目標
- 把三組分支整合到 `integrate/frontend-1004`：Wen 的 `feature/wen-diary-setup`（聲影日記、整理菜籃）為基底，合併欣紜的 `game-fridge-inventory`（冰箱清點）、蘇蘇的 `feature/cooking-prep`（料理準備）。
- 後端網址原本散在 7 支 service、混用 3 個不同的 trycloudflare 網址，集中到一個地方管理。

### 合併時的處理方式
- `lib/main.dart`：保留 `AuthGate`（登入檢查）與 `onGenerateRoute` 路由。欣紜版本的開機畫面 `GameHomeScreen`、蘇蘇版本的 `IdentitySelectPage` 都沒有採用，未登入時 `AuthGate` 本來就會導到身分選擇頁。保留蘇蘇加的「開機強制直向」，避免 hot restart 後殘留橫向設定。
- `pubspec.yaml`：套件以 Wen 的版本為主，assets 補上 `fridge_inventory/`、`cooking_prep/`、`assets/audio/game/`。
- `lib/screens/game_home_screen.dart`：兩邊的 import 都保留。目前五個領域都已接上：視覺空間→冰箱清點、數學→市場買菜、執行功能→整理菜籃、注意力→來去菜市場、工作記憶→料理準備（只剩語言是敬請期待）。
- 刪除 `changes.diff`（`git diff` 的輸出檔，誤 commit 進來的，不影響程式）。

### 修改檔案
- `lib/core/constants/api_constants.dart`：新增 `serverUrl`，後端網址只寫在這裡。
- 7 支 service 改用 `${ApiConstants.serverUrl}` 組網址，路徑後半段不變：`auth_service.dart`、`diary_service.dart`、`go_to_market_service.dart`、`market_shopping_service.dart`、`market_sort_api_service.dart`、`fridge_inventory_service.dart`、`memory_recall_service.dart`
- `lib/features/game/fridge_inventory/services/fridge_inventory_service.dart`：讀 token 原本用 `auth_token`，但登入時存的是 `access_token`（`TokenStorage`），所以一直拿不到 token。改成跟其他遊戲一樣用 `TokenStorage.getAccessToken()`。

### 目前狀態
- `flutter analyze` 全專案 0 error（只剩原本就有的 info 提示）。
- 整合後的後端還沒完成，尚未連線實測。10/5 由欣紜、小惠對接測試。

### 已知延後項目
- 共用元件統一、字體縮放全域化、深色模式補齊、橫向鎖定共用化，整理在 `docs/frontend_todo.md`。

### 給接手組員的提醒
- 後端換網址，只要改 `api_constants.dart` 的 `serverUrl` 一行，存檔後重新 `flutter run`。只有後端改了某個功能的路徑（例如 `/api/diary/`），才需要回去改那支 service。
- 之後新增的 service 一律用 `ApiConstants.serverUrl` 組網址、用 `TokenStorage` 讀 token，不要再寫死網址或自己存取 SharedPreferences。
- commit 前先 `git status` 看清單，不要用 `git add .`。plugin 那幾個檔案和 `pubspec.lock` 常被自動改動，用 `git restore linux macos windows pubspec.lock` 還原。

---

## 蘇蘇（料理準備：修正 1-back 預覽時機 bug／拿掉多餘的橋接輪邏輯／新增前端規格文件）— 2026/10/04

### 本次異動目標
- 後端團隊看過實測 log 後回報：`cooking_prep`（記憶配對／memory_recall 美術包裝）原本的展示時機搞錯了——每輪選項卡出現前，畫面展示的是「上一輪」的 `new_item`，而那個值剛好就是這一輪的正解，等於出題前就先把答案秀給玩家看，整個遊戲變成「看了就選」，不是真正的 1-back 記憶測驗。照後端給的正確約定重寫展示邏輯。
- 後端同時更新：`round/answer/` 不再回傳 `seed_item`（升階不換種子，鏈不中斷）、升階門檻 `promote_streak` 從 3 改成 6、高階卡片的干擾物可能來自任何階段（不再保證同組）。
- 補一份 `cooking_prep` 的前端規格文件，把 API 契約、核心邏輯、已知問題整理成文件，方便之後跟後端對接或交接。

### 修正 `_fetchNextRoundAndPreview`（`cooking_prep_game_page.dart`）
- 改成每一輪都只展示「這一輪自己」`round/` 回應裡的 `new_item`（不是上一輪的），這個值保證不會出現在這一輪自己的 `option_items` 裡，純粹是為了讓玩家記住、留到下一輪才用得到；這一輪選項卡的正解是「上一輪」已經展示過的 `new_item`，不重複提示。
- 整場遊戲只有第 1 輪例外：依序展示 `seed_item`（start/ 給的）再展示第 1 輪自己的 `new_item`，之後每一輪都只展示 1 個物品。
- 拿掉 ver5 版本「比較這輪跟上一輪 stage 是否不同、換階段要展示兩個物品」的 `isStageOpening` 邏輯——後端證實不需要，鏈不會因為升階而中斷，換階段跟平常任何一輪一樣只展示 1 個物品。原本發現的「橋接輪」現象（升階後下一次 `round/` 的 `stage` 還停在舊階段）依然存在，但已經確認不影響展示個數，只是畫面主題切換會晚一輪的已知小瑕疵。
- 拿掉舊版「anchor 要驗證是否在這輪 optionItems 裡、對不上就整輪展示」的防呆分支——新邏輯下 `new_item` 本來就不該出現在自己這輪的選項裡，不需要這個檢查。

### 更新過時／錯誤的註解
- `memory_recall_model.dart`：`MemoryRecallRound.newItem` 的註解更新成正確語意（這一輪自己要新引入的物品，不是「下一輪會出現」的舊說法），並移除對已不存在的 `_advanceToNextRound` 方法的引用。
- `cooking_prep_asset_map.dart`：移除「進階階段干擾物永遠同組抽取、不會跨組」的錯誤假設（後端證實跨階段也會出現，實測也抓到 `鮮奶油`／`洋蔥` 這種其他階段字串混進 advanced 選項），補上提醒不要再假設同組。

### 新增 `docs/cooking_prep_frontend_spec.md`
- 玩法總覽、6 支 API 的實際 request/response 格式與已知欄位行為（`new_item`、橋接輪、`is_correct` 判定）、核心預覽邏輯、已修復的歷史 bug（供日後排查參考）、前端自訂的部分、目前已知未解決的問題（`is_correct` 判定反轉，已回報後端）。

### 驗證
- 用 Python 直打 API 驗證（不是用猜的）：`new_item` 對下一輪的預測在 100+ 輪測試中（含故意答錯穿插、含升階橋接輪）0 次錯輪；`is_correct` 判定目前仍是反的（已回報後端，前端刻意不做任何補償）。
- `flutter analyze` 全專案乾淨，只剩改動前就存在的既有 lint 提示。
- 真機實測（emulator）：前測 4 輪全部用新邏輯逐輪核對 debugPrint 輸出，展示內容與判定結果跟預期完全一致；結算流程（`finish/` → 結算對話框）在「正常破關」與「session 意外逾時」兩種情況下都正常顯示、沒有卡死或崩潰。

### 已知延後項目
- advanced 階段干擾物池的實際分佈規則（跨階段混入的機率、是否還有其他規律）還沒有長時間統計，只確認了「不保證同組」這個事實。
- 後端 `is_correct` 判定反轉的問題仍待後端修復，前端目前的行為是正確的（忠實呈現後端判定），不需要配合現況調整。

---

## 欣紜（冰箱清點：玩法教學／遊戲主畫面／結算頁／串接後端 API）— 2026/10/04

### 本次異動目標
- 新增「冰箱清點」遊戲（視覺空間領域），包含三種難度的玩法教學、遊戲主畫面、結算頁，並串接後端 `fridge-check` API。
- 六大認知領域中的「視覺空間」卡片接上冰箱清點，點擊後進入教學頁。
- 修正 Session ID 型別錯誤：後端回傳的 `session_id` 是 UUID 字串，原本前端用 `int` 解析導致變成 `0`，送答案時打到 `/sessions/0/answers/` 一直回 404 `SESSION_NOT_FOUND`。

### 新增檔案
- `lib/features/game/fridge_inventory/models/fridge_inventory_model.dart`：資料結構（`FridgeItem` 九宮格格子、`SourceFood` 困難模式待放入食材、`FridgeQuestion` 題目、`FridgeGameSession` 遊戲場次）。`sessionId` 為 `String`（UUID）
- `lib/features/game/fridge_inventory/services/fridge_inventory_service.dart`：串接後端 3 支 API
  - `POST /api/games/fridge-check/sessions/`：建立場次、取得第一題
  - `POST /api/games/fridge-check/sessions/{session_id}/answers/`：送出答案，body 為 `{"answer": {...}, "reaction_time_ms": ...}`（不傳 `question_id`）。easy 傳 `food_code`、medium 傳 `position`、hard 兩者都傳
  - `GET /api/games/fridge-check/history/`：歷史成績，相容 `history`／`data.history`／`result.history`／純陣列四種回傳格式
  - 回應解析會自動取出 `data` 或 `result` 內層，對應後端統一的 `{success, data, error}` 格式；有 token 時帶 `Authorization: Bearer token`
- `lib/features/game/fridge_inventory/pages/fridge_tutorial_page.dart`：玩法教學頁（6 頁，簡單／中等／困難各 2 頁）
  - 每頁先展示題目，下一頁用外框＋手指圖示標出正確答案
  - 切換到中等、困難難度時跳出 1.4 秒的難度提示彈窗
  - 右上「略過教學」可直接開始遊戲，最後一頁跳出「所有難度教學已完成」彈窗（開始遊戲／再看一次教學）
- `lib/features/game/fridge_inventory/pages/fridge_game_page.dart`：遊戲主畫面
  - 冰箱造型九宮格（冷藏室標頭、玻璃層板、最下排為蔬果保鮮抽屜），上方顯示難度標籤與題號進度條
  - 三種作答方式：easy 點食材、medium 點位置、hard 先點下方「待放入食材」再點目標格子
  - 答對：綠框＋打勾＋答對音效；答錯：橘框＋答錯音效，每題最多 3 次，次數用完自動進下一題
  - 難度、題號、剩餘次數以後端回傳為準（`difficulty`／`current_question`／`remaining_attempts`），後端沒給時才用本地值推算
  - 共用暫停選單 `lib/features/game/widgets/game_pause.dart`，App 切到背景時自動暫停
  - 連線失敗時顯示錯誤畫面與「重新連線」按鈕
- `lib/features/game/fridge_inventory/pages/fridge_result_page.dart`：結算頁（標題與遊戲頁、教學頁統一為「冰箱清點」）
  - 評語依分數分三級：90 分以上「非常棒！」（星星）、60～89「很好！」（打勾）、60 以下「沒關係，再加油！」（旗子，橘色）
  - 本次分數／最高分數（最高分取全部歷史紀錄最大值）
  - 最近五次成績折線圖（`CustomPainter` 自繪），本次成績固定放在最右邊
  - 歷史成績載入失敗時顯示「目前無法取得歷史成績」與「重新載入」按鈕，本次成績照常顯示
  - 「再玩一次」重新開局、「退出」返回上一頁
- `assets/images/game/fridge_inventory/`：9 種食材圖片（apple／banana／cabbage／carrot／egg／milk／pepper／tofu／tomato）＋教學用手指圖示 `finger.png`。檔名對應後端 `food_code`，畫面用 `$foodCode.png` 組路徑
  - 原本的 `red bell pepper.png` 已刪除，改為 `pepper.png`（檔名有空格容易在 Android 建置出問題，也要跟後端 `food_code: pepper` 對上）

### 修改檔案
- `lib/screens/game_home_screen.dart`：`DomainCard` 的 `onTap` 新增 `domain.id == 'visual_spatial'` 分支，導向 `FridgeTutorialPage`；其他領域導向不變
- `pubspec.yaml`：assets 新增 `assets/images/game/fridge_inventory/`（Flutter 的資料夾宣告不會自動包含子資料夾，必須另外宣告），並移除預設的英文註解
- `lib/features/game/go_to_market/services/audio_service.dart`（來去菜市場團隊的檔案）：
  - 移除 `PlayerMode.lowLatency` 與 `AudioContext` 設定，改用 audioplayers 預設值，原因是這段設定在 Android 模擬器上會造成音效播放異常
  - 修正錯誤訊息字串寫壞的問題（`'❌ 播放音效失敗 (\(fileName):\)e'` → `'❌ 播放音效失敗 ($fileName): $e'`）
- `lib/main.dart`：⚠️ 開機首頁暫時從 `IdentitySelectPage` 改成 `GameHomeScreen`，方便測試時直接進遊戲大廳（見下方「已知延後項目」）

### 目前狀態
- 已完成真實後端 API 串接測試，能建立場次、完整玩完 10 題（含答對／答錯／錯滿 3 次自動跳題）、送出成績並進入結算頁
- 結算頁的歷史成績 API 已接通，最高分數與最近五次折線圖皆正常顯示
- 已測試：Android 模擬器正常運作，九宮格與食材圖片、音效、暫停選單皆正常；尚未在 Chrome 測試
- Session ID 修正後，送答案的網址已改為 `/sessions/{UUID}/answers/`，不再出現 404 `SESSION_NOT_FOUND`

### 已知延後項目
- ⚠️ `lib/main.dart` 的開機首頁是測試用暫時改法，**會跳過登入流程**，沒有登入就不會有 token，需要驗證的 API（例如歷史成績）可能會失敗。正式推上 GitHub 前要改回 `IdentitySelectPage`
- 遊戲畫面的錯誤頁有三顆「測試成績頁（100／80／45 分）」按鈕（`isTestMode: true`，使用固定的假歷史資料 35→60→70→85），是後端沒開時測試結算頁用的，正式版要移除
- 退出導航尚未統一：遊戲頁與教學頁的暫停選單「退出遊戲」仍是 `popUntil(isFirst)`，結算頁「退出」是 `pop()`。蘇蘇 9/18 已把其他三款遊戲統一成 `pushAndRemoveUntil(GameHomeScreen)`，冰箱清點之後要跟著改
- 結算頁的折線圖是自己用 `CustomPainter` 畫的，還沒改用整理菜籃的共用元件 `ResultScoreCard`／`ResultHistoryChart`（fl_chart）
- 送答案失敗時只顯示「後端判題失敗 (404)」，還沒改用 `lib/core/network/api_response.dart` 的 `parseEnvelope`，所以看不到後端給的中文錯誤訊息（例如「查無此遊戲場次」）

### 給接手組員的提醒
- **後端的 `session_id` 是 UUID 字串，不是數字**，model、service、遊戲頁三個地方都要用 `String` 保存。如果用 `int.tryParse(...) ?? 0` 會靜默變成 0，畫面不會報錯，但每次送答案都會 404
- `fridge_inventory_service.dart` 的後端網址目前寫死為 `drawing-gap-jpeg-work.trycloudflare.com`，跟其他三款遊戲用的網址不同，也還沒改用 `ApiConstants`。`trycloudflare.com` 臨時網址會過期，網址換掉時這個檔案也要一起更新
- `audio_service.dart` 是來去菜市場的檔案，這次的修改會影響所有共用它的遊戲（來去菜市場、冰箱清點、六大領域首頁點擊音效）。如果來去菜市場那邊發現音效延遲變明顯，可能跟移除 `lowLatency` 有關
- 冰箱清點的圖片路徑使用完整的 `assets/images/game/fridge_inventory/xxx.png` 寫法，已在 Android 模擬器確認可以正常顯示
- 新增食材時，圖片檔名必須跟後端的 `food_code` 完全一致（全小寫、不要有空格），找不到圖片時會顯示預設的餐具圖示
- 每次從首頁進入都會先顯示教學頁，目前沒有「只有第一次顯示」的判斷

---

## Wen（整理菜籃：豬肉圖改為豬排／移除去背工具資料夾）— 2026/10/04

### 修改檔案
- `assets/images/game/market_sort/pork.png`：原圖看起來像層狀五花肉，容易跟培根混淆，改畫成帶骨豬排
- `.gitignore`：移除 `_raw_market_sort/`（去背原圖與 `prepare_images.py` 已移出專案，之後去背在專案外處理）

### 已知延後項目
- 牛肉圖偏褐色（顏色題答案是紅），之後可能重畫

## Wen（聲影日記：比賽版畫面比對／主色改深綠／錄音區提示文字／完成頁分享按鈕）— 2026/09/30

### 本次異動目標
- 在本機架起比賽版聲影日記（futureQ，Django），跟專題版 Flutter 逐頁比對首頁、月曆、動態回顧、上傳照片、錄音流程、等待頁、完成頁、分享頁共 8 組畫面，整理出差異清單並依優先度修正。
- 優先處理影響長輩使用的部分：顏色對比不足、缺少操作說明、最新訊息被遮擋。

### 修改檔案
- `lib/theme/app_theme.dart`：`primaryColor` 從 `0xFF5B9E87` 改為比賽版的深綠 `0xFF36684C`，白字對比度從約 3:1 提高到約 6:1（無障礙標準為 4.5:1）；`ColorScheme.fromSeed` 額外指定 `primary: primaryColor`，確保透過主題取色的 Material 元件跟 `primaryColor` 完全一致
- `lib/features/diary/widgets/record_button.dart`：
  - 新增 `isFirstRound` 參數
  - 按鈕下方新增依狀態變化的提示文字（新增 `_hintForState()`）：待機時第一輪顯示「請盡量詳細描述照片裡的人、地點、發生的事（至少講 15 秒喔）。點擊開始錄音」，之後顯示「點擊開始錄音」；錄音中「點擊暫停，或按完成送出」；暫停時「點擊繼續錄音，或按完成送出」；送出中「語音辨識與思考中…」
  - 計時器改用 `Text.rich` 顯示為 `00:48 / 03:00`，上限時間用較小的字，避免大字級時過寬
  - `ListenableBuilder` 改為同時監聽字級、深色模式、高對比，提示文字顏色跟著設定切換
- `lib/features/diary/pages/diary_chat_page.dart`：
  - 逐字稿先 `trim()`，`null` 或空字串都顯示「（沒有聽清楚）」（後端沒聽到聲音時回傳的是空字串，原本的 `?? '（沒有聽清楚）'` 判斷不到，會出現只有播放鍵的空白氣泡）
  - `RecordButton` 傳入 `isFirstRound: _roundIndex == 1`
  - `onStateChanged` 裡多呼叫一次 `_scrollToBottom()`：原本捲到底之後，下方才冒出「這題跳過」「生成日記」按鈕，對話區變矮，導致最新的 AI 問題被錄音區擋住
- `lib/features/diary/pages/diary_loading_page.dart`：文字「語言認知計算中請稍後」改為「正在整理您的日記，請稍候」（修正「稍後」錯字，並避免長輩覺得自己在被測驗）；外層加 `Flexible`，大字級時自動換行不溢出
- `lib/features/diary/pages/diary_finish_page.dart`：
  - 分享卡片外層包 `RepaintBoundary`，供「儲存圖片」轉成 PNG
  - 原本單一的「分享日記」按鈕（系統分享選單）改為比賽版的 2 × 2 按鈕：LINE 分享、Facebook、儲存圖片、複製連結，上方加「分享這則日記」標題
  - LINE 分享使用官方分享網址 `https://line.me/R/share?text=...`，透過 `url_launcher` 開啟
  - Facebook、複製連結會判斷 `diary.shareUrl`：目前後端沒有回傳，按下時顯示「分享連結準備中，之後就能使用」；後端開始回傳 `share_url` 後自動生效，不用再改程式
  - 組分享文字的邏輯從 `_onShareTap()` 抽成 `_buildShareText()`
  - 外框按鈕在深色模式改用 `0xFF4CAF50`，避免深綠在深色背景上太暗

### 目前狀態
- 已在 Chrome 手動測試：錄音各狀態提示文字、計時器上限顯示、第一輪 15 秒門檻、空白逐字稿提示、最新訊息不被遮擋、等待頁文字、完成頁四顆分享按鈕（LINE 開啟分享頁、Facebook／複製連結顯示提示、儲存圖片下載 PNG）
- 繁體字檢查通過：AI 提問、Whisper 逐字稿、生成的日記標題與內文、標籤皆為繁體

### 已知延後項目
- 首頁月曆：點擊月份標題彈出年月快速選擇框（比賽版為 4 × 3 月份按鈕）
- 首頁月曆：尚未用有日記的帳號確認日期格子是否顯示照片標記
- 動態回顧：比賽版為獨立頁面（昨天／去年的今天分頁、日記卡片含照片與逐字稿、點擊彈出詳細內容與播放語音、空狀態），排入下一輪；需先確認後端 D-2 回傳單篇或列表，以及是否有逐字稿欄位（目前 `DiaryReviewItem` 為單篇且只有 `postText`）
- 儲存圖片目前只在網頁上測試（Chrome 會直接下載），手機上存進相簿需另外處理
- Facebook、複製連結待後端提供 `share_url`
- 低優先度視覺細節：首頁卡片高度與圖示（比賽版用 `history_edu`）、上傳照片外框、錄音完成鈕下方「完成」文字、暫停時「重新錄製」造成版面跳動、第 2 輪後縮小照片高度
- 尚未全面確認是否有檔案直接寫死舊主色 `0xFF5B9E87`（沒有透過 `AppTheme.primaryColor`）

### 給接手組員的提醒
- `AppTheme.primaryColor` 被全專案約 26 個檔案使用（包含遊戲頁面），這次改色會連帶讓遊戲頁面變深，是否全 App 統一待組內確認；整理菜籃的暫時測試色 `_testPrimaryColor`（`0xFF2E5940`）若決定統一，可一併改用 `AppTheme.primaryColor`
- 改了 `const` 常數（例如主色）之後，hot reload 不一定會更新，要用大寫 `R` 做 hot restart
- 聊天頁的下方區塊會依錄音狀態增減按鈕，之後在錄音區新增任何元件，都要確認最新訊息仍會被捲到可見範圍
- 比賽版 futureQ 在本機執行需要 Python 3.10 以上、`requirements.txt`（含 Whisper，安裝時間較長）、ffmpeg（加入 PATH），以及 `.env` 的 OpenAI 金鑰；只看畫面的話可以不填金鑰，直接用網址進各頁（例如 `/finish/?diary_id=167`）

---

## Wen（整理菜籃：配合後端計分修正／商品改用去背圖片；底部導覽列與首頁卡片套用字體縮放、深色模式、高對比）— 2026/09/30

### 本次異動目標
- 9/23 會議發現整理菜籃計分異常（實測答對 27/28 得 79 分、答對 4/28 得 77 分），分析後由後端筠淇在 `feat/game/market-sort-scoring-fix` 分支做「短期、不改玩法」的計分修正，前端配合調整送出的資料與錯誤處理。
- 整理菜籃 28 項商品從 emoji 換成去背 PNG 圖片。
- 底部導覽列、首頁卡片接上設定頁的字體縮放、深色模式、高對比。

### 計分問題原因（前端這邊需要知道的部分）
- 主因：現在的玩法籃子會跟著規則換，前端 `market_sort_answer_judge.dart` 永遠判不出 `persistent` 錯誤，`persistent_error_rate` 恆為 0，每個人固定多拿約 21 分。後端這次先把這項指標拿掉，改用整體正確率。
- 其他原因（常模假資料太寬、z 分數沒有上下限、repeat 題答錯不扣分）都在後端處理，完整分析見文件「整理菜籃計分問題與修改建議」。
- 修正後實測：幾乎全對與幾乎全錯的分數已有明顯落差。

### 新增檔案
- `assets/images/game/market_sort/*.png`：28 張商品圖（512×512 去背 PNG，每張約 50–140 KB），檔名與商品對照見 `market_sort_item_pool.dart` 的 `imageAsset` 欄位

### 修改檔案
- `lib/features/game/market_sort/controllers/market_sort_game_controller.dart`：新增 `recordedTrialType`，第 1 題（沒有上一題）送給後端時記成 `repeat`；原本的 `isRepeatTrial` 不動，只用來決定鎖定時間，所以第 1 題仍維持 1 秒
- `test/features/game/market_sort/controllers/market_sort_game_controller_test.dart`：新增「第1題記錄成repeat，但鎖定時間仍維持1秒」測試（共 9 個測試全數通過）
- `lib/screens/market_sort_game_screen.dart`：`_submitAndShowResult()` 送出失敗時改顯示「成績送出失敗，請確認網路後再試一次」＋「重試」按鈕，原始錯誤只 `debugPrint` 到終端機；開頭加上 `_isSubmitting` 防呆，避免連按重試重複送出（後端對同一 `session_id` 有冪等處理）
- `lib/features/game/market_sort/models/market_sort_item_pool.dart`：28 項商品全部補上 `imageAsset`，emoji 保留當作備援
- `lib/core/assets/item_visual_resolver.dart`：`Image.asset` 加上 `errorBuilder`，圖片路徑錯誤或檔案漏放時退回顯示 emoji；emoji 備援縮為圖片尺寸的 55%，避免撐出圓形卡片
- `lib/features/game/market_sort/widgets/product_card.dart`：商品卡放大（遊戲畫面圓形 180／圖片 140；教學彈窗 compact 版圓形 95／圖片 74）
- `lib/screens/main_screen.dart`：底部導覽列用 `ListenableBuilder` 監聽三個設定；深色配色與 `TopBar` 一致（底色 `0xFF1E1E1E`、選中綠色 `0xFF4CAF50`、未選中 `0xFFCCCCCC`）；高對比時未選中項目改純黑／純白；文字改用 `AppSettings.scaleFont(12)`，系統字體縮放上限從 1.25 降到 1.0 避免雙重放大，並用 `FittedBox` 確保最大字級時「聲影日記」不被截斷；`withOpacity` 改為 `withValues(alpha:)`
- `lib/features/home/widgets/daily_suggestion_card.dart`、`lib/features/home/widgets/game_card.dart`：兩張卡片各自加上 `ListenableBuilder`；深色模式沿用聲影日記的深綠底容器配色（底色 `0xFF25382E`、文字 `0xFFB8E6D0`）；字體改用 `AppSettings.scaleFont()`；高對比時文字純黑／純白加粗並加 2px 外框
- 5 支 service（`auth_service.dart`、`diary_service.dart`、`go_to_market_service.dart`、`market_shopping_service.dart`、`market_sort_api_service.dart`）：後端 trycloudflare 測試網址更新
- `pubspec.yaml`：assets 新增 `assets/images/game/market_sort/`
- `.gitignore`：新增 `_raw_market_sort/`（本機去背用的原圖資料夾，不進版控）

### 目前狀態
- `flutter test test/features/game/market_sort/` 9 個測試全數通過；本次修改的檔案 `flutter analyze` 皆無問題
- 已手動測試：整理菜籃完整一局（圖片顯示、教學彈窗、送出成績）；設定頁切換字體大小／深色模式／高對比後，底部導覽列與首頁卡片即時更新

### 已知延後項目
- 後端計分修正還在 `feat/game/market-sort-scoring-fix` 分支，待合併後正式環境才會套用新公式
- 整理菜籃、市場買菜、來去菜市場三款遊戲的畫面尚未套用字體縮放／深色模式
- 豬肉的圖目前看起來像培根、牛肉偏褐色（顏色題答案是紅），之後可能重畫
- 整理菜籃的籃子圖案還是 emoji
- 長期是否改成「固定兩籃」玩法待組內決定；`market_sort_answer_judge.dart` 的 persistent 判斷先保留，改玩法後可以直接沿用
- `market_sort_api_service.dart` 的網址仍是寫死的 trycloudflare 網址

### 給接手組員的提醒
- 新增 asset 圖片後 hot reload／hot restart 都讀不到，要重新 `flutter run`；`pubspec.yaml` 裡 `assets/images/` 不包含子資料夾，新資料夾要另外宣告
- 教學彈窗高度固定，`ProductCard` 的 compact 圓形超過約 100 就會出現 BOTTOM OVERFLOWED
- 其他頁面要套用設定，可以比照這次的做法：`ListenableBuilder` 監聽 `AppSettings.fontSizeLevel`／`isDarkMode`／`isHighContrast`，文字用 `AppSettings.scaleFont()`，深色配色沿用 `0xFF121212`（頁面底）／`0xFF1E1E1E`（卡片、列）／`0xFF4CAF50`（綠色）／`0xFF25382E`（淺綠容器）
- `pubspec.lock` 切分支時常被自動改動，commit 時不要用 `git add .`，明確列出檔案

---
## Wen（聲影日記：串接真實後端 API／新增登入狀態檢查／修正 CORS 與錄音格式問題）— 2026/09/23

### 本次異動目標
- 把聲影日記核心流程（上傳照片→AI 問答→生成日記→完成分享）從假資料全面換成呼叫後端真實 API（D-1／D-3／D-5／D-7），D-2／D-4／D-6 待後端補齊前維持假資料。
- 新增 App 啟動時的登入狀態檢查，避免未登入直接看到主畫面。
- 排除串接過程中遇到的一連串環境問題：CORS、音訊上傳格式、後端回應欄位缺漏。

### 新增檔案
- `lib/features/auth/pages/auth_gate.dart`：App 啟動時的登入狀態檢查，有 token 就直接進主畫面，沒有就導去身分選擇頁
- `lib/features/diary/pages/diary_loading_page.dart`：生成日記時的等待畫面（旋轉齒輪動畫），呼叫 D-7 `finalizeDiary`
- `lib/features/diary/pages/diary_finish_page.dart`：完成頁（分享卡片預覽、朗讀貼文、分享日記），使用 `flutter_tts`、`share_plus`

### 修改檔案
- `lib/main.dart`：`home` 從固定的 `MainScreen` 改成 `AuthGate`；`voiceDiaryChat` 路由改成傳遞完整 `DiaryModel` 而非單純 `diaryId`；新增 `voiceDiaryLoading`／`voiceDiaryFinish` 路由
- `lib/features/diary/services/diary_service.dart`：D-1／D-3／D-5／D-7 改接真實後端；新增統一的 `_unwrap()` 解析 `{"data":...}`／`{"error":...}`／DRF 的 `{"detail":...}` 三種回應格式；`_fillMissingDiaryFields()` 補上以 `created_at` 推算 `date` 的容錯（部分後端回應目前沒有 `date` 欄位）；`submitReply()` 明確指定音訊 `contentType` 為 `audio/webm`，避免後端收不到有效檔案
- `lib/features/diary/pages/diary_chat_page.dart`：建構子從 `required diaryId`（int）改成 `required initialDiary`（`DiaryModel`），不再呼叫尚未提供的 D-4，直接用建立日記時（D-3）回傳的資料進聊天室
- `lib/features/diary/pages/diary_upload_page.dart`：導航到聊天室時改傳完整 `DiaryModel`（原本只傳 `diaryId`）
- `lib/features/diary/pages/diary_home_page.dart`：`_loadMonth()` 補上 `try/catch`，讀取失敗時顯示「讀取失敗，請檢查登入狀態後再試一次」＋重新載入按鈕，取代原本失敗時卡死在轉圈圈的問題
- `lib/features/diary/widgets/record_button.dart`：錄音編碼改用 `AudioEncoder.opus`（Chrome 的 `MediaRecorder` 不支援預設的 AAC）；`_completeRecording()` 包裝錄音結果時明確指定 `XFile` 的 `name`／`mimeType`（Web 上 `stop()` 回傳的是沒有副檔名的 blob 網址，不指定會讓後端判斷不出這是音訊檔）
- `lib/features/auth/services/auth_service.dart`：登入／註冊網址更新為後端目前的 Cloudflare Tunnel 網址
- `pubspec.yaml`：新增 `flutter_tts`、`share_plus`、`http_parser`

### 排除的環境問題
- CORS：後端 Django 需要 `django-cors-headers` 開放 Flutter Web 的來源；圖片所在的 Google Cloud Storage bucket 是另一個獨立的 CORS 設定，要另外用 `gsutil cors set` 開放跨網域讀取，兩者要分開設定
- 建立日記（D-3）回應目前只有 `created_at` 沒有 `date` 欄位，`DiaryModel.fromJson` 對 `date` 的強制轉型會直接噴例外，前端改用 `created_at` 推算補上
- 錄音送出（D-5）400 錯誤：Web 上 `XFile` 包 blob 網址沒有副檔名／Content-Type，後端判斷不出音訊格式而拒收，改為明確指定 `name`／`mimeType` 與 `contentType`

### 目前狀態
- 已完成真人手動測試：登入→聲影日記首頁→上傳照片→AI 問答（含第一輪 15 秒門檻）→生成日記→完成頁，全流程跑通
- 測試時發現：錄音若沒有實際講話內容，Whisper 轉譯出空字串，後端會判斷「沒有有效回覆」拒絕生成日記（`NO_VALID_REPLY`），這是後端合理的驗證邏輯，不是前端 bug，測試時需要真的對著麥克風講話

### 已知延後項目
- D-2（動態回顧）、D-4（單篇日記詳情）、D-6（跳過本輪）後端尚未提供，畫面上這幾個功能目前還是假資料
- `finalize` 回應目前沒有 `share_url`，完成頁的分享功能暫時用標題＋內文組字串，之後後端補上再串正式分享連結
- `auth_service.dart`、`diary_service.dart` 的後端網址都還是暫時寫死的 trycloudflare 網址，重開發環境就會換，之後待後端提供正式固定網域再統一改用 `ApiConstants`

### 給接手組員的提醒
- trycloudflare 這類臨時通道網址一換，需要同步更新的檔案是 `auth_service.dart` 和 `diary_service.dart` 兩支
- 之後如果還有新的 multipart 上傳（例如未來要傳影片），記得比照 `record_button.dart` 的做法，明確指定 `XFile` 的 `name`／`mimeType`，不要依賴 Web 端 blob 網址自動推斷
- `diary_service.dart` 的 `_unwrap()`／`_fillMissingDiaryFields()` 是這次串接統一收斂的解析邏輯，之後 D-2／D-4／D-6 換成真實 API 時直接沿用這兩個方法即可

---

## 蘇蘇（合併 goto-market／三款遊戲風格統一／歷史成績 API／後端錯誤格式統一解析）— 2026/09/18

### 本次異動目標
- 把 `goto-market` 分支（來去菜市場：注意力訓練）正式合併進來，讓六大認知領域裡「數學」「執行功能」「注意力」三個領域都能實際進入對應的小遊戲。
- 三款遊戲（市場買菜／整理菜籃／來去菜市場）的暫停選單、結算頁樣式、退出遊戲導航統一。
- 市場買菜補上歷史成績查詢 API。
- 因應後端把三款遊戲的錯誤回應統一成 `{success, data, error:{code, message}}` 格式，前端加上共用解析邏輯。

### 合併 goto-market 分支
- 解決 `lib/main.dart`、`lib/screens/game_home_screen.dart`、`pubspec.yaml`、`pubspec.lock` 的合併衝突，兩邊功能都保留（登入流程、通知鈴鐺、六大領域卡片點擊音效都沒有掉）
- `lib/screens/game_home_screen.dart`：六大領域卡片新增 `domain.id == 'attention'` 分支，導向 `GoToMarketTutorialPage`；「數學」「執行功能」維持原本導向市場買菜／整理菜籃，其餘領域仍是「敬請期待」提示
- `pubspec.yaml`：套件版本取兩邊較新的（`http ^1.6.0`、`audioplayers ^6.8.1`、`shared_preferences ^2.5.5`），assets 補齊 `assets/images/game/market_shopping/`（goto-market 帶進來的魚圖片放在 `assets/images/` 下已涵蓋，不用另外宣告）

### 後端網址更新（4 個檔案）
- `lib/features/auth/services/auth_service.dart`、`lib/features/game/market_shopping/services/market_shopping_service.dart`、`lib/features/game/market_sort/services/market_sort_api_service.dart`、`lib/features/game/go_to_market/services/go_to_market_service.dart`
- 全部改成後端最新的 Cloudflare Tunnel 網址 `stopped-residential-proposal-clients.trycloudflare.com`（go_to_market_service.dart 原本指向的是另一個已經失效的舊網址，這次一併修正）

### 暫停選單樣式統一
- 市場買菜的暫停選單改用共用元件 `lib/features/game/widgets/game_pause.dart`（goto-market 團隊做的正式版，橫向/直向自動排版），刪除原本標記「暫時版」的 `lib/features/game/market_shopping/widgets/game_pause.dart`
- 呼叫端（`market_shopping_memorize_page.dart`／`checkout_page.dart`／`play_page.dart`）呼叫方式完全沒變（`onResume`／`onTutorial`／`onRestart`／`onExit` 參數一致），只改 import

### 結算頁樣式統一 + 退出導航統一
- `lib/features/game/market_shopping/pages/market_shopping_result_page.dart` 改用整理菜籃的 `ResultScoreCard`／`ResultHistoryChart`（fl_chart 折線圖），取代原本自己刻的 `_SimpleLineChartPainter`
- `lib/features/game/market_sort/widgets/result_score_card.dart` 新增 `currentLabel`／`bestLabel`／`unit` 三個可選參數（預設值跟原本一樣是「本次分數」／「最高分數」／「分」），市場買菜傳入「本次正確率」／「最高正確率」／「%」
- 三款遊戲結算頁的「退出遊戲」按鈕統一改成 `Navigator.pushAndRemoveUntil(GameHomeScreen)`，直接清空 route stack 回到六大領域遊戲首頁，不再是 `popUntil(isFirst)`（會跑回登入頁）或單純 `pop()`（來去菜市場原本是跳回上一頁教學頁）

### 市場買菜新增歷史成績 API
- `lib/features/game/market_shopping/models/market_shopping_models.dart` 新增 `HistoryRecord`（score／accuracy／playedAt）與 `HistoryResult`
- `lib/features/game/market_shopping/services/market_shopping_service.dart` 新增 `getHistory()`，帶 `Authorization: Bearer token`
- `market_shopping_result_page.dart` 改成 `StatefulWidget`，進頁面時打 `getHistory()`：讀取中顯示 loading、失敗顯示「無法載入歷史成績」但本次成績正常顯示、取最近 5 筆畫折線圖、最高正確率取全部歷史紀錄的最大值（records 是空的就顯示本次成績）

### 後端錯誤格式統一解析
- 新增 `lib/core/network/api_response.dart`：`ApiException(statusCode, code, message, details)` + `parseEnvelope`／`parseData` 兩個解析函式，對應後端統一後的 `{success, data, error:{code, message}}` 格式，也相容 `market_route` 改版前的純字串 `error` 跟未登入時 DRF 預設的 `{"detail": "..."}`
- 市場買菜、整理菜籃的 service 全部改用 `parseEnvelope` 解析，失敗時丟出 `ApiException`，畫面上 `catch (e) { ... e.toString()... }` 的顯示邏輯不用改，玩家會看到後端給的中文訊息（例如「查無此遊戲局次」）而不是整包原始 JSON
- 來去菜市場的 5 支 API 內部改用 `parseData`，但刻意保留原本「內部 catch 掉、回傳 null、呼叫端 fallback 成本地生成題目／本地計分」的離線優先設計不變，只是 debugPrint 現在會印出後端真正的錯誤代碼跟訊息

### 目前狀態
- 已用 `flutter analyze` 確認全專案 0 error，只剩合併前就存在的既有 lint 提示（65 項，數量沒有變化）
- 已用 curl 直接打過新網址確認 4 支網址都能連上，也確認過後端新的 `SESSION_NOT_FOUND` 錯誤格式（HTTP 404，`{"success":false,"data":null,"error":{"code":"SESSION_NOT_FOUND","message":"..."}}`）能被前端正確解析

### 已知延後項目
- 後端錯誤代碼文件裡 `market_route` 的第 4 支端點 `result`（會回傳 `SESSION_NOT_FOUND`／`SESSION_NOT_FINISHED`）前端目前沒有對應的呼叫方法，之後要接再補
- 目前只是把 `error.code`／`error.message` 結構化解析出來、訊息顯示更準確，沒有針對特定 code 做導頁或其他分支邏輯（例如 `SESSION_NOT_FOUND` 時自動導回首頁），之後有需要再加
- `market_shopping_service.dart` 的 `startGame`／`submitItemAnswer`／`submitChangeAnswer` 目前沒有帶 `Authorization` token（跟 `getHistory()` 不一樣），如果後端這三支也要求登入驗證，要再補上

### 給接手組員的提醒
- 三款遊戲的 service 現在都共用 `lib/core/network/api_response.dart`，之後後端錯誤格式再變動，原則上只需要改這一個檔案，不用三個 service 分別改
- `change.md` 裡蘇蘇之前寫的「`trycloudflare.com`類臨時通道網址會過期或換掉」這則提醒依然有效（這次就是因為網址換了才觸發這輪更新），下次網址再換，需要更新的檔案是上面列的那 4 個

---

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
## Wen（整理菜籃：靜態元件／拖曳互動／隨機規則／API串接）— 2026/09/16

### 新增檔案
- `lib/features/game/market_sort/widgets/`：`market_sort_top_bar.dart`、`game_progress_header.dart`、`rule_badge.dart`、`basket_row.dart`、`product_card.dart`、`countdown_digit.dart`、`tutorial_modal.dart`（兩頁式玩法教學，含PageView切換與商品移動動畫）、`pause_modal.dart`（暫停選單，退出二次確認尚未做）
- `lib/features/game/market_sort/controllers/market_sort_game_controller.dart`：單題狀態機（locked/interactive/resolved）、計時、判定邏輯，含測試 `market_sort_game_controller_test.dart`（8項全過）
- `lib/features/game/market_sort/services/market_sort_answer_judge.dart`：答題判定演算法（persistent/random錯誤類型）
- `lib/features/game/market_sort/services/market_sort_api_service.dart`：串接後端 `POST /api/games/market-sort/submit/`
- `lib/features/game/market_sort/models/market_sort_stage_plan.dart`：新增 `buildMarketSort28QuestionPlan()`，第四階段（隨機混合）改為真正隨機生成，每2~3題一組同規則、組間規則不重複，取代原本寫死的固定序列
- `lib/core/services/token_storage.dart`：JWT token 存取（`SharedPreferences`）
- `lib/screens/market_sort_game_screen.dart`：整合畫面，串接controller狀態機、`Draggable`/`DragTarget`拖曳判定、動態依規則產生籃子（種類/顏色各3籃、生熟2籃留白維持版位）、音效、5秒逾時提示、暫停/教學彈窗
- `lib/screens/market_sort_result_screen.dart`：結算頁，串接API回傳的分數與歷史成績

### 修改檔案
- `lib/features/game/market_sort/widgets/basket_row.dart`：擴充支援 `DragTarget`、答對/答錯閃光、`compact`模式維持零padding避免教學彈窗溢出
- `lib/features/game/market_sort/widgets/result_score_card.dart`：等級圖示/文字依分數動態變色（綠/橘）
- `lib/features/game/market_sort/widgets/result_history_chart.dart`：加入`fl_chart`折線圖，資料介面對齊API的`recent_scores[]`/`current_score`
- `lib/features/auth/pages/login_page.dart`：補上登入成功後存取JWT token的邏輯（原本完全沒有存）
- `lib/features/home/widgets/game_card.dart`：「菜市場」卡片導向 `GameHomeScreen`
- `lib/screens/game_home_screen.dart`：「執行功能」領域卡片導向整理菜籃（其餘五個領域維持TODO）
- `lib/main.dart`：註冊 `AppRoutes.gameMarketSort` 命名路由
- `pubspec.yaml`：新增 `fl_chart`、`shared_preferences`、`uuid`

### 目前狀態
- 已完成真實API串接測試（後端：筠淇），能登入、玩完28題、送出成績、顯示結算頁與歷史成績折線圖
- 已測試：完整流程（登入→首頁→執行功能→整理菜籃→結算頁）在Chrome跑通，拖曳判定、規則切換音效、5秒逾時提示、暫停/教學彈窗皆正常

### ⚠️ 待後端確認的計分異常（已回報筠淇，附逐題測試資料）
- 兩次真實測試：28題27對1錯→79分；28題4對24錯（正確率14.3%）→77分。正確率差距極大，分數卻幾乎一樣，不符合設計文件Step5「z=-2→10分下限」的預期
- `encouragement_tier` 在分數退步（87→77）時仍回傳`good`，疑似沒有正確依「本次分數－最高分數」判斷
- 懷疑常模假資料設定過寬鬆，或加權公式/z分數計算有誤，需筠淇檢查後端邏輯

### 已知延後項目
- `pause_modal.dart` 退出遊戲二次確認彈窗
- `tutorial_modal.dart` 商品移動到籃子的動畫（此項實際上已完成，見上方新增檔案說明）
- `_testPrimaryColor`（`0xFF2E5940`）暫時測試色，散落在 `pause_modal.dart`、`result_score_card.dart`、`result_history_chart.dart` 三個檔案，待組員提供正式色碼後統一替換
- 暫停時 `Stopwatch` 未真正凍結（用重新倒數緩解，非精確解法）
- 首次進入自動教學（`has_seen_market_sort_tutorial`）尚未接local storage判斷
- 中途退出（`is_complete: false`）尚未送出API，待與筠淇對齊該情境的後端行為
- 一般按鈕點擊音效尚未全面接上（僅答對/答錯/規則切換三種）

### 給接手組員的提醒
- `game_card.dart`／`game_home_screen.dart` 目前的導航是MVP暫時接法，「菜市場」卡片直接連到遊戲首頁、「執行功能」直接連到整理菜籃，之後若六大領域有各自對應的正式遊戲，這裡要重新設計
- API串接遇到401時要先分辨是`"Token is invalid"`還是`"Token is expired"`，兩者原因不同（前者可能是假token或格式錯，後者是token過期需重新登入）
- `trycloudflare.com`類臨時通道網址會過期或換掉，`auth_service.dart`與`market_sort_api_service.dart`裡目前都是暫時寫死網址，待後端提供正式固定網域後要一併更新並改用`ApiConstants`
## 欣紜（Go to Market 遊戲頁面：題號字串修復與介面簡化）— 2026/09/17

### 本次異動目標
- 修復 `go_to_market_game_page.dart` 頂部題號的字串插值問題，解決終端機／命令列在編譯時因解析 `$` 符號導致的字面亂碼。
- 簡化遊戲頂部導航列介面，移除右上角的「快升」進度狀態標籤，使畫面維持清爽。

### 新增與變更檔案
- `lib/features/game/go_to_market/pages/go_to_market_game_page.dart`：
  - 將頂部題號顯示改為 `.toString()` 字串串接：`currentQuestionNumber.toString() + ' / ' + totalQuestions.toString()`。
  - 移除頂部導航列中負責渲染「快升」標籤的 `Container` 區塊。

### 目前狀態
- 已經過本地模擬器測試，題號能正確呈現（如 `1 / 20`），右上角快升標籤已順利移除。
- 已完成專案暫存清理與相依套件重建（`flutter clean` / `flutter pub get`），執行穩定正常。

### 給接手組員的提醒
- 若未來在 Dart 程式碼中遇到終端機因轉譯產生變數顯示異常時，可直接優先採用 `.toString()` 進行字串串接以確保編譯一致性。

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