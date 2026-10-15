# 前端待辦清單（整合後）

> 整理人：Wen｜整理日期：2026/10/05，2026/10/06、10/07、10/09、10/14、10/15、10/16 更新
> 依據：`integrate/frontend-1004` 分支（整合 Wen／欣紜冰箱清點／蘇蘇料理準備後）的全專案檢查；10/6 起以 `fix/session-id-uuid`（JWT token、session_id 改 UUID 字串）為基礎，在 `fix/pre-meeting-1006` 繼續修正；10/14 起新功能在 `feature/wen-diary-review-share`

---

## 一、已決定的方向

- **字體縮放改成全域處理**：在 `main.dart` 統一設定整個 App 的文字縮放倍率，所有頁面（含五款遊戲）自動跟著放大，不再逐頁呼叫 `AppSettings.scaleFont()`。
- **遊戲畫面暫時不做深色模式**：五款遊戲的配色是設計好的場景（菜市場、冰箱、廚房），寫死的色碼有數百處，先維持原本配色。深色模式只做一般頁面。
- **登入相關頁面、新手教學暫時不做深色模式**（10/7 決定）：身分選擇、登入、註冊、歡迎頁、新手教學引導頁、教練標記疊加層維持淺色。
- **後端網址集中管理**：所有 service 都讀 `lib/core/constants/api_constants.dart` 的 `serverUrl`，換後端只改這一行。Cloudflare 臨時網址每次重開都會變，這一行**不要 commit**。

---

## 二、字體縮放、深色模式的套用狀況

目前做法是每一頁自己監聽 `AppSettings`，用 `scaleFont()`、`isDarkMode` 判斷。`MaterialApp` 只設定淺色主題，沒有 `darkTheme`。

**已套用**
- 聲影日記：所有頁面與元件（含 10/14 新增的動態回顧頁 `diary_review_page.dart`）
- 首頁：頂部列、問候、每日建議卡片、遊戲卡片
- 底部導覽列、設定頁、通知頁、動態牆貼文卡片
- 遊戲首頁（10/7）：`lib/screens/game_home_screen.dart` 與它的 4 個元件
  - `lib/features/game/widgets/game_top_bar.dart`
  - `lib/features/game/widgets/domain_card.dart`
  - `lib/features/game/widgets/training_progress_card.dart`
  - `lib/features/game/widgets/game_bottom_actions.dart`

**不套用深色模式（字體由全域縮放處理）**
- 整理菜籃、市場買菜、來去菜市場、冰箱清點、料理準備五款遊戲的所有頁面
- 登入相關：`identity_select_page.dart`、`login_page.dart`、`register_page.dart`、`welcome_page.dart`（`lib/features/auth/pages/`）
- 新手教學：`tutorial_intro_page.dart`、`lib/features/auth/widgets/tutorial_overlay.dart`

---

## 三、待辦項目

### A. 字體縮放全域化
- [ ] `main.dart` 的 `MaterialApp` 加上 `builder`，依 `AppSettings.fontSizeLevel` 設定全 App 的 `textScaler`
- [ ] `AppSettings.scaleFont()` 改成不再自己放大（避免已套用的頁面放大兩次）
- [ ] `main_screen.dart` 底部導覽列原本為了避免雙重放大，把系統縮放上限降到 1.0，全域化後要一起檢查
- [ ] 五款遊戲逐款在「超大（145%）」下檢查有沒有文字溢出（`OVERFLOWED`）

### B. 深色模式（一般頁面）
- [x] 遊戲首頁＋4 個元件（9/30 開會發現：遊戲首頁完全沒套用深色模式和字級）（10/7 完成，含高對比與字級）
- [ ] 評估 `MaterialApp` 是否加上 `darkTheme`＋`themeMode`，減少逐頁判斷

### C. 共用元件統一

