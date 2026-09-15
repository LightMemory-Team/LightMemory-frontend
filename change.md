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