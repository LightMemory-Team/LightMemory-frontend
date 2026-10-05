# 料理準備（cooking_prep）前端規格

> 「料理準備」是後端 `memory_recall`（記憶配對）遊戲的美術主題包裝，不是獨立遊戲。
> 路由是 `/api/games/memory-recall/`，前端程式碼放在 `lib/features/game/cooking_prep/`
> （資料結構沿用 `memory_recall_*` 命名，是因為後端本身就叫這個名字）。
> 最後更新：2026-10-05（已對照後端 `games/memory_recall/views.py` 更正前測判斷、
> action、錯誤碼、單題時限）。前端目前的完整流程請看
> [`cooking_prep_system.md`](./cooking_prep_system.md)。

## 1. 玩法總覽

1-back 連續配對：後端維護一條物品序列 A, B, C, D, ...，每一輪給玩家 2 個選項
（`option_items`），玩家要選出「比較早出現的那一個」。答對/答錯、要不要升階、
要不要結束遊戲，全部由後端判斷，前端不自己出題、不自己判分。

三個難度階段共用同一套玩法，只是美術主題跟物品池不同：

| 後端 `stage` 字串 | 中文主題 | 畫面場景 | 物品池 |
|---|---|---|---|
| `basic` | 切菜 | 砧板 + 刀 | 馬鈴薯／胡蘿蔔／洋蔥（3 選 1 類別） |
| `intermediate` | 調味 | 鍋子 + 倒入動畫 | 辣椒粉／鮮奶油／咖哩塊 |
| `advanced` | 烹飪 | 鍋子 + 裝飾食材堆 | 3 組×2 型態（馬鈴薯塊/泥、紅蘿蔔塊/片、洋蔥圈/絲），干擾物固定同組抽取、不跨組 |

階段文字對照在 [`cooking_prep_model.dart`](../lib/features/game/cooking_prep/models/cooking_prep_model.dart)
的 `cookingStageTitle` extension；物品字串 → 圖片路徑對照在
[`cooking_prep_asset_map.dart`](../lib/features/game/cooking_prep/models/cooking_prep_asset_map.dart)
（這份 map 的 key **必須**是後端實際回傳的字串，不是美術素材自己的檔名，對不上
會整張顯示 Icon 佔位——`紅蘿蔔片` 這個 key 就曾經因為跟後端字串不一致，整個
2026-10 都在顯示佔位圖，直到用 curl 實測 `config/`/`round/` 原始回應才抓出來）。

## 2. 後端 API 契約（6 支，都在 `/api/games/memory-recall/`）

實作在 [`memory_recall_service.dart`](../lib/features/game/cooking_prep/services/memory_recall_service.dart)，
解析在 [`memory_recall_model.dart`](../lib/features/game/cooking_prep/models/memory_recall_model.dart)。
回應格式統一是 `{success, data, error:{code, message}}`，用共用的
`core/network/api_response.dart` 的 `parseEnvelope` 解析。

### 2.1 `GET /config/`
```json
{
  "is_pretest": bool,
  "current_stage": "basic",
  "pretest_total_rounds": 4,
  "base_time_limit_seconds": 60,
  "promote_streak": 6,
  "promote_bonus_seconds": 15
}
```
- `is_pretest`：**永遠是 false**，不能拿來判斷前測。
- 後端另外回 `stage_item_pools`，前端 model 沒有這個欄位。

前端用途：前測輪數顯示（`練習題 N / pretest_total_rounds`）、正式賽倒數條
的總秒數估算（`base_time_limit_seconds` + 每升一階 `promote_bonus_seconds`）。
`promote_streak` 目前前端沒有直接使用（只是展示後端給的升階門檻，不在前端
重算升不升階，升階完全看 `round/answer/` 的 `action`）。

### 2.2 `POST /start/`
Request: `{}`。後端**不會讀** `is_pretest`，是不是前測完全由後端依資料庫判斷
（這位使用者有沒有結束過一場），前端不再送這個欄位。

Response:
```json
{
  "session_id": "8f1c…",       // UUID 字串
  "is_pretest": bool,
  "current_stage": "basic",
  "expires_at": "2026-...Z",   // 前測沒有這欄（不啟用倒數）
  "seed_item": "馬鈴薯"         // 整場遊戲第1輪「真正先出現」的物品
}
```
`seed_item` **只有開局這一次**拿得到；升階不會換 seed，鏈不會中斷（見第 3 節）。

