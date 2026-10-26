# 前端待辦清單

> 整理人：Wen｜10/05 建立，10/20 精簡（已完成的項目移除，紀錄見 `change.md`），10/26 補上 10/21 開會決議
> `integrate/frontend-1019` 已由 PR #15 合進 `dev`（10/21），新分支一律從 `dev` 開

---

## 一、已決定的方向

- **字體縮放改成全域處理**：在 `main.dart` 統一設定整個 App 的文字縮放倍率，所有頁面（含五款遊戲）自動跟著放大，不再逐頁呼叫 `AppSettings.scaleFont()`（尚未實作，見三-之後）。
- **深色模式只做一般頁面**：五款遊戲（場景配色寫死數百處）、登入相關頁面、新手教學維持淺色（10/7）。
- **資訊加油站不做**（10/20）：時間不夠，整個功能砍掉，底部導覽列第 2 格與新手教學第 3 步改為動態牆。
- **時程**（10/21）：10/27 晚上跟老師開會前，先修上週做的功能；10/28～11/04（下次小組開會前）做新功能。
- **刪除親屬端**（10/21）：拿掉家屬模式相關的流程與畫面（Wen、筠淇）。
- **動態牆只看得到自己的貼文**（10/21）：做帳號隔離；拿掉按讚，只留留言（可刪除留言和貼文）。
- **使用者名稱**（10/21）：註冊完再跳一頁「請輸入姓名」，首頁招呼語改用這個名字。
- **點月曆上的日記照片**（10/21）：彈出小視窗，顯示那天的日記內容。
- **日記一天一篇**（10/21）：前端已經擋，後端 D-3 也要擋。
- **登出按鈕放在會員頁**（10/21）：目前在設定頁（組長 PR #14），會員頁做好後搬過去。
- **六大能力說明截圖**（10/21）：放大重要的部分。
- **儀表板常模**（10/21）：多數遊戲的常模還是假的，一開始不顯示目前狀況，用久了才有常模；分數換算 `50 + 25 × z`。
- **AD-8 測驗改成選填**（10/21）：優先度最低，先用已經做好的部分，有時間再補。
- **整理菜籃的分類標準**（10/20）：以「一般人買菜時會不會猶豫」為準，不用植物學分類。會猶豫的商品，該題型的值設成 `null`，不出那一種題目（例如甜椒不出種類題）。之後新增商品也照這個標準。
- **對話泡泡錄音是「停止」不是「暫停」**（10/7）：每輪錄音頂多幾十秒，先維持停止（再按從頭播），組員有意見再改。
- **後端網址集中管理**：所有 service 都讀 `lib/core/constants/api_constants.dart` 的 `serverUrl`。Cloudflare 臨時網址每次重開都會變，這一行**不要 commit**。

**注意事項（不要改錯）**
- 整理菜籃籃子的 `0xFF5B9E87`（蔬菜籃、綠色籃、生食籃）是分類顏色，不是舊主色，不要改。
- `main.dart` 開機時強制設回直向（處理 hot restart 殘留橫向），這行要保留。
- `linux/`、`macos/`、`windows/` 的 plugin 檔案、`pubspec.lock`、`api_constants.dart` 每次都會變動，平常不要 commit。

---

## 二、待組內討論

**之前留下、還沒討論**
- 遊戲教學頁左上角按鈕不一致：冰箱清點（箭頭→開暫停選單）、來去菜市場（箭頭→返回上一頁）、整理菜籃／市場買菜／料理準備（箭頭→教學上一頁）。建議規則：按鈕上的字跟按下去的動作一致（開選單寫「選單」、翻頁寫「上一頁」），討論後再改。
- 結算頁目前 3 種樣式（整理菜籃與市場買菜共用 `ResultScoreCard`＋`ResultHistoryChart`、來去菜市場彈窗、冰箱清點自己的頁面），要不要統一。
- 整理菜籃生熟題：生食 10 項全是水果、熟食全是蔬菜和肉，等於換了籃子的種類題。不用改程式，報告被問到時要能說明。

---

## 三、待辦項目

### 10/27 前（晚上 8 點跟老師開會前，修上週的功能）
**動態牆組（欣紜、筠淇）**
- [ ] 動態牆帳號隔離：只看得到自己的貼文
- [ ] 拿掉按讚，只留留言