**遊戲進行中的頂部列（10/9 已統一）**
- `GameInProgressTopBar`（`lib/features/game/widgets/`）：整理菜籃、市場買菜、料理準備、冰箱清點在用
- 來去菜市場是橫向畫面，只把返回箭頭換成 `GameMenuButton(compact: true)`
- [x] 統一成 `GameInProgressTopBar`，移到 `lib/features/game/widgets/` 當共用元件；刪除 `MarketSortTopBar` 和 `market_shopping/widgets/` 裡的舊版
- [x] 老師建議（10/8）：遊戲左上角的返回按鈕改成深綠色的「選單」按鈕（`GameMenuButton`），點擊後打開 `GamePause`

**教學頁左上角的按鈕（10/9 發現，各遊戲不一致，待組內討論）**
- 冰箱清點教學頁：箭頭，點下去打開暫停選單
- 來去菜市場教學頁：箭頭，點下去直接返回上一頁
- 整理菜籃、市場買菜、料理準備的教學彈窗：箭頭，點下去回到教學上一頁（第一頁不顯示）
- 整理菜籃的教學流程本身也跟其他遊戲不太一樣
- [ ] 討論統一規則：按鈕上的字要跟按下去發生的事一致（例如會開暫停選單就寫「選單」、彈窗翻頁就寫「上一頁」），只有圖示長輩不容易看懂
- [ ] 依討論結果修改各遊戲教學頁

**暫停選單（10/7 已統一）**
- `GamePause`（`lib/features/game/widgets/game_pause.dart`）：五款遊戲都在用
- [x] 整理菜籃改用 `GamePause`，刪除 `pause_modal.dart`

**結算頁（目前 3 種，之後討論）**
- 整理菜籃、市場買菜：共用 `ResultScoreCard`＋`ResultHistoryChart`
- 來去菜市場：彈窗 `MarketResultDialog`＋自己畫的折線圖
- 冰箱清點：自己的 `fridge_result_page.dart`
- [ ] 是否統一樣式，待組內討論

### D. 寫死的舊色碼
- [x] `_testPrimaryColor`（`0xFF2E5940`）原本在 `pause_modal.dart`、`result_score_card.dart`、`result_history_chart.dart`，已改用 `AppTheme.primaryColor`（`pause_modal.dart` 已刪除）
- [x] `training_progress_card.dart` 的進度條寫死舊主色 `0xFF5B9E87`（遊戲首頁進度條還是淺綠的原因），改用 `AppTheme.primaryColor`
- 註：整理菜籃籃子用的 `0xFF5B9E87`（蔬菜籃、綠色籃、生食籃）是分類顏色，不是主色，**不要改**

### E. 橫向鎖定
- 來去菜市場、料理準備各自在 `initState` 鎖橫向、`dispose` 設回直向
- [x] **Bug**：`go_to_market_tutorial_page.dart` 的 `dispose()` 沒有設回直向，用 Android 系統返回鍵或手勢離開，遊戲首頁會停在橫向
  - 10/6 已修正並 commit：新增 `openedFromGame` 參數，依離開方式決定要不要設回直向；同時修正從遊戲內開啟教學再按「開始挑戰」會疊出第二個遊戲頁的問題
  - 待 Android 實機或模擬器測試，見「五、待測試清單」
- [ ] 建議做成共用工具，所有橫向遊戲用同一套鎖定與還原（目前 `go_to_market_game_page.dart`、`go_to_market_tutorial_page.dart`、`cooking_prep_game_page.dart` 各自呼叫 `setPreferredOrientations`）
- 註：`main.dart` 開機時已強制設回直向（處理 hot restart 殘留），這行要保留