⚠️ 正式賽**每一題有作答時限** `ROUND_TIMEOUT_SECONDS`（目前測試值 10 秒，上線
改 20 秒），從後端收到 `round/` 那一刻開始算，暫停也不會停，config/ 沒有提供
這個值。超時才送答案會回 `ROUND_TIME_UP` 並直接結束整場。前測沒有這個限制。

### 2.3 `GET /round/?session_id=`
```json
{
  "round_number": 7,
  "stage": "basic",
  "option_items": ["馬鈴薯", "洋蔥"],
  "new_item": "辣椒粉"
}
```
- `option_items`：這一輪要二選一的兩張卡片，**陣列順序是隨機的**，不能拿來
  判斷「誰先出現」。
- `new_item`：這一輪要讓玩家記住的物品，**保證不在這一輪自己的
  `option_items` 裡**，它是下一輪的正解。前端拿到這一輪資料時就單獨展示它，
  不再用「玩家這輪答對答錯」反推（反推邏輯已證實不可靠，見第 4 節）。
- `stage`：這一輪實際所屬的階段。**這個欄位比 `round/answer/` 的
  `current_stage` 更準確**，畫面主題（背景、頂部標題）要用這個，不要用
  `round/answer/` 的 `current_stage`（見第 3 節）。

### 2.4 `POST /round/answer/`
Request: `{ session_id, round_number, selected_item, response_time_ms }`

Response:
```json
{
  "is_correct": bool,
  "action": "next_question",  // next_question / promoted / finished
  "current_stage": "basic",
  "correct_streak": 3,
  "bonus_seconds_granted": 0,   // 只有 action=promoted 那一次 > 0
  "expires_at": "2026-...Z",
  "score_earned": 10
}
```
前端**不會事先知道哪個選項是正解**，只能送出答案、等後端回 `is_correct`
才知道「剛剛選的那張」對不對；選項卡只針對「被選中的那張」畫勾/叉，沒被選
的那張就算是正解也不特別標示。

`action` 只有三種：

| 情況 | action |
|---|---|
| 前測第 4 題 | `finished` |
| 正式賽升階（連對 6 題，加 15 秒） | `promoted` |
| 其他 | `next_question` |

- 後端**不會**回 `time_up`，正式賽也不會回 `finished`。正式賽時間到是錯誤
  `GAME_TIME_UP`（HTTP 410），單題超時是錯誤 `ROUND_TIME_UP`（見 2.7）。
- `next_question` / `promoted` 都走同一個「抓下一輪」流程。
- `finished`：呼叫 `finish/`，前測結束後前端直接開正式賽。

`is_correct`：後端組員對照 `views.py` 確認判定正確——正解是上一輪的
`new_item`，第 1 輪是 `seed_item`。先前看起來「反轉」是前端 ver5 展示時間點
錯誤造成的，已修正。

### 2.5 `POST /finish/`
Request: `{ session_id }`。正式賽時間到或玩家中途離開時呼叫；前測第 4 輪
答完後也要呼叫一次（後端記錄這場已結束，下一次 `start/` 才會給正式賽）。
Response 欄位同 2.6，但**直接在 `data` 底下**；另外多回 `score`（0～100 的
跨遊戲統一分數，前端目前沒用）。重複呼叫會回傳同一份結果。

### 2.6 `GET /result/{session_id}/`
```json
{
  "total_rounds": int,
  "total_correct": int,
  "total_wrong": int,
  "accuracy": double,
  "avg_response_time_ms": int,
  "final_stage": "advanced",
  "total_bonus_seconds": int,
  "total_score": int | null   // 前測是 null
}
```
`result/` 的內容包在 `data.session_result` 底下，`finish/` 則是直接在 `data`
底下。兩者共用同一個 model，分別用 `fromJson`／`fromResultJson` 解析（已處理）。

### 2.7 已知錯誤碼
都會被 `parseEnvelope` 轉成帶 `code` 的 `ApiException`：

| 錯誤碼 | 意義 |
|---|---|
| `SESSION_NOT_FOUND` | 找不到場次 |
| `SESSION_ALREADY_FINISHED` | 場次已結束 |
| `FORBIDDEN` | 不是自己的場次 |
| `USER_NOT_FOUND` | 使用者不存在 |
| `ROUND_MISMATCH` | round_number 對不上 |
| `INVALID_ITEM` | selected_item 不合法 |
| `ROUND_TIME_UP` | 單題超過作答時限，**整場直接結束** |
| `GAME_TIME_UP`（HTTP 410） | 整場時間到 |