**動態回顧組（Wen、詩雅）**
- [x] 修復、重構分享頁面（10/27：親友分享頁放後端 `public_share`，完成頁按鈕改用 `share_url`）
- [x] 點月曆上有日記的日期（照片圖示），彈出小視窗顯示那天的日記內容（10/27，`diary_day_dialog.dart`）

### 10/28～11/04（下次小組開會前，做新功能）
- [ ] **刪除親屬端**（Wen、筠淇）：身分選擇頁的「家屬模式」（`identity_select_page.dart`）、註冊頁的「家屬聯絡人」與「新增家屬帳號」（`register_page.dart`）、動態牆 mock 的 `family` 分類（`social_service.dart`）
- [ ] **會員相關**（其他 4 人）：
  - 會員頁，登出按鈕從設定頁搬過來
  - 註冊完的「請輸入姓名」頁；首頁、聲影日記、歡迎頁的招呼語改讀真實姓名

### 之後再排
- [ ] 六大能力說明截圖放大重要的部分（蘇蘇）
- [ ] **動態牆未登入畫面**（欣紜）：未登入時改成「前往登入」（`social_wall_page.dart` 第 212 行起）
- [ ] **冰箱清點錯誤訊息**：`fridge_game_page.dart` 3 處直接顯示 `$e`（第 158、370、435 行），改用 `friendlyErrorMessage()`
- [ ] `pubspec.yaml` 補上 `intl`（完成頁、動態回顧、`main.dart` 都有用到），單獨 commit
- [ ] 刪除 `social_service.dart` 沒用到的 `shareDiary()`（第 401 行）
- [ ] 完成頁加「傳給親友」按鈕，用 `share_plus` 開系統分享選單（電腦版 LINE、Facebook 按鈕要先登入，看起來像沒反應）
- [ ] 月曆小視窗加上語音播放和 hashtag（要另外打 D-4）
- [ ] 親友能否刪除自己在分享頁的留言（親友沒有帳號，要另外設計；目前長輩可以在動態牆刪除）

### 之後（依建議順序）
1. [ ] **字體縮放全域化**
   - `MaterialApp` 加上 `builder`，依 `AppSettings.fontSizeLevel` 設定全 App 的 `textScaler`
   - `AppSettings.scaleFont()` 改成不再自己放大（避免已套用的頁面放大兩次）
   - 底部導覽列目前把系統縮放上限降到 1.0（`main_screen.dart`），全域化後一起檢查
   - 五款遊戲逐款在「超大（145%）」下檢查文字溢出
2. [ ] **401 重新登入提示做成共用元件**：目前只有來去菜市場有，其他四款遊戲、聲影日記、動態牆要補上（`NotLoggedInException` 和後端回 401 一起處理）
3. [ ] **refresh token**：目前沒存，access token 2 小時就過期（後端 `SIMPLE_JWT`），對長輩偏短，可以跟 2 一起做
4. [ ] **橫向鎖定共用工具**：`go_to_market_game_page.dart`、`go_to_market_tutorial_page.dart`、`cooking_prep_game_page.dart` 各自呼叫 `setPreferredOrientations`
5. [ ] 動態牆列表只讀第一頁（每次 20 則），補「往下滑載入更多」（欣紜）
6. [ ] S-11 貼文詳情已寫好但畫面還沒用到，做「點通知跳到貼文」時使用，要處理貼文已被刪除（404）
7. [ ] 完成頁 `share_url`：11 月親友分享頁（P-1）完成後再接到 LINE／Facebook／複製連結
8. [ ] **顯示設定存起來**：`AppSettings` 的字體、深色模式、高對比只存在記憶體，重新整理或關掉 App 就回到預設，改成存進 SharedPreferences，開機時讀回來
9. [ ] **設定頁 `ListTile` 提醒**：「顯示」卡片的開關和「帳號」卡片的登出都包在有背景色的 `Container` 裡，debug 模式會印出「ListTile background color or ink splashes may be invisible」。在 `Container` 和 `ListTile` 之間包一層 `Material(type: MaterialType.transparency)`
10. [ ] 來去菜市場的最高分存在本機（`market_highest_score`），同一台裝置換帳號會沿用上一個帳號的紀錄

