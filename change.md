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