### F. 其他
- [ ] `linux/`、`macos/`、`windows/` 的 plugin 檔案每次 `flutter run` 都會變動，找時間統一 commit 一次
- [ ] `flutter analyze` 剩下的 `info`：`print` 18 處（`fridge_inventory_service.dart`；`auth_service.dart` 的 4 處 10/16 已改成 `debugPrint`）、`auth_service.dart` 註冊參數的 `if (x != null)` 寫法（`use_null_aware_elements`，第 30–34 行），來去菜市場用 `+` 接字串（9/17 為了避開 `$` 問題刻意改的）。不影響執行，有空再整理
- [x] `market_sort_game_screen.dart` 的 `_seedFakeTokenForTesting()` 是測試時留下的，沒有地方呼叫（10/9 連同 `token_storage.dart` 的 import 一起刪除）
- [ ] 冰箱清點連不上後端時，錯誤畫面會顯示開發用的測試按鈕和原始錯誤訊息（`ClientException...`）：`fridge_game_page.dart` 的三顆「測試成績頁」按鈕用 `kDebugMode` 包起來，錯誤訊息（目前直接顯示 `$e`）改用共用的 `friendlyErrorMessage()`（`lib/core/network/error_message.dart`，10/16 新增）
- [x] 錯誤提示直接顯示原始錯誤（`ClientFailed to fetch, uri=https://...`、`Exception: ...`），長輩看不懂還會露出後端網址：新增共用 `friendlyErrorMessage()`，套用到註冊、登入、聊天室送出／跳過、完成頁分享、錄音按鈕（10/16）；其他頁面之後新增錯誤提示也一律用它
- [x] Android 建置暫存資料夾 `android/build/` 出現在 `git status`：`android/.gitignore` 加入 `/build/`（10/9）
- [x] 整理菜籃三個籃子在一般手機寬度下溢出：`basket_row.dart` 改成平分寬度、放不下時等比例縮小（10/9）
- [ ] 菜市場購物的 `warning`：`market_shopping_game_page.dart` 沒用到的 `tutorial_preference.dart` import、`market_shopping_memorize_page.dart` 沒用到的 `dart:async` import、`market_shopping_play_page.dart` 的 `_result` 有設值但沒被讀取（刪之前先確認原本用途）
- [ ] 聲影日記的 `warning`：`diary_chat_page.dart` 沒用到的 `_isDone`、`_isFinalizable`；`diary_finish_page.dart` 大量「不可能是 null 卻判斷 null」（model 欄位改成不可為 null 後頁面沒跟著改）；`diary_loading_page.dart` 沒用到的 `diary_model.dart` import（`intl` 見 I）
- [ ] 新手教學的 `warning`：`tutorial_overlay.dart` 沒用到的 `isLastStep`（第 97 行）、3 處 `withOpacity`（10/16 analyze `lib/features/auth` 時看到）
- 各遊戲自己的延後項目，見 `change.md` 各筆紀錄的「已知延後項目」

### G. 聲影日記（10/6 測試發現）
- [x] 對話泡泡的錄音播放鍵只能播放、不能停止：`chat_bubble.dart` 新增 `isPlaying`，播放中顯示停止圖示；`diary_chat_page.dart` 記錄正在播放哪一則，再按一次停止、播完自動變回播放圖示、開始錄音時自動停止播放（10/7，待後端測試）
- [x] 按「保存照片」後上傳要等一陣子，原本按鈕只有白色小轉圈，在淺灰停用底色上幾乎看不見：`diary_upload_page.dart` 改成轉圈加「照片上傳中，請稍候…」，顏色改用 `disabledText`（10/7，待後端測試）
- 註：10/7 會議說的是錄音播放要能「暫停」，目前做的是「停止」（再按從頭播）；每輪錄音頂多幾十秒，先維持停止，組員有意見再改成暫停

### H. API 串接（10/6 整理）

**已完成（`fix/jwt-token-headers`、`fix/session-id-uuid`）**
- 來去菜市場、菜市場購物補上 JWT `Authorization` header，五款遊戲與聲影日記都有帶 token
- 菜市場購物、來去菜市場、料理準備的 `session_id` 改成 UUID 字串（`String`）
- 來去菜市場收到 401 時，跳出「登入已過期」對話框，可選擇重新登入或繼續練習

