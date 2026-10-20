# 前端待辦清單

> 整理人：Wen｜10/05 建立，10/20 精簡（已完成的項目移除，紀錄見 `change.md`）
> 目前整合分支：`integrate/frontend-1019`（Wen 聲影日記＋欣紜動態牆）

---

## 一、已決定的方向

- **字體縮放改成全域處理**：在 `main.dart` 統一設定整個 App 的文字縮放倍率，所有頁面（含五款遊戲）自動跟著放大，不再逐頁呼叫 `AppSettings.scaleFont()`（尚未實作，見三-之後）。
- **深色模式只做一般頁面**：五款遊戲（場景配色寫死數百處）、登入相關頁面、新手教學維持淺色（10/7）。
- **資訊加油站不做**（10/20）：時間不夠，整個功能砍掉，底部導覽列第 2 格與新手教學第 3 步改為動態牆。
- **整理菜籃的分類標準**（10/20）：以「一般人買菜時會不會猶豫」為準，不用植物學分類。會猶豫的商品，該題型的值設成 `null`，不出那一種題目（例如甜椒不出種類題）。之後新增商品也照這個標準。
- **對話泡泡錄音是「停止」不是「暫停」**（10/7）：每輪錄音頂多幾十秒，先維持停止（再按從頭播），組員有意見再改。
- **後端網址集中管理**：所有 service 都讀 `lib/core/constants/api_constants.dart` 的 `serverUrl`。Cloudflare 臨時網址每次重開都會變，這一行**不要 commit**。

**注意事項（不要改錯）**
- 整理菜籃籃子的 `0xFF5B9E87`（蔬菜籃、綠色籃、生食籃）是分類顏色，不是舊主色，不要改。
- `main.dart` 開機時強制設回直向（處理 hot restart 殘留橫向），這行要保留。
- `linux/`、`macos/`、`windows/` 的 plugin 檔案、`pubspec.lock`、`api_constants.dart` 每次都會變動，平常不要 commit。

---

## 二、待組內討論

**10/21 開會**
1. **使用者名稱**
   - 現況：註冊只填帳號（建議手機或 email）和密碼，沒有名字。首頁、聲影日記的「早安，玉蘭」是寫死的假資料（`lib/features/home/models/home_data.dart`）；歡迎頁顯示帳號；動態牆沒有姓名時顯示帳號（後端 `social/utils.py` 的 `get_display_name()`：姓＋名，空的就用 `username`），等於其他使用者看得到這個人的手機號碼或 email。
   - 選項：A 註冊多一欄「怎麼稱呼您」（後端註冊本來就收 `first_name`）／B 註冊不變，之後在會員頁填／C 兩者都做（建議 C，至少 A）。
   - 需要後端：`GET /api/users/me/`（回傳姓名、頭像）；沒有名字時動態牆不要退回顯示帳號。
   - 需要前端：註冊頁加欄位；歡迎頁、首頁、聲影日記問候語改讀真實姓名。
   - 待決定：動態牆顯示「稱呼」還是「姓＋名」。
2. **點月曆上的日記照片要開什麼**（`diary_home_page.dart` 的 `_onDiaryTap`，現在只跳提示）
   - A 開啟日記詳情頁（照片、標題、全文、播放錄音，沒分享的可以在這裡分享）：後端 D-4（`GET /api/diary/{id}/`）已完成，可沿用動態回顧頁的卡片（建議）。
   - B 跳到動態牆的那則貼文：沒分享的日記沒有貼文。
   - C 彈窗：動態回顧原本是彈窗後來改成頁面，選 A 比較一致。
3. **順便提**：後端遊戲分支還沒合進 `main`（料理準備 404、工作記憶與冰箱清點打不開）；動態牆未登入畫面請欣紜處理（見三）。

**之前留下、還沒討論**
- 一天一篇或多篇日記：目前前端擋同一個帳號一天一篇；若確定一天一篇，後端 D-3 也要擋。
- 遊戲教學頁左上角按鈕不一致：冰箱清點（箭頭→開暫停選單）、來去菜市場（箭頭→返回上一頁）、整理菜籃／市場買菜／料理準備（箭頭→教學上一頁）。建議規則：按鈕上的字跟按下去的動作一致（開選單寫「選單」、翻頁寫「上一頁」），討論後再改。
- 結算頁目前 3 種樣式（整理菜籃與市場買菜共用 `ResultScoreCard`＋`ResultHistoryChart`、來去菜市場彈窗、冰箱清點自己的頁面），要不要統一。
- 整理菜籃生熟題：生食 10 項全是水果、熟食全是蔬菜和肉，等於換了籃子的種類題。不用改程式，報告被問到時要能說明。

---

## 三、待辦項目

### 這次整合（PR 到 `dev` 之前）
- [ ] **動態牆未登入畫面**（欣紜）：標題「尚未登入，請重新登入」，但說明、斷網圖示、「重新載入」按鈕都是網路錯誤的樣子，按了沒有作用。未登入時改成「前往登入」（`social_wall_page.dart` 第 212 行起）
- [ ] **冰箱清點錯誤訊息**：`fridge_game_page.dart` 3 處直接顯示 `$e`（會露出網址）：第 158、370、435 行，改用 `friendlyErrorMessage()`（`lib/core/network/error_message.dart`）
- [ ] `pubspec.yaml` 補上 `intl`（完成頁、動態回顧、`main.dart` 都有用到，目前是間接安裝），單獨 commit
- [ ] 刪除 `social_service.dart` 沒用到的 `shareDiary()`（S-1 舊 mock，第 401 行；S-1 已改由 `diary_service.dart` 的 `shareToWall()` 呼叫）
- [ ] 開 PR：`integrate/frontend-1019` → `dev`。要等後端整合版（含 `feat/wall-post-integration`）push 到後端 `main` 後再合

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

**需要後端（聲影日記、動態牆）**
- [ ] 動態牆互動：換另一個帳號，看得到別人的貼文、可以按讚和留言；換回原帳號，按讚數、留言數正確
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

- **已套用**：聲影日記所有頁面（含動態回顧）、首頁、底部導覽列、設定頁、通知頁、動態牆、遊戲首頁＋4 個元件（`game_top_bar`、`domain_card`、`training_progress_card`、`game_bottom_actions`）
- **只做字體、不做深色**：五款遊戲所有頁面、登入相關（身分選擇、登入、註冊、歡迎頁）、新手教學（引導頁、教練標記疊加層）
