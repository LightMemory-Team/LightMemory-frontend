# 來去菜市場（go_to_market）前端邏輯說明書

> 這份文件描述 `lib/features/game/go_to_market/` **目前程式碼實際的運作方式**：
> 檔案分工、狀態欄位、完整遊戲流程、**每個函式做什麼**、計分與難度調整（DDA）、
> 計時與暫停、結算、本機儲存，以及目前已知的問題。
>
> 最後更新：2026-10-05（`fix/session` 分支）。`config/` 回應為實測結果；後端行為
> （session_id 型別、對錯判定、不讀的欄位、干擾物位置）已對照後端 `views.py`。

---

## 目錄

1. [一句話說明](#1-一句話說明)
2. [檔案結構與分工](#2-檔案結構與分工)
3. [遊戲規則](#3-遊戲規則)
4. [三個難度階段](#4-三個難度階段)
5. [後端 API 與資料模型](#5-後端-api-與資料模型)
6. [遊戲頁狀態欄位](#6-遊戲頁狀態欄位)
7. [完整遊戲流程](#7-完整遊戲流程)
8. [函式說明：遊戲頁](#8-函式說明遊戲頁-go_to_market_game_pagedart)
9. [計分與難度調整（本地 DDA）](#9-計分與難度調整本地-dda)
10. [畫面與作答區](#10-畫面與作答區)
11. [計時、暫停與恢復](#11-計時暫停與恢復)
12. [結算與歷史成績](#12-結算與歷史成績)
13. [函式說明：教學頁](#13-函式說明教學頁-go_to_market_tutorial_pagedart)
14. [函式說明：Service、Model、Widget](#14-函式說明servicemodelwidget)
15. [本機儲存（SharedPreferences）](#15-本機儲存sharedpreferences)
16. [前端寫死的常數](#16-前端寫死的常數)
17. [已知問題與待辦](#17-已知問題與待辦)
18. [除錯指引](#18-除錯指引)

---

## 1. 一句話說明

「來去菜市場」是**注意力**領域的遊戲：畫面中央的十字棋盤會**閃現**一條魚，
魚消失後玩家要點出它剛剛出現的位置。共 20 題，依表現在初階／中階／高階之間
升降，越高階閃現時間越短，高階還會多出一個「魚骨頭」干擾物。

後端是 `market-route`。前端的特色是**後端失敗時也能玩**：題目、對錯、升降階、
計分在前端都有一套本地備援邏輯（見 [§9](#9-計分與難度調整本地-dda)）。

---

## 2. 檔案結構與分工

```
lib/features/game/go_to_market/
├── pages/
│   ├── go_to_market_entry_page.dart      # 首次進入判斷（目前沒有任何地方使用）
│   ├── go_to_market_tutorial_page.dart   # 三難度互動教學（靜態示意，不計分）
│   └── go_to_market_game_page.dart       # 遊戲本體：流程、計時、DDA、計分、結算
├── services/
│   ├── go_to_market_service.dart         # 5 支 API（含 JWT Authorization header）
│   └── audio_service.dart                # 音效（多款遊戲共用）
├── models/
│   └── go_to_market_model.dart           # 題目／作答回應／結算 三個資料類別
└── widgets/
    ├── market_result_dialog.dart         # 結算對話框（料理準備也共用）
    └── market_history_chart_painter.dart # 結算框左側的歷史成績折線圖
```

外部依賴：

| 依賴 | 用途 |
|---|---|
| `widgets/game_pause.dart` | 暫停選單（繼續／教學／重新開始／退出） |
| `core/services/token_storage.dart` | 讀 JWT access token；401 重新登入時清掉 |
| `core/network/api_response.dart` | `parseData` 解析 `{success, data, error}`，失敗丟 `ApiException` |
| `core/constants/api_constants.dart` | `serverUrl`（後端網址） |
| `features/auth/pages/auth_gate.dart` | 401 選「重新登入」後導回這裡，走一般登入流程 |
| `screens/game_home_screen.dart` | 結算「退出」時回到這裡 |

**入口**：`game_home_screen.dart` 點「注意力」領域 → `push(GoToMarketTutorialPage())`。
也就是說**每次都先進教學頁**，玩家可按「略過教學」直接進遊戲。
`GoToMarketEntryPage`（第一次才看教學）寫好了但沒有被任何地方引用。

**被其他模組共用的檔案**（改這幾個檔案要注意影響範圍）：

| 檔案 | 共用者 |
|---|---|
| `audio_service.dart` | 冰箱清點、遊戲首頁的點擊音效 |
| `market_result_dialog.dart` | 料理準備（會多傳 `avgResponseTimeMs`、`totalScore`） |

---

## 3. 遊戲規則

每一題的節奏：

```
閃現（exposureTimeMs，500~2000ms）→ 魚消失 → 作答（最多 20 秒）→ 回饋
```

- **位置代號**：`center`（正中央），以及數學象限命名的四個角落：

  ```
          │
     q2   │   q1
   (左上)  │  (右上)
  ────────┼────────
     q3   │   q4
   (左下)  │  (右下)
          │
  ```

- **答對**：綠色光暈＋打勾，1 秒後下一題（或升階對話框／結算）。
- **答錯**：橘色光暈，同時把魚的正確位置秀出來。
  - 同一題答錯**未滿 3 次**：出現「重看題目」按鈕，按下後**同一題**重新閃現一次
    （`attemptNumber + 1`），基礎分會降低。
  - 答錯第 3 次、**超時**、或最後一題：1.2 秒後直接下一題（或降階對話框／結算）。
- **超時**：20 秒內沒點，視為答錯且不給重看。

---

## 4. 三個難度階段

| `stage` | 畫面標籤 | 魚出現位置 | 干擾物 | 閃現時間範圍 | 本地題目的魚 |
|---|---|---|---|---|---|
| `basic` | 初階難度 | 只有 `center` | 無 | 2000 → 1500ms | 魚（`fish.png`） |
| `intermediate` | 中階難度 | `q1`~`q4` 隨機 | 無 | 1500 → 1000ms | 鮭魚（`fish2.png`） |
| `advanced` | 高階難度 | `q1`~`q4` 隨機 | 1 個魚骨頭，**位置一定跟魚不同** | 1000 → 500ms | 鱸魚（`fish3.png`） |

- 閃現範圍跟後端 `config/` 的 `stage_exposure_range` 一致（見 [§5](#5-後端-api-與資料模型)）。
- 干擾物位置：後端保證跟魚不同（`views.py:139-141`），本地出題也是從剩下 3 個象限挑。
- 升／降階規則見 [§9](#9-計分與難度調整本地-dda)。
- 頂部標籤 `levelTitle` 讀的是 `currentStage`，作答回應一回來就會換成新階段的名稱，
  比升階對話框更早。

---

## 5. 後端 API 與資料模型

Base URL：`${ApiConstants.serverUrl}/api/games/market-route`

所有請求都帶 `Content-Type: application/json`，有 token 時加
`Authorization: Bearer <access_token>`。**每支都設 4 秒逾時**。

| # | 函式 | Method & Path | 送出 | 取用回應 | 遊戲頁有沒有用 |
|---|---|---|---|---|---|
| 1 | `fetchConfig()` | `GET /config/` | — | 整個 `data` | ❌ 沒有呼叫 |
| 2 | `startGame()` | `POST /start/` | 無 body | `data.session_id`（**UUID 字串**） | ✅ 開局 |
| 3 | `fetchRound()` | `GET /round/?session_id=` | query | `MarketRoundData` | ✅ 每題 |
| 4 | `submitAnswer()` | `POST /round/answer/` | 見下 | `MarketAnswerResponse` | ✅ 每次作答 |
| 5 | `finishGame()` | `POST /finish/` | `{session_id}` | `MarketFinishResult` | ✅ 結算 |

> 後端還有 `result` 查詢端點尚未串接（README 待辦）。

### 5.1 `config/` 實測回應（2026-10-05）

```json
{
  "success": true,
  "data": {
    "is_pretest": false,
    "current_stage": "basic",
    "total_questions": 20,
    "timeout_seconds": 20,
    "promote_streak": 5,
    "fast_promote_streak": 3,
    "fast_response_ratio": 0.5,
    "max_wrong_attempts": 3,
    "stage_exposure_range": {
      "basic": [2000, 1500],
      "intermediate": [1500, 1000],
      "advanced": [1000, 500]
    }
  },
  "error": null
}
```

這些值前端**全部寫死**在遊戲頁裡（見 [§16](#16-前端寫死的常數)），目前數字一致；
後端如果改設定，前端不會跟著變。

### 5.2 `round/answer/` 的 request body

```json
{
  "session_id": "5f1c...（UUID 字串）",
  "question_number": 5,
  "attempt_number": 1,
  "answer_position": "q2",
  "is_timeout": false,
  "response_time_ms": 842,
  "paused_duration_ms": 0
}
```

- `answer_position`：`center` / `q1`~`q4`；超時時為 `null`。
- `response_time_ms`：已扣掉 App 切到背景的時間，上限 20000。
- **後端不讀 `question_number` 和 `paused_duration_ms`**：它用自己記錄的「目前這一題」來判斷，
  所以前端題號（`currentQuestionNumber`）就算跟 `round/` 回傳的不同步也不會被拒收。
  前端照送是為了 log 方便對照。
- **對錯判定**：後端跟前端用一樣的方式（`answer_position == target_position`）。

### 5.3 資料模型（`go_to_market_model.dart`）

每個 `fromJson` 遇到缺欄位都會**給預設值**，不會丟錯。

**`MarketRoundData`**（`round/` 的 `data`）

| 欄位 | JSON key | 預設值 |
|---|---|---|
| `questionNumber` | `question_number` | `1` |
| `stage` | `stage` | `'basic'` |
| `targetItem` | `target_item` | `'魚'` |
| `targetPosition` | `target_position` | `'center'` |
| `distractorItems` | `distractor_items` | `[]`（`dynamic`，每筆預期是 `{item, position}`） |
| `exposureTimeMs` | `exposure_time_ms` | `2000` |

**`MarketAnswerResponse`**（`round/answer/` 的 `data`）

| 欄位 | JSON key | 預設值 | 說明 |
|---|---|---|---|
| `isCorrect` | `is_correct` | `false` | |
| `action` | `action` | `'next_question'` | `next_question` / `retry` / `promoted` / `demoted` / `finished` |
| `currentStage` | `current_stage` | `'basic'` | |
| `correctStreak` | `correct_streak` | `0` | |
| `wrongAttempts` | `wrong_attempts` | `0` | 前端沒用 |
| `scoreEarned` | `score_earned` | `0` | |
| `fastCorrectStreak` | `fast_correct_streak` | `0` | 前端沒用（自己算） |

**`MarketFinishResult`**（`finish/` 的 `data`）

| 欄位 | JSON key | 預設值 | 前端有沒有用 |
|---|---|---|---|
| `totalQuestions` | `total_questions` | `20` | ❌ |
| `answeredCount` | `answered_count` | `0` | ❌ |
| `correctCount` | `correct_count` | `0` | ❌ |
| `timeoutCount` | `timeout_count` | `0` | ❌ |
| `accuracy` | `accuracy` | `0.0` | ❌ |
| `avgResponseTimeMs` | `avg_response_time_ms` | `0` | ❌ |
| `finalStage` | `final_stage` | `'basic'` | ❌ |
| `totalScore` | `total_score` | `0` | ✅ 本次分數 |

### 5.4 錯誤處理：回 `null` → 改用本地模式

每支 service 都用 `try { ... } catch (e) { _logFailure(...) } return null;` 包起來。
`parseData` 遇到 `success != true` 會丟 `ApiException`，也會在這裡被接住。
遊戲頁拿到 `null` 就改用本地邏輯：

| 失敗的 API | 遊戲頁的反應 |
|---|---|
| `startGame` 回 `null` | `sessionId` 為 `null` → **整場都用本地模式**，之後不會再打任何 API |
| `fetchRound` 回 `null` | 這一題改用 `_generateLocalRound` 產生 |
| `submitAnswer` 回 `null` | 這一次作答改用 `_generateLocalAnswerResponse` 判定 |
| `finishGame` 回 `null` | 本次分數改用前端累加的 `totalScoreAccumulated` |

**失敗一定會留下明顯的 log**（`_logFailure`）：

| 情況 | Console | 畫面 |
|---|---|---|
| 401（token 過期或沒登入） | `🔴🔴🔴 [API] xxx 回 401：token 過期或沒登入，改用本地模式，這場成績不會寫入後端` | 跳「登入已過期」對話框（每場一次，見下） |
| 其他錯誤（逾時、5xx、錯誤碼） | `🔴 [API] xxx 失敗，改用本地模式，這場成績不會寫入後端: <原因>` | 沒有提示，照常用本地模式 |

**401 的處理流程**：

1. `_logFailure` 把 `GoToMarketService.unauthorized` 設成 `true`（每次 `startGame` 開頭會重設成 `false`）。
2. 遊戲頁在兩個時間點呼叫 `_promptReloginIfUnauthorized()`：
   - **開局**：`startGame` 之後、載入第一題之前。最常見的情況，這時沒有 Timer 在跑。
   - **結算**：`finishGame` 之後、顯示結算框之前。處理玩到一半 token 才過期的情況。
3. 對話框兩個選項：
   - **繼續練習**：照常玩（或照常顯示結算），成績不進後端。
   - **重新登入**：`TokenStorage.clear()`，再 `pushAndRemoveUntil(AuthGate)`。AuthGate 看到沒有 token，
     會導去身分選擇頁走一般的登入流程。

---

## 6. 遊戲頁狀態欄位

`_GoToMarketGamePageState`（[go_to_market_game_page.dart:23-55](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L23-L55)）

| 分類 | 欄位 | 初始值 | 說明 |
|---|---|---|---|
| 進度 | `totalQuestions` | `20` | 常數 |
| | `currentQuestionNumber` | `1` | 前端自己數，1~20 |
| | `attemptNumber` | `1` | 本題第幾次作答（1~3），按「重看題目」+1 |
| 場次 | `sessionId` | `null` | `String?`（UUID）；`null` 代表本地模式 |
| | `currentRound` | `null` | 目前題目；`null` 時畫面顯示轉圈 |
| 難度 | `currentStage` | `'basic'` | 來自作答回應的 `currentStage` |
| | `correctStreak` | `0` | 連續答對數（來自作答回應） |
| | `fastCorrectStreak` | `0` | 連續「快速答對」數（前端自己算） |
| | `wrongStreak` | `0` | 連續答錯**次數**（每次作答都算，包含重看後再錯） |
| | `exposureTimeMs` | `2000` | 本題閃現時間 |
| 分數 | `totalScoreAccumulated` | `0` | 前端累加的分數 |
| | `correctCount` | `0` | 答對題數（**沒有被顯示或送出**） |
| | `_reactionTimes` | `[]` | 每次的反應時間（**沒有被使用**） |
| 階段旗標 | `isExposing` | `true` | 閃現中（顯示魚、不能點） |
| | `canAnswer` | `false` | 作答中（顯示觸控區） |
| | `feedbackState` | `null` | `'correct'` / `'wrong'` / `null` |
| | `lastUserClickedPosition` | `null` | 玩家點的位置（只記錄，畫面沒用） |
| 計時 | `_exposureTimer` | — | 閃現結束的單次 Timer |
| | `_countdownTimer` | — | 作答 20 秒倒數（每秒一次） |
| | `_remainingSeconds` | `20` | 剩餘秒數（**畫面沒顯示**） |
| | `_questionStartTime` | `null` | 魚消失、開始作答的時間點 |
| 暫停 | `_pausedStartTime` | `null` | App 進背景的時間 |
| | `_totalPausedMsThisRound` | `0` | 本題累積的背景時間，換題時歸零 |
| | `_isPauseDialogOpen` | `false` | 避免重複開暫停選單 |
| | `_canAutoPause` | `false` | 進頁 1.2 秒後才變 `true`，避免一進來就跳暫停 |
| 登入 | `_hasPromptedRelogin` | `false` | 401 提示每場只跳一次，開新場次時重設 |

三個階段旗標的組合：

| 畫面階段 | `isExposing` | `canAnswer` | `feedbackState` | 棋盤上看得到 |
|---|---|---|---|---|
| 閃現 | `true` | `false` | `null` | 魚（＋魚骨頭） |
| 作答 | `false` | `true` | `null` | 只有十字線，加上透明觸控區 |
| 送出中 | `false` | `false` | `null` | 只有十字線（等 API） |
| 回饋 | `false` | `false` | `'correct'`/`'wrong'` | 魚的正確位置（＋答對打勾） |

---

## 7. 完整遊戲流程

```
initState
 ├─ 鎖橫向、1.2 秒後開放自動暫停
 └─ _startNewGameSession
     ├─ startGame()              → sessionId（失敗 = null = 本地模式）
     ├─ 401？→ _promptReloginIfUnauthorized（重新登入 → AuthGate，流程結束）
     └─ _loadRound
         ├─ fetchRound()         → 失敗則 _generateLocalRound
         ├─ 重設 attemptNumber=1、回饋、本題暫停時間
         └─ _startExposure
             ├─ 閃現 exposureTimeMs
             └─ 時間到 → 開始作答 + 20 秒倒數
                         │
          玩家點擊 / 倒數歸零（isTimeout）
                         ▼
                   _handleAnswer
                    ├─ 算反應時間、前端判斷對錯
                    ├─ submitAnswer()
                    ├─ 回應為 null（或對錯跟前端不同）→ _generateLocalAnswerResponse
                    └─ _applyAnswerResponse
                        ├─ 更新階段、連對、分數、閃現時間
                        ├─ 答對 → 1000ms 後：
                        │     第 20 題或 finished → _showGameSummary
                        │     promoted           → _showLevelTransitionDialog(升階)
                        │     其他               → _proceedToNextQuestion
                        └─ 答錯：
                              action == retry 且 attempt<3 且未超時
                                 → 停在本題，等玩家按「重看題目」
                                   （attemptNumber+1 → _startExposure，同一題）
                              否則 1200ms 後：
                                 第 20 題或 finished → _showGameSummary
                                 demoted            → _showLevelTransitionDialog(降階)
                                 其他               → _proceedToNextQuestion

_proceedToNextQuestion：currentQuestionNumber+1 → _loadRound（回到上面）
_showLevelTransitionDialog：按「進入下一題」→ _proceedToNextQuestion
_showGameSummary：finishGame() → 401？提示重新登入 → 寫本機歷史 → MarketResultDialog
                    ├─ 再玩一次 → _resetGame → _startNewGameSession
                    └─ 退出     → 清空路由堆疊，回 GameHomeScreen
```

---

## 8. 函式說明：遊戲頁（`go_to_market_game_page.dart`）

### 生命週期

| 函式 | 行 | 做什麼 |
|---|---|---|
| `levelTitle`（getter） | [57](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L57) | `currentStage` → 「初階／中階／高階難度」，未知值當初階 |
| `initState()` | [70](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L70) | 註冊 lifecycle 觀察者；鎖橫向（立即一次＋第一個 frame 後再一次，避免某些裝置沒生效）；1200ms 後 `_canAutoPause = true`；呼叫 `_startNewGameSession()` |
| `dispose()` | [99](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L99) | 恢復直向、移除觀察者、取消兩個 Timer |
| `didChangeAppLifecycleState()` | [109](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L109) | `paused`：記下時間並停 Timer。`resumed`：把背景時間加進 `_totalPausedMsThisRound`，再自動開暫停選單（要 `_canAutoPause` 為真、選單還沒開） |

### 暫停相關

| 函式 | 行 | 做什麼 |
|---|---|---|
| `_pauseTimers()` | [127](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L127) | 取消閃現與倒數 Timer |
| `_resumeTimers()` | [132](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L132) | 閃現中 → `_startExposure()`（**從頭重新閃現**）；作答中 → 用剩下的 `_remainingSeconds` 重開倒數；回饋中 → 什麼都不做 |
| `_showPauseDialog()` | [148](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L148) | 停 Timer，開 `GamePause`：**繼續** → `_resumeTimers`；**教學** → push 教學頁；**重新開始** → `_resetGame`；**退出** → pop 遊戲頁 |

### 場次與題目

| 函式 | 行 | 做什麼 |
|---|---|---|
| `_resetGame()` | [181](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L181) | 進度、連對／連錯、分數、階段、閃現時間全部歸零回初階，清掉反應時間，呼叫 `_startNewGameSession()` 開一個**新場次**（舊場次不會呼叫 finish） |
| `_startNewGameSession()` | [197](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L197) | 重設 `_hasPromptedRelogin`；`sessionId = await startGame()`；遇到 401 先提示重新登入（選重新登入就停在這裡）；然後 `_loadRound()` |
| `_promptReloginIfUnauthorized()` | [206](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L206) | `GoToMarketService.unauthorized` 為真且這場還沒提示過，就跳「登入已過期」對話框。**繼續練習** → 回傳 `false`；**重新登入** → 清 token、`pushAndRemoveUntil(AuthGate)`、回傳 `true`（呼叫端看到 `true` 要停止後續動作） |
| `_loadRound()` | [304](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L304) | 有 `sessionId` 就 `fetchRound`；拿不到就 `_generateLocalRound`。設定 `currentRound`，**用題目的 `exposureTimeMs` 覆蓋本地值**，重設 `attemptNumber=1`、回饋、本題暫停時間，然後 `_startExposure()` |
| `_generateLocalRound(qNum, stage, currentExpMs)` | [329](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L329) | 本地出題（見 [§4](#4-三個難度階段)）：初階固定 `center`；中階隨機 `q1~q4`；高階隨機 `q1~q4`，再從剩下 3 個象限挑一個放魚骨頭。閃現時間 = `currentExpMs` clamp 到該階段範圍 |

### 計時與作答

| 函式 | 行 | 做什麼 |
|---|---|---|
| `_startExposure()` | [378](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L378) | 取消舊 Timer；進入閃現（`isExposing=true`、`canAnswer=false`、清回饋、倒數重設 20）。`exposureTimeMs` 後切到作答：記 `_questionStartTime`，開每秒倒數，倒數到 1 之後下一秒觸發 `_handleAnswer(userPosition: null, isTimeout: true)` |
| `_handleAnswer({userPosition, isTimeout})` | [410](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L410) | **作答核心**。`canAnswer` 為假就直接 return（防連點）。① 停倒數 ② 反應時間 =（現在 − `_questionStartTime`）− 本題背景時間，clamp 0~20000 ③ 前端判斷對錯：未超時且 `userPosition == targetPosition` ④ 關掉作答 ⑤ 有場次就 `submitAnswer` ⑥ 回應是 `null` 就改用本地回應。程式另外也會在「回應的 `isCorrect` 跟前端判斷不同」時改用本地回應，但後端用一樣的比對方式，正常情況不會發生 ⑦ `_applyAnswerResponse` |
| `_generateLocalAnswerResponse(isCorrect, isTimeout, reactionMs)` | [467](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L467) | 本地 DDA 與計分，產生一個 `MarketAnswerResponse`。規則見 [§9](#9-計分與難度調整本地-dda) |
| `_applyAnswerResponse(response, isCorrect, isTimeout, reactionMs)` | [567](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L567) | ① 套用 `currentStage`、`correctStreak`，分數累加 `scoreEarned` ② 前端重算 `fastCorrectStreak` ③ 調整閃現時間（見 [§9.3](#93-閃現時間微調)）④ 播音效、設 `feedbackState` ⑤ 依 `action` 排下一步：答對等 1000ms，答錯（不是 retry 時）等 1200ms |
| `_proceedToNextQuestion()` | [657](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L657) | 未滿 20 題 → 題號 +1、`attemptNumber=1`、`_loadRound()`；否則 `_showGameSummary()` |

### 對話框

| 函式 | 行 | 做什麼 |
|---|---|---|
| `_showLevelTransitionDialog({isPromoted})` | [669](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L669) | 升階：星星圖示、「表現優異！難度升級！」、`playLevelUp`。降階：資訊圖示、「節奏調整！進入更合適的難度」、`playClick`。不能點背景關閉，按「進入下一題」→ `_proceedToNextQuestion()` |
| `_showGameSummary()` | [745](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L745) | 結算（見 [§12](#12-結算與歷史成績)） |

### 畫面

| 函式 | 行 | 做什麼 |
|---|---|---|
| `_buildFishImage()` | [813](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L813) | 依 `targetItem` 選圖：含「鮭魚」或 `fish2` → `fish2.png`；含「鱸魚」或 `fish3` → `fish3.png`；其他 → `fish.png`。140×48 |
| `_buildFishBoneImage()` | [828](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L828) | `fish_bone.png`，95×48。不看干擾物的 `item` 名稱，一律畫魚骨頭 |
| `_buildCheckMark()` | [837](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L837) | 深綠圓底白勾，54×54，答對時疊在棋盤正中央 |
| `build()` | [857](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L857) | 見 [§10](#10-畫面與作答區) |

---

## 9. 計分與難度調整（本地 DDA）

> 以下是 `_generateLocalAnswerResponse` 的邏輯，**只在 `submitAnswer` 失敗（回 `null`）時使用**。
> 連上後端時，升降階與分數以後端回應為準；`fastCorrectStreak` 與閃現時間微調則**一律由前端計算**。

### 9.1 答對

**分數** = round(基礎分 × 難度係數) + 速度加成

| 第幾次答對 | 基礎分 | | 階段 | 係數 | | 條件 | 速度加成 |
|---|---|---|---|---|---|---|---|
| 第 1 次 | 10 | | basic | 1.0 | | 反應 ≤ 閃現時間 × 50% | +2 |
| 第 2 次 | 6 | | intermediate | 1.3 | | 其他 | 0 |
| 第 3 次 | 3 | | advanced | 1.6 | | | |

例：高階第一次就快速答對 = round(10 × 1.6) + 2 = **18 分**（單題最高）。

> 「反應時間」是從**魚消失**開始算。閃現 2000ms 時，要在 1000ms 內點才算快速。

**升階（雙軌，任一成立就升，已在 advanced 就不升）：**

- 一般升階：連續答對 **5** 題（`correctStreak + 1 >= 5`）
- 快速升階：連續快速答對 **3** 題（`fastCorrectStreak + 1 >= 3`）

升階時 `action = 'promoted'`（第 20 題則為 `'finished'`），連對與快速連對歸零。

### 9.2 答錯（含超時）

判斷順序：

1. **降階**：`wrongStreak + 1 >= 5` 且不在 basic → `action = 'demoted'`，退一階。
   `wrongStreak` 算的是**每一次作答**，所以「第 1 題錯 3 次＋第 2 題錯 2 次」也會觸發。
2. **跳題**：第 3 次錯、超時、或第 20 題 → `next_question`（第 20 題為 `finished`）。
3. **其他** → `retry`（顯示「重看題目」）。

答錯一律 0 分、`correctStreak = 0`。

### 9.3 閃現時間微調

`_applyAnswerResponse` 每次作答後都會調整 `exposureTimeMs`：

| 情況 | 調整 | 範圍（basic / intermediate / advanced） |
|---|---|---|
| 升階或降階 | 重設成**新階段最寬鬆**的值，連錯、快速連對歸零 | 2000 / 1500 / 1000 |
| 答對 | −100ms，不低於下限 | 下限 1500 / 1000 / 500 |
| 答錯 | +150ms，不超過上限；`wrongStreak + 1` | 上限 2000 / 1500 / 1000 |

**影響範圍要注意：**

- 「重看題目」不會重新拿題目，所以**會用到 +150ms 之後的值**，重看時閃得比較久。
- 進下一題時 `_loadRound` 會用題目的 `exposureTimeMs` 覆蓋：
  - **連線模式**：用後端給的值，前端微調的結果被蓋掉。
  - **本地模式**：`_generateLocalRound` 會把前端值 clamp 進範圍再用，微調有效。

---

## 10. 畫面與作答區

### 版面（由上到下）

1. **頂部列**：返回鍵（**開暫停選單**，不是直接離開）、`?`（push 教學頁）、
   階段標籤、`題號 / 20`、進度條（`currentQuestionNumber / 20`）。
2. **十字棋盤**：480×150，一條水平線、一條垂直線。
3. **提示文字**：

   | 條件 | 文字 |
   |---|---|
   | 閃現中 | 注意看！記住魚出現的位置！ |
   | 答錯且 `attemptNumber >= 3` | 答錯三次囉！準備進入下一題 |
   | 答錯且 `attemptNumber < 3` | 答錯囉！請看魚的正確位置 |
   | 答對 | 太棒了！答對了！ |
   | 作答中 | 請點擊剛剛魚出現的位置！ |

4. **「重看題目」按鈕**：`feedbackState == 'wrong' && attemptNumber < 3` 時出現。
   按下：`attemptNumber++` → `_startExposure()`。

### 棋盤上的物件位置

| 位置 | 魚 | 魚骨頭 |
|---|---|---|
| `center` | 棋盤正中央 | — |
| `q1` | top 6, right 20 | top 6, right 30 |
| `q2` | top 6, left 20 | top 6, left 30 |
| `q3` | bottom 6, left 20 | bottom 6, left 30 |
| `q4` | bottom 6, right 20 | bottom 6, right 30 |

魚和魚骨頭不會在同一象限（後端與本地出題都保證），所以不會重疊。

### 觸控區（只在 `canAnswer` 時存在）

- 四個象限各佔棋盤的 1/4（240×75），透明 `GestureDetector`。
- 正中央另有一塊 90×70 的 `center` 區，**疊在最上層**。
- 所以**每個階段都能點 `center`**。中階、高階點到十字交叉附近會被判成 `center` → 答錯。

### 回饋效果

- 答對：全螢幕綠色徑向光暈（`IgnorePointer`，不擋點擊）、棋盤中央打勾、`playCorrect`。
- 答錯：全螢幕橘色徑向光暈、`playWrong`。
- 回饋期間 `showObjects` 為真，會把魚（與魚骨頭）的**正確位置**顯示出來。

---

## 11. 計時、暫停與恢復

| 計時 | 長度 | 誰啟動 | 誰停止 |
|---|---|---|---|
| 閃現 `_exposureTimer` | `exposureTimeMs` | `_startExposure` | 時間到、`_pauseTimers`、`dispose` |
| 作答倒數 `_countdownTimer` | 20 × 1 秒 | 閃現結束、`_resumeTimers` | 作答、超時、`_pauseTimers`、`dispose` |
| 回饋延遲 `Future.delayed` | 1000 / 1200ms | `_applyAnswerResponse` | **無法取消**，只檢查 `mounted` |

**兩種暫停來源：**

| 來源 | 觸發 | Timer | 會從反應時間扣掉嗎 |
|---|---|---|---|
| App 進背景 | `AppLifecycleState.paused` | 停止；回前景時自動開暫停選單 | ✅ 加進 `_totalPausedMsThisRound` |
| 暫停選單 | 返回鍵 | 停止 | ❌ 沒扣（見 [§17](#17-已知問題與待辦)） |

後端不讀 `paused_duration_ms`，所以**暫停時間只能靠前端從 `response_time_ms` 扣掉**。

**恢復（`_resumeTimers`）：**

- 閃現中被暫停 → **從頭重新閃現**（玩家會多看一次完整閃現）。
- 作答中被暫停 → 倒數從剩餘秒數接著跑。

**轉向**：遊戲頁 `initState` 鎖橫向、`dispose` 設回直向。在 Chrome（Web）上鎖轉向不會有作用。

---

## 12. 結算與歷史成績

`_showGameSummary()`（[745](../lib/features/game/go_to_market/pages/go_to_market_game_page.dart#L745)）：

1. `finalScore = totalScoreAccumulated`；有場次就呼叫 `finishGame`，成功則改用後端的 `totalScore`。
2. 如果這場有 API 回 401，先跳「登入已過期」對話框（選重新登入就直接離開，不顯示結算）。
3. 讀本機 `market_score_list`（字串陣列），加入本次分數，**只保留最近 5 筆**，寫回。
4. 最高分 = max(本機 `market_highest_score`, 本次)，寫回。
5. 本機存取失敗 → 歷史只放本次分數。
6. 開 `MarketResultDialog`（不能點背景關閉）：
   - **再玩一次** → `_resetGame()`
   - **退出** → `pushAndRemoveUntil(GameHomeScreen)`，清空整個路由堆疊

**結算框**（`market_result_dialog.dart`）：

| 本次分數 | 評語 | 圖示／顏色 |
|---|---|---|
| ≥ 90 | 非常棒！ | 星星／深綠 |
| ≥ 60 | 很好！ | 打勾／深綠 |
| < 60 | 沒關係再加油！ | 旗子／橘 |

- 左側：歷史成績折線圖。右側：評語、本次分數＋最高分數、「退出」「再玩一次」。
- 兩個按鈕都是**先關對話框、再呼叫 callback**。
- `avgResponseTimeMs`、`totalScore` 是給料理準備用的選填欄位，來去菜市場沒傳，不會顯示。

> 歷史成績**只存在本機**，沒有向後端查歷史，換裝置或清資料就沒了。

---

## 13. 函式說明：教學頁（`go_to_market_tutorial_page.dart`）

教學是**靜態示意**：每一步固定畫好魚的位置，沒有計時、不判斷對錯，玩家只按「上一步／下一步」。

### 教學內容（3 個階段，共 10 步）

| `stage` | `step` | 棋盤畫面 | 指示文字 |
|---|---|---|---|
| 0 簡單 | 0 | 魚在中央 | 注意看！圖案出現在正中間 |
| | 1 | 空棋盤 | 剛剛的圖案出現在哪裡？ |
| | 2 | 中央虛線框＋魚＋手指 | 請點擊剛剛圖案出現的正中間！ |
| 1 中等 | 0 | 魚在右上 | 注意看！圖案會隨機出現在四個角落 |
| | 1 | 空棋盤 | 剛剛的圖案出現在哪裡？ |
| | 2 | 右上虛線框＋魚＋手指 | 請點擊剛剛圖案出現的角落！ |
| 2 高階 | 0 | 「目標物／干擾物」兩張辨識卡 | 記清楚！只需要點擊「目標物」… |
| | 1 | 魚在右上、魚骨頭在左下 | 注意看！請專注記住「目標物」的位置 |
| | 2 | 空棋盤 | 剛剛的「目標物」出現在哪裡？ |
| | 3 | 右上虛線框＋魚＋手指 | 請點擊剛剛「目標物」的位置… |

每進一個新階段，先蓋一層半透明的**階段橫幅**（例如「簡單難度教學」）1.6 秒，點一下也可以關掉。
頂部的「1/20」與進度條是固定的示意值。

### 函式

| 函式 | 行 | 做什麼 |
|---|---|---|
| `initState()` | [23](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L23) | 鎖橫向，顯示第一個階段橫幅 |
| `dispose()` | [33](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L33) | 取消橫幅 Timer（**沒有恢復直向**） |
| `_backToPreviousPage()` | [39](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L39) | 點擊音效、設回直向、`maybePop` |
| `_triggerStageBanner()` | [45](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L45) | 顯示橫幅，1600ms 後自動隱藏 |
| `stageTitle` / `stepBadgeText` / `instructionText` | [59](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L59) / [72](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L72) / [87](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L87) | 依 `stage`、`step` 回傳標題、「第 N 步」、指示文字 |
| `canGoPrev` | [121](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L121) | 不在第一階段第一步時才能按「上一步」 |
| `_nextStep()` | [123](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L123) | 橫幅還在 → 只關橫幅。否則 step+1；到本階段最後一步（高階為 3，其他為 2）就進下一階段並顯示橫幅；最後一階段的最後一步 → `_showCompletionDialog()` |
| `_prevStep()` | [150](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L150) | 關橫幅（**不會 return**，同一下也會往回一步）。step−1；step 為 0 時退回上一階段的最後一步 |
| `_showCompletionDialog()` | [169](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L169) | 「全難度教學完成！」：**再看一次教學** → 回到 stage 0 step 0；**開始挑戰 20 題** → `pushReplacement(GoToMarketGamePage)` |
| `_buildFishImage()` / `_buildFishBoneImage()` | [282](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L282) / [291](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L291) | 魚固定用 `fish.png`；魚骨頭圖載入失敗時改用 `_FishBonePainter` 手繪 |
| `_buildUnifiedGuideTarget({showFish})` | [306](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L306) | 「點這裡」示意：虛線圓角框＋魚＋手指圖示 |
| `build()` | [345](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L345) | 頂部列（返回、標題「來去菜市場」、**略過教學** → `pushReplacement` 遊戲頁）、進度列、教學內容、指示文字、上一步／下一步；最上層疊階段橫幅 |
| `_buildStageContent()` | [601](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L601) | 高階第 0 步 → 辨識卡；其他 → 步驟徽章＋460×140 棋盤，依上表擺放物件 |
| `_buildIdentificationCards()` | [699](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L699) | 兩張白卡：「目標物」魚「請記住它！」、「干擾物」魚骨頭「請忽略它！」 |
| `_DottedBorderPainter` | [805](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L805) | 沿圓角矩形畫虛線（實線 7px、間隔 `gap`） |
| `_FishBonePainter` | [853](../lib/features/game/go_to_market/pages/go_to_market_tutorial_page.dart#L853) | 魚骨頭的手繪備援：三角形頭、眼睛、脊椎、4 根刺、尾巴 |

### 入口頁 `go_to_market_entry_page.dart`（目前沒有使用）

| 函式 | 做什麼 |
|---|---|
| `_checkFirstTimeUser()` | 讀 `has_played_market_game`：沒玩過 → 設為 `true` 並 `pushReplacement` 教學頁；玩過 → `pushReplacement` 遊戲頁。等待期間顯示轉圈 |

---

## 14. 函式說明：Service、Model、Widget

### `GoToMarketService`（[go_to_market_service.dart](../lib/features/game/go_to_market/services/go_to_market_service.dart)）

全部是 `static`，回傳型別都是沒標型別的 `Future`（實際上是 `Future<dynamic>`）。

| 成員 | 做什麼 | 成功回傳 | 失敗回傳 |
|---|---|---|---|
| `unauthorized`（欄位） | 這場有沒有 API 回 401；`startGame` 開頭重設 | — | — |
| `_getHeaders()` | 從 `TokenStorage.getAccessToken()` 讀 token，組 header；token 空就不帶 `Authorization` | `Map<String, String>` | — |
| `_logFailure(api, e)` | 統一的失敗 log：401 印 `🔴🔴🔴` 並設 `unauthorized = true`，其他錯誤印 `🔴` | — | — |
| `fetchConfig()` | `GET /config/` | `data`（Map） | `null` |
| `startGame()` | 重設 `unauthorized`，`POST /start/` | `data['session_id']?.toString()`（`String`） | `null` |
| `fetchRound({String sessionId})` | `GET /round/?session_id=` | `MarketRoundData` | `null` |
| `submitAnswer({...7 個參數})` | `POST /round/answer/`，欄位見 [§5.2](#52-roundanswer-的-request-body) | `MarketAnswerResponse` | `null` |
| `finishGame({String sessionId})` | `POST /finish/` | `MarketFinishResult` | `null` |

每支都會 `debugPrint`：`🚀` 送出、`📥` 回傳（含狀態碼與 body），失敗時印 `🔴` 的 `_logFailure` log。

### `AudioService`（[audio_service.dart](../lib/features/game/go_to_market/services/audio_service.dart)）

共用**一個** `AudioPlayer`，避免 Android 一直申請新的音訊通道而卡住。

| 函式 | 檔案 |
|---|---|
| `_init()` | 只設旗標（原本的 `AudioContext` 設定已移除） |
| `_play(fileName)` | 先 `stop()` 再播 `assets/audio/<fileName>`；失敗只印 log |
| `playCorrect()` | `correct.mp3` |
| `playWrong()` | `no.mp3` |
| `playClick()` | `normal.mp3` |
| `playLevelUp()` | `correct.mp3`（跟答對同一個） |

### `MarketHistoryChartPainter`（[market_history_chart_painter.dart](../lib/features/game/go_to_market/widgets/market_history_chart_painter.dart)）

| 步驟 | 做什麼 |
|---|---|
| Y 軸 | 固定刻度 0 / 50 / 100，加淺色虛線 |
| X 軸 | **固定 5 格**，從左排。有資料的格子標「前 N 次」，最後一筆標「本次」，沒資料的標「-」 |
| 資料點 | 分數 **clamp 到 0~100** 再換算 Y 座標，但點上方的文字顯示原始分數 |
| 繪製 | 漸層填色 → 折線（2 點以上才畫）→ 白底圓點（本次較大）→ 分數文字 |
| `_drawDashedLine()` | 畫水平虛線（5px 線、4px 空） |
| `shouldRepaint()` | 永遠 `true` |

### `MarketResultDialog`

見 [§12](#12-結算與歷史成績)。

---

## 15. 本機儲存（SharedPreferences）

| Key | 型別 | 寫入者 | 內容 |
|---|---|---|---|
| `market_score_list` | `List<String>` | `_showGameSummary` | 最近 5 次分數（舊到新） |
| `market_highest_score` | `int` | `_showGameSummary` | 歷史最高分 |
| `has_played_market_game` | `bool` | `GoToMarketEntryPage`（未使用） | 是否看過教學 |

JWT token 由 `TokenStorage` 管理（key 是 `access_token`）。這個模組平常只讀；401 時玩家選「重新登入」才會清掉。

---

## 16. 前端寫死的常數

| 常數 | 值 | 位置 | 後端 `config/` 對應 |
|---|---|---|---|
| 總題數 | 20 | `totalQuestions` | `total_questions: 20` |
| 作答時限 | 20 秒 | `_remainingSeconds`、反應時間上限 20000 | `timeout_seconds: 20` |
| 一般升階連對數 | 5 | `_generateLocalAnswerResponse` | `promote_streak: 5` |
| 快速升階連對數 | 3 | 同上 | `fast_promote_streak: 3` |
| 快速判定比例 | 0.5 | 同上、`_applyAnswerResponse` | `fast_response_ratio: 0.5` |
| 每題最多作答次數 | 3 | 同上、`build` | `max_wrong_attempts: 3` |
| 降階連錯次數 | 5 | 同上 | （config 沒有） |
| 各階段閃現範圍 | 見 §4 | `_generateLocalRound`、`_applyAnswerResponse` | `stage_exposure_range` |
| 閃現微調 | 答對 −100、答錯 +150 | `_applyAnswerResponse` | （config 沒有） |
| 基礎分／係數／速度加成 | 10·6·3／1.0·1.3·1.6／+2 | `_generateLocalAnswerResponse` | （config 沒有） |
| 回饋停留 | 答對 1000ms、答錯 1200ms | `_applyAnswerResponse` | — |
| 自動暫停延遲 | 1200ms | `initState` | — |
| API 逾時 | 4 秒 | service 每支 | — |

---

## 17. 已知問題與待辦

### 已修正（2026-10-05）

| # | 問題 | 修法 |
|---|---|---|
| F1 | `sessionId` 宣告為 `int?`。後端從 9/24 起回傳 UUID 字串，`sessionId = await startGame()` 丟 `TypeError`，第一題載不出來，畫面**一直轉圈** | 改成 `String?`；service 的 `sessionId` 參數都改 `String`；`startGame` 用 `data['session_id']?.toString()` 解析（跟料理準備的修法一樣） |
| F2 | 所有 API 錯誤都被靜默吞掉，401 時偷偷切到本地模式，成績不進後端 | 新增 `_logFailure`，失敗一律印 `🔴` log（401 印 `🔴🔴🔴`）；401 時在開局與結算跳「登入已過期」對話框，可選重新登入。詳見 [§5.4](#54-錯誤處理回-null--改用本地模式) |

### 仍待處理

**正確性**

1. **「重看題目」按鈕在不該出現時出現**：按鈕條件只看 `attemptNumber < 3`。**超時**、
   **降階**、**第 20 題答錯**（且 attempt < 3）時，按鈕會在 1.2 秒的延遲期間出現。
   這時按下去會重新閃現，但延遲的 callback 照樣會跳下一題或結算。提示文字也會誤顯示
   「答錯囉！請看魚的正確位置」。
2. **非 401 的錯誤仍然只有 Console log**：逾時、5xx 時玩家看不到提示，成績照樣不進後端。

**暫停與導航**

3. **暫停選單 → 教學 → 返回後遊戲卡住**：`onTutorial` 沒有在返回後呼叫
   `_resumeTimers()`。閃現中暫停的話，魚會一直留在畫面上。
4. **從暫停選單進教學再按「開始挑戰／略過教學」會疊出第二個遊戲頁**：教學頁用
   `pushReplacement`，只換掉教學頁本身，底下的舊遊戲頁和它的場次都還在。
5. **教學頁返回鍵會把轉向設成直向**：從遊戲頁進教學再返回，遊戲頁會變直向。
   另外教學頁 `dispose()` 沒有恢復直向（已列在 `docs/frontend_todo.md`）。
6. **暫停選單的時間沒有從反應時間扣掉**：只有 App 進背景的時間會扣，作答中開暫停選單
   的時間會算進 `response_time_ms`。後端不讀 `paused_duration_ms`，所以只能在前端修。
7. **回饋期間暫停，下一題會在選單後面開始**：1000／1200ms 的 `Future.delayed` 不會被暫停取消。
8. **重新開始不會結束舊場次**：`_resetGame` 直接 `startGame()`，舊 session 沒呼叫 `finish/`。
   另外它是在 `setState` 裡呼叫 async 函式。

**畫面與計分**

9. **中央觸控區在中階、高階也有效**：點到十字交叉附近會判成 `center`，必錯。
10. **分數尺度跟圖表、評語不一致**：本地計分單題最高 18 分，20 題可以超過 100。
    折線圖把 Y 座標 clamp 在 100，評語門檻是 90／60。後端 `total_score` 的尺度也需要確認。

**沒用到的程式碼**

11. `fetchConfig()`、`GoToMarketEntryPage`、`correctCount`、`_reactionTimes`、
    `lastUserClickedPosition`、`MarketAnswerResponse.wrongAttempts／fastCorrectStreak`、
    `MarketFinishResult` 除了 `totalScore` 以外的欄位都沒用到。`_remainingSeconds` 有在倒數，但畫面沒顯示。
12. `market_route` 的 `result` 查詢端點尚未串接，歷史成績只存在本機（README 待辦）。

---

## 18. 除錯指引

| 症狀 | 先看哪裡 |
|---|---|
| 進遊戲一直轉圈 | Console 有沒有 `TypeError`，或 `start` 一直沒有回應（F1 已修，若再發生先看 `📥 [API] start 回傳` 的 `session_id`） |
| 跳出「登入已過期」 | Console 會有 `🔴🔴🔴 [API] xxx 回 401`。重新登入即可；開發時也可能是後端換了 JWT secret |
| 成績沒進後端 | Console 找 `🔴 [API]`；最常見是 401、逾時（4 秒），或 trycloudflare 網址換了 |
| 圖片顯示不出來 | `target_item` 字串有沒有包含「鮭魚／鱸魚／fish2／fish3」，沒有的話都顯示 `fish.png` |
| 手機上轉向不對 | §17-5；Web 上鎖轉向本來就沒作用 |
| 想看後端設定 | `curl <serverUrl>/api/games/market-route/config/`（不需要 token） |

所有 API log 都用 `debugPrint` 印出，`flutter run -d chrome` 時會出現在**終端機**，
也可以在 Chrome DevTools 的 Console 看到。