**待處理**
- [x] 菜市場購物拿不到 `session_id` 時直接丟錯，不要用空字串繼續（否則會打到 `/sessions//item-answers/`，只得到看不懂的 404）：`lib/features/game/market_shopping/models/market_shopping_models.dart` 的 `GameSession.fromJson`
- [ ] 401 重新登入提示目前只有來去菜市場有，其他四款遊戲與聲影日記要補上，建議做成共用元件（「沒有 token」的 `NotLoggedInException` 和後端回 401 要一起處理）
- [x] **Bug**（10/16 發現並修正）：註冊成功後沒有登入也沒有存 token，直接進歡迎頁 → 新手教學 → 主畫面，所有需要登入的 API 都會失敗（聲影日記首頁顯示「讀取失敗，請檢查登入狀態」）。`auth_service.dart` 新增 `loginAndSaveToken()`（登入頁、註冊頁共用），註冊成功後自動登入並存 token；自動登入失敗時提示「註冊成功！請用剛才的帳號密碼登入」並帶到登入頁
- [x] 讀 token 組 header 的寫法原本有六份，合併成 `lib/core/network/auth_headers.dart` 的 `authHeaders()`；沒有 token 時丟出 `NotLoggedInException`，不送出請求（10/9）
- [ ] refresh token 目前沒存，token 過期只能重新登入。後端設定 access token 2 小時、refresh token 7 天（`config/settings.py` 的 `SIMPLE_JWT`），2 小時對長輩偏短，建議下次整合時處理
- [x] ~~問後端：使用者相關 API 目前是 `AllowAny`~~（10/15 確認）：使用者 API 只有註冊、登入，本來就要開放；其他功能各自有 `IsAuthenticated`。但後端全域預設權限是 `AllowAny`，新增 API 時忘了加權限就會變成公開，已提醒後端

### I. 動態回顧＋分享（10/14 開始，分支 `feature/wen-diary-review-share`）
- [x] 完成頁新增「分享到動態牆」按鈕（S-1 先用假資料）
- [x] 動態回顧改為獨立頁面（D-2 改陣列格式，先用假資料）
- [x] S-1、D-2 接真實 API：`diary_service.dart` 的 `_useMockShareToWall`、`_useMockReview` 改成 `false`，跟詩雅測試（10/15 完成，後端分支 `feat/wall-post-integration`）
- [ ] D-4 單篇詳情：後端已完成（`GET /api/diary/{id}/`），首頁月曆點日期目前只跳提示（`diary_home_page.dart` 的 `_onDiaryTap`），待接上
- [ ] 完成頁 `share_url`：11 月親友分享頁（P-1）完成後再接到 LINE／Facebook／複製連結
- [ ] 一天一篇或多篇日記待組長決定；若一天一篇，後端 D-3 也要擋（目前只有前端擋）
- [x] 月曆有日記的日期改成顯示日記照片＋金色外框（對照比賽版 `.dot-photo`），拿掉「選取」狀態（原本點過的日期會變成深綠圓圈、蓋掉日記標記），今天有日記時也會顯示照片（10/16）
- [ ] 月曆照片蓋住日期數字，長輩要靠位置判斷日期；比賽版也是這樣，先維持，組員覺得不清楚再考慮在照片角落加小數字
- [ ] `pubspec.yaml` 補上 `intl`（完成頁、動態回顧、`main.dart` 都有用到，目前是間接安裝），單獨 commit
- [ ] 開 PR 到 `dev`：要等後端 `feat/wall-post-integration` 合併後再合，不然動態回顧會讀取失敗、分享會失敗

---

## 四、建議順序

1. ~~H 菜市場購物 `session_id` 檢查~~（10/7 完成）
2. ~~C 整理菜籃改用 `GamePause`~~（10/7 完成）
3. ~~D 舊色碼~~（10/7 完成）
4. ~~B 遊戲首頁深色模式~~（10/7 完成）
5. ~~G 聲影日記播放停止、上傳提示~~（10/7 完成，待後端測試）
### 新功能開工前（必做）
6. ~~C 頂部列統一，左上角改成老師建議的「選單」按鈕（打開 `GamePause`）~~（10/9 完成）
7. ~~H 合併讀 token 的寫法（新功能直接用共用 header，避免再多一份）~~（10/9 完成）

### 新功能完成後、下次整合時
8. A 字體縮放全域化（影響全部頁面，要逐款檢查溢出）
9. H 401 重新登入提示做成共用元件（需要後端測試）
10. H refresh token（access token 只有 2 小時，可以跟 9 一起做）
11. E 橫向鎖定共用工具（若新功能有橫向遊戲，改成開工前做）
12. C 教學頁左上角按鈕統一（先跟組員討論規則）
13. F 冰箱清點錯誤畫面改成友善訊息、測試按鈕只在開發時顯示
14. 「五、待測試清單」約後端與 Android 一起測

