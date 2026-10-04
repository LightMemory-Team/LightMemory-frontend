# 前端待辦清單（整合後）

> 整理人：Wen｜整理日期：2026/10/05
> 依據：`integrate/frontend-1004` 分支（整合 Wen／欣紜冰箱清點／蘇蘇料理準備後）的全專案檢查

---

## 一、已決定的方向

- **字體縮放改成全域處理**：在 `main.dart` 統一設定整個 App 的文字縮放倍率，所有頁面（含五款遊戲）自動跟著放大，不再逐頁呼叫 `AppSettings.scaleFont()`。
- **遊戲畫面暫時不做深色模式**：五款遊戲的配色是設計好的場景（菜市場、冰箱、廚房），寫死的色碼有數百處，先維持原本配色。深色模式只做一般頁面。

---

## 二、字體縮放、深色模式的套用狀況

目前做法是每一頁自己監聽 `AppSettings`，用 `scaleFont()`、`isDarkMode` 判斷。`MaterialApp` 只設定淺色主題，沒有 `darkTheme`。

**已套用**
- 聲影日記：所有頁面與元件
- 首頁：頂部列、問候、每日建議卡片、遊戲卡片
- 底部導覽列、設定頁、通知頁、動態牆貼文卡片

**尚未套用（之後要做）**
- 遊戲首頁 `lib/screens/game_home_screen.dart` 與它的 4 個元件：
  - `lib/features/game/widgets/game_top_bar.dart`
  - `lib/features/game/widgets/domain_card.dart`
  - `lib/features/game/widgets/training_progress_card.dart`
  - `lib/features/game/widgets/game_bottom_actions.dart`
- 登入相關：`identity_select_page.dart`、`login_page.dart`、`register_page.dart`、`welcome_page.dart`（`lib/features/auth/pages/`）
- 新手教學：`tutorial_intro_page.dart`、`lib/features/auth/widgets/tutorial_overlay.dart`

**尚未套用（暫不處理深色模式，字體由全域縮放處理）**
- 整理菜籃、市場買菜、來去菜市場、冰箱清點、料理準備五款遊戲的所有頁面

---

## 三、待辦項目

### A. 字體縮放全域化
- [ ] `main.dart` 的 `MaterialApp` 加上 `builder`，依 `AppSettings.fontSizeLevel` 設定全 App 的 `textScaler`
- [ ] `AppSettings.scaleFont()` 改成不再自己放大（避免已套用的頁面放大兩次）
- [ ] `main_screen.dart` 底部導覽列原本為了避免雙重放大，把系統縮放上限降到 1.0，全域化後要一起檢查
- [ ] 五款遊戲逐款在「超大（145%）」下檢查有沒有文字溢出（`OVERFLOWED`）

### B. 深色模式（一般頁面）
- [ ] 遊戲首頁＋4 個元件（9/30 開會發現：遊戲首頁完全沒套用深色模式和字級）
- [ ] 登入、註冊、身分選擇、歡迎頁
- [ ] 新手教學引導頁、教練標記疊加層
- [ ] 評估 `MaterialApp` 是否加上 `darkTheme`＋`themeMode`，減少逐頁判斷

### C. 共用元件統一

**遊戲進行中的頂部列（目前 4 種做法）**
- `GameInProgressTopBar`（`lib/features/game/market_shopping/widgets/`）：市場買菜、料理準備在用
- `MarketSortTopBar`：整理菜籃專用，跟上面幾乎一樣，只差標題寫死、返回圖示不同
- 冰箱清點：用 Flutter 內建 `AppBar` 自己刻
- 來去菜市場：畫面裡自己排，沒有獨立元件
- [ ] 建議統一成 `GameInProgressTopBar`，並移到 `lib/features/game/widgets/` 當共用元件

**暫停選單（目前 2 種）**
- `GamePause`（`lib/features/game/widgets/game_pause.dart`）：市場買菜、來去菜市場、冰箱清點、料理準備在用
- `PauseModal`：只有整理菜籃在用，退出的二次確認還沒做
- [ ] 整理菜籃改用 `GamePause`，刪除 `pause_modal.dart`

**結算頁（目前 3 種，之後討論）**
- 整理菜籃、市場買菜：共用 `ResultScoreCard`＋`ResultHistoryChart`
- 來去菜市場：彈窗 `MarketResultDialog`＋自己畫的折線圖
- 冰箱清點：自己的 `fridge_result_page.dart`
- [ ] 是否統一樣式，待組內討論

### D. 寫死的舊色碼
- [ ] `_testPrimaryColor`（`0xFF2E5940`）還在 `pause_modal.dart`、`result_score_card.dart`、`result_history_chart.dart`，改用 `AppTheme.primaryColor`
- [ ] `training_progress_card.dart` 的進度條寫死舊主色 `0xFF5B9E87`（遊戲首頁進度條還是淺綠的原因），改用 `AppTheme.primaryColor`
- 註：整理菜籃籃子用的 `0xFF5B9E87`（蔬菜籃、綠色籃、生食籃）是分類顏色，不是主色，**不要改**

### E. 橫向鎖定
- 來去菜市場、料理準備各自在 `initState` 鎖橫向、`dispose` 設回直向
- [ ] **Bug**：`go_to_market_tutorial_page.dart` 的 `dispose()` 沒有設回直向，只有按畫面上的返回按鈕才會改。用 Android 系統返回鍵或手勢離開，遊戲首頁會停在橫向
- [ ] 建議做成共用工具，所有橫向遊戲用同一套鎖定與還原
- 註：`main.dart` 開機時已強制設回直向（處理 hot restart 殘留），這行要保留

### F. 其他
- [ ] `linux/`、`macos/`、`windows/` 的 plugin 檔案每次 `flutter run` 都會變動，找時間統一 commit 一次
- [ ] `flutter analyze` 剩下的都是 `info`：冰箱清點與登入服務大量使用 `print`、來去菜市場用 `+` 接字串（9/17 為了避開 `$` 問題刻意改的）。不影響執行，有空再整理
- 各遊戲自己的延後項目，見 `change.md` 各筆紀錄的「已知延後項目」

---

## 四、建議順序

1. D 舊色碼（改動最小）
2. B 遊戲首頁深色模式
3. A 字體縮放全域化
4. C 頂部列、暫停選單統一
5. E 橫向鎖定共用
6. B 登入、註冊、教學頁深色模式

C、E 會動到其他組員寫的檔案，動手前先在群組說一聲，避免同時改到同一支檔案。
