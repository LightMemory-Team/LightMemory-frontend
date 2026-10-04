# 料理準備（cooking_prep）前端規格

> 「料理準備」是後端 `memory_recall`（記憶配對）遊戲的美術主題包裝，不是獨立遊戲。
> 路由是 `/api/games/memory-recall/`，前端程式碼放在 `lib/features/game/cooking_prep/`
> （資料結構沿用 `memory_recall_*` 命名，是因為後端本身就叫這個名字）。
> 最後更新：2026-10-04（對應 `promote_streak=6`、`round/answer/` 移除 `seed_item` 之後）。

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
前端用途：前測輪數顯示（`練習題 N / pretest_total_rounds`）、正式賽倒數條
的總秒數估算（`base_time_limit_seconds` + 每升一階 `promote_bonus_seconds`）。
`promote_streak` 目前前端沒有直接使用（只是展示後端給的升階門檻，不在前端
重算升不升階，升階完全看 `round/answer/` 的 `action`）。

### 2.2 `POST /start/`
Request: `{ "is_pretest": bool }`（可省略，省略時後端自己判斷）。

Response:
```json
{
  "session_id": 123,
  "is_pretest": bool,
  "current_stage": "basic",
  "expires_at": "2026-...Z",   // 前測沒有這欄（不啟用倒數）
  "seed_item": "馬鈴薯"         // 整場遊戲第1輪「真正先出現」的物品
}
```
`seed_item` **只有開局這一次**拿得到，換階段時沒有對應欄位（見第 3 節的
「橋接輪」機制，說明換階段時前端怎麼在沒有 `seed_item` 的情況下照樣拿到錨點）。

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
- `new_item`：**非官方文件欄位，前端實測確認的行為**——準確預測「下一輪會
  新引入的物品」，不是「這一輪兩個選項裡誰是新的」。前端拿它來驅動「下一輪
  開始前先單獨展示這個物品」的動畫，不再用「玩家這輪答對答錯」反推（反推
  邏輯已證實不可靠，見第 4 節）。
- `stage`：這一輪實際所屬的階段。**這個欄位比 `round/answer/` 的
  `current_stage` 更準確**，畫面主題（背景、頂部標題）要用這個，不要用
  `round/answer/` 的 `current_stage`（見第 3 節）。

### 2.4 `POST /round/answer/`
Request: `{ session_id, round_number, selected_item, response_time_ms }`

Response:
```json
{
  "is_correct": bool,
  "action": "next_question",  // next_question / promoted / finished / time_up
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

`action` 決定下一步：
- `next_question` / `promoted`：都呼叫同一個「抓下一輪」流程（見第 3 節），
  不需要依 `action` 分流處理「要不要展示開局兩個物品」——那個判斷改用比較
  `round/` 自己回報的 `stage` 是否跟上一輪不同。
- `finished` / `time_up`：呼叫 `finish/` 進結算流程。

⚠️ **已知後端行為問題**：`is_correct` 的判定目前是反的（已回報後端團隊，
尚未修復）。前端刻意不針對這個做任何補償邏輯，只單純轉送 `selected_item`、
原樣顯示後端回傳的 `is_correct`，不在前端寫死「哪個是正解」。

### 2.5 `POST /finish/`
Request: `{ session_id }`。正式賽時間到或玩家中途離開時呼叫；前測第 4 輪
答完後也要呼叫一次。Response 格式同 2.6。

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
（`result/` 的內容包在 `session_result` 底下，`finish/` 則是直接在 `data` 底下，
兩者共用同一個 model、分別用 `fromJson`／`fromResultJson` 解析。）

### 2.7 已知錯誤碼
除了三款菜市場遊戲共用的 `SESSION_NOT_FOUND`，這份 API 另外會回：
`FORBIDDEN`、`ROUND_MISMATCH`、`GAME_TIME_UP`，都會被 `parseEnvelope`
轉成帶 `code` 的 `ApiException`，呼叫端可以讀 `e.code` 分流（目前前端沒有
針對這幾個碼做特殊分流，一律當成「這輪拿不到/送不出」直接進結算）。

## 3. 核心前端邏輯：下一輪展示佇列

核心實作全部在 [`cooking_prep_game_page.dart`](../lib/features/game/cooking_prep/pages/cooking_prep_game_page.dart)
的 `_fetchNextRoundAndPreview()`，整場遊戲開局（帶 `initialAnchor = seed_item`）
跟之後每一輪答完（不管 `action` 是 `next_question` 還是 `promoted`）都走這一個
方法，不分開處理。

### 3.1 anchor（這一輪已知會出現的物品）
優先用「剛答完、即將被取代的那一輪」自己的 `new_item`；只有整場遊戲最開始、
還沒有任何上一輪時，才用 `start/` 給的 `seed_item`。

### 3.2 要展示 1 個還是 2 個物品
不是看 `action` 是不是 `promoted`，而是直接比較這一輪 `round/` 回報的 `stage`
跟上一輪是否不同：
- 不同（含整場遊戲第一輪）→ 開局，依序單獨展示 `[anchor, 另一個選項]` 兩個
- 相同 → 一般輪次，只展示 `[anchor]` 一個

### 3.3 「橋接輪」現象（2026-10 實測發現）
`action == 'promoted'` 那一輪答完、緊接著呼叫 `round/` 拿到的資料，`stage`
欄位其實還停在**舊階段**、`option_items` 也還是舊階段的物品池；要再下一輪
`stage` 才會真的變成新階段。但這個還留在舊階段的「橋接輪」，它自己的
`new_item` 已經能正確預測「真正新階段第一輪」的其中一個選項——等於間接
提供了新階段的 seed，不需要後端額外補欄位。

實測數據（basic → intermediate 的轉換點，`promote_streak=6`）：
```
round 6 answer: is_correct=true action=promoted current_stage=intermediate
round 7 round/:  stage=basic         option_items=[馬鈴薯,洋蔥]     new_item=辣椒粉   ← 橋接輪
round 7 answer: is_correct=true action=next_question current_stage=intermediate
round 8 round/:  stage=intermediate  option_items=[辣椒粉,鮮奶油]   new_item=咖哩塊   ← 真正新階段開局
```
第 3.2 節的「比較 stage」判斷法則，會讓 round 7（橋接輪）正確地只展示 1 個
物品（沿用舊階段視覺），round 8 才正確展示 2 個物品並切換新階段視覺。

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
- 「是否為首次遊玩」：後端 `start/` 不帶 `is_pretest` 時不會自動判斷，前端
  自己用 `SharedPreferences`（`memory_recall_has_played`）記錄，比照
  `go_to_market` 的 `hasPlayed` 模式
- 歷史成績（最近 5 筆、最高分）：目前存在本機 `SharedPreferences`
  （`cooking_prep_score_list` / `cooking_prep_highest_score`），不是後端
  API——沒有串接後端歷史成績查詢

## 6. 目前已知、尚未解決的問題

- **`is_correct` 判定反轉**（第 2.4 節）：後端行為問題，已回報，前端不做
  任何補償，等後端修復
- advanced 階段干擾物固定「同組不跨組」、新物品組別目前是否已改成隨機（而
  非固定順序輪替）需要跟後端再次對齊——2026-10 的隨機化需求是否已完整上線，
  上一輪驗證時後端表示已改好，前端已實測確認選項配對規則（同組兩型態）維持
  正確，但長期分佈是否均勻未做長時間統計
