# 前端待辦清單（整合後）

> 整理人：Wen｜整理日期：2026/10/05，2026/10/06、10/07 更新
> 依據：`integrate/frontend-1004` 分支（整合 Wen／欣紜冰箱清點／蘇蘇料理準備後）的全專案檢查；10/6 起以 `fix/session-id-uuid`（JWT token、session_id 改 UUID 字串）為基礎，在 `fix/pre-meeting-1006` 繼續修正

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
- 聲影日記：所有頁面與元件
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

**遊戲進行中的頂部列（目前 4 種做法）**
- `GameInProgressTopBar`（`lib/features/game/market_shopping/widgets/`）：市場買菜、料理準備在用
- `MarketSortTopBar`：整理菜籃專用，跟上面幾乎一樣，只差標題寫死、返回圖示不同
- 冰箱清點：用 Flutter 內建 `AppBar` 自己刻
- 來去菜市場：畫面裡自己排，沒有獨立元件
- [ ] 建議統一成 `GameInProgressTopBar`，並移到 `lib/features/game/widgets/` 當共用元件
- [ ] 老師建議（10/8）：遊戲左上角的返回按鈕改成深綠色的「選單」按鈕，點擊後打開 `GamePause`（收納離開與其他功能，操作比較直覺）。統一頂部列時一起做，五款遊戲共用

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
- [ ] 建議做成共用工具，所有橫向遊戲用同一套鎖定與還原
- 註：`main.dart` 開機時已強制設回直向（處理 hot restart 殘留），這行要保留

### F. 其他
- [ ] `linux/`、`macos/`、`windows/` 的 plugin 檔案每次 `flutter run` 都會變動，找時間統一 commit 一次
- [ ] `flutter analyze` 剩下的都是 `info`：冰箱清點與登入服務大量使用 `print`、來去菜市場用 `+` 接字串（9/17 為了避開 `$` 問題刻意改的）。不影響執行，有空再整理
- [ ] `market_sort_game_screen.dart` 的 `_seedFakeTokenForTesting()` 是測試時留下的，沒有地方呼叫，刪除時記得檢查 `token_storage.dart` 的 import 是否也變成沒用到
- [ ] 菜市場購物的 `warning`：`market_shopping_game_page.dart` 沒用到的 `tutorial_preference.dart` import、`market_shopping_memorize_page.dart` 沒用到的 `dart:async` import、`market_shopping_play_page.dart` 的 `_result` 有設值但沒被讀取（刪之前先確認原本用途）
- [ ] 聲影日記的 `warning`：`diary_chat_page.dart` 沒用到的 `_isDone`、`_isFinalizable`；`diary_finish_page.dart` 大量「不可能是 null 卻判斷 null」（model 欄位改成不可為 null 後頁面沒跟著改）；`diary_loading_page.dart` 沒用到的 `diary_model.dart` import；`diary_finish_page.dart` 用到 `intl` 但 `pubspec.yaml` 沒有列
- 各遊戲自己的延後項目，見 `change.md` 各筆紀錄的「已知延後項目」

### G. 聲影日記（10/6 測試發現）
- [x] 對話泡泡的錄音播放鍵只能播放、不能停止：`chat_bubble.dart` 新增 `isPlaying`，播放中顯示停止圖示；`diary_chat_page.dart` 記錄正在播放哪一則，再按一次停止、播完自動變回播放圖示、開始錄音時自動停止播放（10/7，待後端測試）
- [x] 按「保存照片」後上傳要等一陣子，原本按鈕只有白色小轉圈，在淺灰停用底色上幾乎看不見：`diary_upload_page.dart` 改成轉圈加「照片上傳中，請稍候…」，顏色改用 `disabledText`（10/7，待後端測試）

### H. API 串接（10/6 整理）

**已完成（`fix/jwt-token-headers`、`fix/session-id-uuid`）**
- 來去菜市場、菜市場購物補上 JWT `Authorization` header，五款遊戲與聲影日記都有帶 token
- 菜市場購物、來去菜市場、料理準備的 `session_id` 改成 UUID 字串（`String`）
- 來去菜市場收到 401 時，跳出「登入已過期」對話框，可選擇重新登入或繼續練習

**待處理**
- [x] 菜市場購物拿不到 `session_id` 時直接丟錯，不要用空字串繼續（否則會打到 `/sessions//item-answers/`，只得到看不懂的 404）：`lib/features/game/market_shopping/models/market_shopping_models.dart` 的 `GameSession.fromJson`
- [ ] 401 重新登入提示目前只有來去菜市場有，其他四款遊戲與聲影日記要補上，建議做成共用元件
- [ ] 讀 token 組 header 的寫法目前有五份（來去菜市場、菜市場購物、料理準備、冰箱清點、聲影日記各一份），合併成 `lib/core/network/` 裡的一個函式
- [ ] refresh token 目前沒存，token 過期只能重新登入；等組長說明 token 有效期限再決定是否處理

---

## 四、建議順序

1. ~~H 菜市場購物 `session_id` 檢查~~（10/7 完成）
2. ~~C 整理菜籃改用 `GamePause`~~（10/7 完成）
3. ~~D 舊色碼~~（10/7 完成）
4. ~~B 遊戲首頁深色模式~~（10/7 完成）
5. ~~G 聲影日記播放停止、上傳提示~~（10/7 完成，待後端測試）
### 新功能開工前（必做）
6. C 頂部列統一，左上角改成老師建議的「選單」按鈕（打開 `GamePause`）
7. H 合併讀 token 的寫法（新功能直接用共用 header，避免再多一份）

### 新功能完成後、下次整合時
8. A 字體縮放全域化（影響全部頁面，要逐款檢查溢出）
9. H 401 重新登入提示做成共用元件（需要後端測試）
10. E 橫向鎖定共用工具（若新功能有橫向遊戲，改成開工前做）
11. H refresh token（等組長說明 token 有效期限）
12. 「五、待測試清單」約後端與 Android 一起測

---

## 五、待測試清單

已修改並 commit，但還沒實際測過的項目。約後端或有 Android 裝置時照這份清單測。

**需要後端**
- [ ] 聲影日記（筠淇的後端）
  - 上傳照片時，按鈕顯示轉圈和「照片上傳中，請稍候…」，字和轉圈看得清楚
  - 按自己泡泡的播放鍵，圖示變成停止；再按一次停止播放，圖示變回播放
  - 錄音自然播完，圖示自己變回播放
  - 播第一段時按第二段，第一段停止、第二段開始，只有第二段顯示停止
  - 播放中按麥克風開始錄音，播放會停止
- [ ] 菜市場購物：正常開局（確認 `session_id` 檢查不會誤擋正常情況）

**需要 Android 實機或模擬器**
- [ ] 來去菜市場教學頁螢幕方向
  - 遊戲首頁 → 來去菜市場 → 用系統返回鍵或手勢離開 → 遊戲首頁是直向
  - 遊戲首頁 → 來去菜市場 → 略過教學 → 遊戲是橫向
  - 遊戲中按說明 → 返回 → 回到原本的遊戲，維持橫向
  - 遊戲中按說明 → 開始挑戰 → 從第 1 題重新開始 → 暫停 → 退出 → 直接回到遊戲首頁