### 選做（有空再整理，不影響功能）
- [ ] 評估 `MaterialApp` 加上 `darkTheme`＋`themeMode`，減少逐頁判斷深色模式
- [ ] `post_card.dart` 的 `_errorText()` 改用共用 `friendlyErrorMessage()`
- [ ] 月曆照片蓋住日期數字（比賽版也是），組員覺得不清楚再在照片角落加小數字
- [ ] `flutter analyze` 清理：
  - `print` 18 處（`fridge_inventory_service.dart`）
  - `auth_service.dart` 第 30–34 行 `use_null_aware_elements`
  - 沒用到的變數或 import：`diary_chat_page.dart` 的 `_isDone`、`_isFinalizable`；`diary_loading_page.dart` 的 `diary_model.dart`；`tutorial_overlay.dart` 的 `isLastStep`；`market_shopping_game_page.dart` 的 `tutorial_preference.dart`；`market_shopping_memorize_page.dart` 的 `dart:async`；`market_shopping_play_page.dart` 的 `_result`（刪之前先確認用途）
  - `diary_finish_page.dart` 大量「不可能是 null 卻判斷 null」（model 欄位改成不可為 null 後頁面沒跟著改）
  - `withOpacity` 改 `withValues`（聲影日記、新手教學）；`settings_screen.dart` 的 `activeColor` 改 `activeThumbColor`
- [ ] plugin 檔案（`linux/`、`macos/`、`windows/`）找時間統一 commit 一次
- 各遊戲自己的延後項目，見 `change.md` 各筆紀錄的「已知延後項目」

---

## 四、待測試清單

已修改並 commit，但還沒實際測過。

**PR #15 合併後補測（需要後端）**
- [ ] 登出後換另一個帳號登入：動態牆、聲影日記月曆沒有上一個帳號的資料；回首頁不會退到奇怪的頁面
- [ ] 儀表板語言軸：沒寫過日記的帳號，後端回 `z_score: null` 時顯示「近期未遊玩」，不是 0
- [ ] 儀表板解鎖後的雷達圖、週報表有資料時的畫面（深色模式、超大字級）
- [ ] 結算頁：整理菜籃；市場買菜分數不是 0（改讀 `raw_score`）；料理準備標題「料理準備」、按鈕不斷行
- [ ] 菜市場購物選菜、找零送出 `reaction_time_ms` 後端有收到

**需要後端（聲影日記、動態牆）**
- [ ] 動態牆帳號隔離（10/27 改完後）：換另一個帳號，看不到原帳號的貼文；換回原帳號，貼文和留言都還在
- [ ] 刪除貼文後，動態回顧這篇日記 `is_shared` 變回 `false`；再分享一次回 201（要等二-2 日記詳情頁接上才回得去）
- [ ] 動態回顧有日記卡片時的深色模式、字級超大（要先請後端跑 `seed_review_diaries`）

**需要後端（遊戲，等遊戲分支合進來）**
- [ ] 五款遊戲都能正常開局，沒有「尚未登入」或 401（共用 `authHeaders()`）
- [ ] 菜市場購物正常開局（`session_id` 檢查不會誤擋）
- [ ] 冰箱清點：暫停選單「退出遊戲」、結算頁「退出」都回到遊戲首頁；結算頁折線圖只顯示真實歷史成績

**需要 Android 實機或模擬器**
- [ ] 來去菜市場教學頁螢幕方向
  - 遊戲首頁 → 來去菜市場 → 系統返回鍵或手勢離開 → 遊戲首頁是直向
  - 遊戲首頁 → 來去菜市場 → 略過教學 → 遊戲是橫向
  - 遊戲中按說明 → 返回 → 回到原本的遊戲，維持橫向
  - 遊戲中按說明 → 開始挑戰 → 從第 1 題重新開始 → 暫停 → 退出 → 直接回到遊戲首頁
- [ ] 來去菜市場橫向畫面的小尺寸「選單」按鈕好不好按
- [ ] 整理菜籃三個籃子完整顯示、好拖放

---

## 五、參考：字體縮放、深色模式的套用狀況

目前每一頁自己監聽 `AppSettings`，用 `scaleFont()`、`isDarkMode` 判斷；`MaterialApp` 只有淺色主題。

- **已套用**：聲影日記所有頁面（含動態回顧）、首頁、底部導覽列、設定頁、通知頁、動態牆、健康儀表板（首頁、週報表、六大能力說明）、遊戲首頁＋4 個元件（`game_top_bar`、`domain_card`、`training_progress_card`、`game_bottom_actions`）
- **只做字體、不做深色**：五款遊戲所有頁面、登入相關（身分選擇、登入、註冊、歡迎頁）、新手教學（引導頁、教練標記疊加層）