前端一律進結算；`ROUND_TIME_UP`／`GAME_TIME_UP` 會先顯示「本題超過作答時間」
／「時間到！」。

## 3. 核心前端邏輯：下一輪展示佇列

核心實作全部在 [`cooking_prep_game_page.dart`](../lib/features/game/cooking_prep/pages/cooking_prep_game_page.dart)
的 `_fetchNextRoundAndPreview()`，整場遊戲開局（帶 `initialAnchor = seed_item`）
跟之後每一輪答完（不管 `action` 是 `next_question` 還是 `promoted`）都走這一個
方法，不分開處理。

> 3.1～3.2 原本描述的是 ver5「比較 stage、換階段展示 2 個物品」的做法，
> **已經不用了**。現在（ver6）的規則：整場只有第 1 輪展示 2 個物品
> （`seed_item` → 第 1 輪 `new_item`），之後每輪只展示這一輪自己的
> `new_item`，升階也一樣。詳見 [`cooking_prep_system.md`](./cooking_prep_system.md) 第 3 節。

### 3.3 「橋接輪」現象（2026-10 實測發現，後端確認）
`action == 'promoted'` 那一輪答完、緊接著呼叫 `round/` 拿到的資料，`stage`
欄位其實還停在**舊階段**；要再下一輪 `stage` 才會真的變成新階段。這只影響畫面
主題切換晚一輪，不影響展示幾個物品。

### 3.4 畫面主題（背景、頂部標題）
跟著「這一輪 `round/` 自己回報的 `stage`」走，**不要**用 `round/answer/` 的
`current_stage`——那個欄位在 `promoted` 當下就先變了，但畫面實際展示的物品
要到橋接輪之後才真的換，兩者沒對齊會出現「畫面已經是調味主題、展示的卻還
是切菜食材」這種不一致。

## 4. 已修復的前端 bug（供理解歷史演進，新 bug 排查時可參考）

舊版曾經用「`isCorrect ? 沒被選的選項 : 被選的選項`」反推下一個該展示的
物品（`_carriedOverItem` 推論法）。實測 12 輪有 7 次對不上，會忽多忽少：

- 玩家本來就有可能答錯，答錯時「沒被選的選項」不一定是真正的延續物品
- 就算答對，「沒被選的選項」也不一定是真正的延續物品
- 這個推論錯誤正是「有時候展示兩個物品、有時候只有一個」（反推結果跟新一
  輪 `option_items` 對不上時，防呆退回整輪展示）跟「確定選對了卻顯示答錯」
  （畫面提示的物品跟後端真正記錄的不一致，玩家選了「看起來對的」卻被判錯）
  兩個回報 bug 的共同根因。

現在已經完全改用 `new_item` 直接驅動，不再有這整類推論。**不要**為了相容
舊資料或邊界情況又改回反推邏輯。

## 5. 前端自訂、後端沒有規定的部分

- 單一物品展示停留時長：`kItemPreviewDisplayDuration`（目前 1.5 秒），後端
  沒有提供這個秒數
- 答對/答錯後停留多久才進下一輪：答對 1000ms／答錯 1800ms（`advanced` 階段
  答對不播特效動畫，跟答錯一樣直接停留後進下一輪）
- 正式賽單題時限 `kRoundTimeoutSeconds`（目前 10 秒）：後端沒有在 config/
  提供，前端寫死，後端改值時要同步改
- 「是否為首次遊玩」**不是**前端自訂：由後端依資料庫判斷，前端只看
  `start/` 回應的 `is_pretest`（舊版的 `memory_recall_has_played` 已移除）
- 歷史成績（最近 5 筆、最高分）：目前存在本機 `SharedPreferences`
  （`cooking_prep_score_list` / `cooking_prep_highest_score`），不是後端
  API——沒有串接後端歷史成績查詢

## 6. 目前已知、尚未解決的問題

- **單題時限從 `round/` 開始算、暫停無效**（第 2.2 節）：物品展示時間也算在
  作答時間內，建議後端改成選項揭曉後才計時，或支援暫停
- advanced 階段干擾物固定「同組不跨組」、新物品組別目前是否已改成隨機（而
  非固定順序輪替）需要跟後端再次對齊——2026-10 的隨機化需求是否已完整上線，
  上一輪驗證時後端表示已改好，前端已實測確認選項配對規則（同組兩型態）維持
  正確，但長期分佈是否均勻未做長時間統計