---

## 五、待測試清單

已修改並 commit，但還沒實際測過的項目。約後端或有 Android 裝置時照這份清單測。

**需要後端**
- [ ] 動態回顧＋分享（詩雅的後端 `feat/wall-post-integration`，10/14）
  - ~~動態回顧：有日記的那天看得到卡片、照片正常；播放、暫停、繼續正常；播放中切換分頁聲音停止~~（10/15 測過）
  - ~~完成頁：按「分享到動態牆」變成「已分享到動態牆」，貼文確實建立；同一篇再分享一次回 200，不重複建立~~（10/15 測過）
  - ~~沒有日記的那天顯示空狀態~~（10/16 用新註冊的帳號測過）
  - ~~深色模式、字級超大時的空狀態~~（10/16 測過）
  - 有日記卡片時的深色模式、字級超大（要先請後端跑 `seed_review_diaries`）
- [ ] 聲影日記（10/7 修正，需要能完整寫日記的後端）
  - 10/16 在詩雅的後端測試時，錄音送出一直回 `TRANSCRIPTION_FAILED`（Whisper 在她電腦上出錯，可能是 ffmpeg），已請她查終端機，修好前以下都測不了
  - 上傳照片時，按鈕顯示轉圈和「照片上傳中，請稍候…」，字和轉圈看得清楚
  - 按自己泡泡的播放鍵，圖示變成停止；再按一次停止播放，圖示變回播放
  - 錄音自然播完，圖示自己變回播放
  - 播第一段時按第二段，第一段停止、第二段開始，只有第二段顯示停止
  - 播放中按麥克風開始錄音，播放會停止
  - 寫完後月曆今天顯示日記照片；再按「今天」進不去（前端擋一天第二篇）
  - 新寫的日記在完成頁按「分享到動態牆」回 201
- [ ] 菜市場購物：正常開局（確認 `session_id` 檢查不會誤擋正常情況）
- [ ] 頂部列「選單」按鈕（10/9）：市場買菜（記憶、購物、結帳三頁）、料理準備、冰箱清點進到遊戲中畫面後
  - 左上角是「☰ 選單」，點下去打開暫停選單，四個按鈕正常
  - 標題置中、右上角鈴鐺點下去進通知頁
- [ ] 共用 `authHeaders()`（10/9）：登入後五款遊戲、聲影日記都能正常呼叫 API（確認 token 有帶上）
  - 聲影日記 10/15 已確認（動態回顧、分享到動態牆帶 token 呼叫成功），五款遊戲待測
- [ ] 沒有 token 時顯示「尚未登入，請重新登入」：原本以為正常操作不會發生，10/16 發現剛註冊的使用者就會遇到（已修正註冊流程）；之後新增登出等會清掉 token 的流程時再確認
- [x] ~~註冊與登入（10/16 修正）~~（10/16 測過）
  - 註冊新帳號後直接進聲影日記，不用重新登入，月曆、動態回顧都能讀取
  - 同一個帳號再註冊一次顯示「這個帳號已經有人使用」；打錯密碼顯示「帳號或密碼錯誤」
  - 連不上後端時，註冊頁、登入頁都顯示「連線失敗，請檢查網路後再試一次」，不再出現網址

**需要 Android 實機或模擬器**
- [ ] 來去菜市場教學頁螢幕方向
  - 遊戲首頁 → 來去菜市場 → 用系統返回鍵或手勢離開 → 遊戲首頁是直向
  - 遊戲首頁 → 來去菜市場 → 略過教學 → 遊戲是橫向
  - 遊戲中按說明 → 返回 → 回到原本的遊戲，維持橫向
  - 遊戲中按說明 → 開始挑戰 → 從第 1 題重新開始 → 暫停 → 退出 → 直接回到遊戲首頁
- [ ] 來去菜市場橫向畫面的小尺寸「選單」按鈕（10/9）：大小、位置是否好按
- [ ] 整理菜籃籃子（10/9）：實機上三個籃子完整顯示、好拖放