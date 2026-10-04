import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cooking_prep_model.dart';
import '../models/cooking_prep_asset_map.dart';
import '../widgets/chopping_reward_scene.dart';
import '../widgets/chopping_display_scene.dart';
import '../widgets/seasoning_pour_scene.dart';
import '../widgets/seasoning_soup_reward_scene.dart';
import '../widgets/cooking_pot_scene.dart';
import '../widgets/memory_recall_option_cards.dart';
import '../widgets/cooking_prep_background.dart';
import '../widgets/cooking_prep_tutorial_dialog.dart';
import '../../market_shopping/widgets/game_in_progress_top_bar.dart';
import '../../widgets/game_pause.dart';
import '../../go_to_market/widgets/market_result_dialog.dart';
import '../models/memory_recall_model.dart';
import '../services/memory_recall_service.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../screens/notification_screen.dart';
import '../../../../screens/game_home_screen.dart';

/// 單獨展示一個物品要停留多久（開局展示 A、B 兩次，之後每輪答完展示一次
/// 新物品，都用這個常數）。後端沒有提供這個秒數，由前端自訂，覺得太快/
/// 太慢可以直接調整這裡。
const Duration kItemPreviewDisplayDuration = Duration(milliseconds: 1500);

/// 料理準備＝記憶配對（memory_recall）的美術主題包裝。
/// 題目、選項、階段、升階、計分全部由後端決定（MemoryRecallService），
/// 這裡不再有任何本地隨機出題或本地難度判斷邏輯。
///
/// ver6 玩法（1-back 連續配對，物品序列 ...,P(N-1),P(N),P(N+1),...，
/// P(0)=seed_item）：
///
/// 2026-10 後端團隊看過實測 log 後指出 ver5 有一個時間點搞錯的 bug（不是
/// 數值錯、是「什麼時候展示」錯）：ver5 在「第N輪選項卡出現之前」展示的是
/// 上一輪（N-1）的 new_item——這個值剛好就是第N輪的正解，等於在出題前就
/// 把答案秀給玩家看，整個遊戲變成「看了就選」，不是真正的 1-back 記憶測驗
/// （1-back 的精神是玩家要記住「上一步」看過的東西，不能馬上又被重新提示
/// 一次）。正確的時間點：
/// - 呼叫 round/ 拿到第N輪資料的當下，要展示的是「這一輪自己的」
///   new_item（= P(N)），不是上一輪的。這個值依照後端的 1-back 規則，
///   保證不會出現在這一輪自己的 option_items 裡（2026-10 實測、含故意
///   答錯干擾，100+ 輪 0 例外）——這一輪展示它純粹是為了讓玩家記住，
///   真正會用到是在「下一輪」出選項卡的時候。
/// - 這一輪選項卡（option_items）的正解＝上一輪自己的 new_item（=
///   P(N-1)），那個早在「上一輪」處理的時候就已經展示過了，這裡不重複
///   展示——玩家要憑記憶認出來，不是靠畫面剛好又提示一次。
/// - 整場遊戲只有第1輪例外：因為還沒有「上一輪」可以提供 P(N-1)，所以
///   第1輪要連續展示兩個：先 seed_item（=P(0)，start/ 給的），再展示
///   第1輪自己的 new_item（=P(1)），之後才揭曉第1輪的選項卡（正解＝
///   seed_item）。第2輪開始，每一輪都只展示 1 個物品（那一輪自己的
///   new_item），不再有任何「展示兩個物品」的情況——ver5 原本以為換階段
///   那一輪也要展示兩個（見下面「已拿掉的 isStageOpening」），已確認是
///   誤判，整條鏈從第1輪到遊戲結束都是「每輪展示1個、只有第1輪展示2個」，
///   不會因為升階而改變。
/// - 前端完全不用自己判斷「選項卡裡哪張是正解」——只負責決定「這輪要
///   展示什麼」跟送出 selected_item，正確與否永遠由後端 round/answer/
///   的 is_correct 回答。
/// - 依 round/answer/ 回傳的 action 決定下一步
///   （next_question/promoted/finished/time_up）
/// - 答錯不重試，直接進下一輪（物品鏈不管答對答錯都照樣往下走，2026-10
///   實測：故意穿插答錯，new_item 跟下一輪 option_items 的對應關係
///   不受影響）
///
/// 已拿掉的 isStageOpening／「橋接輪展示兩個物品」邏輯：ver5 誤以為換
/// 階段的那一輪需要比照開局展示兩個物品，是因為當時還沒請教後端，自己
/// 用「action==promoted」「stage 是否改變」這些間接訊號去猜測。後端
/// 2026-10 說明：升階不會換種子、鏈不會中斷（`round/answer/`
/// 也因此不再回傳 seed_item，整場遊戲只有 start/ 那一次用得到），所以
/// 換階段跟平常任何一輪一樣，只展示這一輪自己的 new_item 一個，不需要
/// 任何特殊處理。原本發現的「橋接輪」現象（升階後下一次 round/ 的 stage
/// 欄位還停在舊階段、下下輪才真的變成新階段）依然存在、依然真實，只是
/// 不影響展示幾個物品——純粹代表畫面主題切換會晚一輪，已知的小瑕疵：
/// 這種情況下畫面主題用的是舊階段的場景，但展示的 new_item 圖片可能已經
/// 是新階段的物品（後端也證實高階卡片的干擾物可能來自任何階段，不只同組
/// ——kMemoryRecallItemImages 本來就收錄全部階段的字串，圖片找得到，
/// 只是場景道具可能跟物品種類不完全搭），沒有特別處理，影響很小。
///
/// 畫面主題（背景、頂部標題用的 _currentStage）維持用「這一輪 round/
/// 自己回報的 stage」，不用 round/answer/ 的 current_stage——那個欄位
/// 在 promoted 當下就先變了，但畫面實際展示的物品要到橋接輪之後才真的
/// 換，兩者對齊才不會出現「畫面已經是調味主題、展示的卻還是切菜食材」
/// 這種不一致。
class CookingPrepGamePage extends StatefulWidget {
  const CookingPrepGamePage({super.key});

  @override
  State<CookingPrepGamePage> createState() => _CookingPrepGamePageState();
}

class _CookingPrepGamePageState extends State<CookingPrepGamePage>
    with SingleTickerProviderStateMixin {
  static const String _prefsHasPlayedKey = 'memory_recall_has_played';
  static const String _prefsScoreListKey = 'cooking_prep_score_list';
  static const String _prefsHighestScoreKey = 'cooking_prep_highest_score';

  int? _sessionId;
  bool _isPretest = false;
  int _pretestTotalRounds = 4;
  String _currentStage = 'basic';

  // 目前正在作答（已經揭曉兩張選項卡）的那一輪。
  MemoryRecallRound? _currentRound;
  List<String> _optionOrder = [];
  DateTime? _questionShownAt;

  // 已經抓到資料、但還在「單獨展示新物品」階段、還沒揭曉選項卡的下一輪。
  MemoryRecallRound? _pendingRound;

  // 還沒展示完的物品佇列：開局是 [A, B] 兩個，之後每輪都只有 1 個新物品。
  List<String> _previewQueue = [];
  bool _isShowingPreview = false;
  String? _previewItem;

  // 單獨展示物品的計時，用 AnimationController 而不是 Future.delayed，
  // 因為 AnimationController.stop() 會保留當下的 value，暫停選單開著時
  // 呼叫 stop()、繼續遊戲時呼叫 forward()（不帶 from）就會從暫停的地方
  // 接續，不會重新開始計時、暫停期間也不會在背景繼續跑。
  late final AnimationController _phaseController;

  // 每次呼叫 fetchRound 就 +1，靠這個 token 確認非同步結果回來時還是
  // 「同一次請求」，避免重來/離開後舊的 callback 還跑完把畫面搞亂。
  int _roundToken = 0;

  bool _hasAnswered = false;
  String? _selectedItem;
  // 前端事先不知道哪張卡是正解，只能在送出答案、後端回傳 is_correct 後
  // 才知道「剛剛選的那張」對不對，所以用這個欄位記錄最近一次作答結果，
  // 選項卡只針對「被選中的那張」畫勾/叉，沒被選中的那張即使是正解也不會
  // 特別標示（因為前端根本不知道）。
  bool? _lastAnswerCorrect;
  bool _isShowingReward = false;
  bool _isCelebratingAdvanced = false;
  MemoryRecallAnswerResult? _pendingResult;

  String? _startErrorMessage;

  // config/ 給的真正時長數字，用來算進度條「已經用掉幾成」的視覺比例，
  // 不影響「時間到了沒」的判定——那個判定只看 expiresAt 是否已經過去。
  // 抓不到 config/ 時才會退回下面這兩個預設值頂著，避免進度條整個壞掉。
  int _baseTimeLimitSeconds = 60;
  int _promoteBonusSeconds = 15;

  DateTime? _expiresAt;
  Timer? _tickTimer;
  DateTime? _pausedAt;
  double _timeProgress = 0.0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();

    // 橫向只鎖這個遊戲頁面本身，不影響 App 其他頁面
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _phaseController = AnimationController(vsync: this);
    _phaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onPreviewDisplayDone();
      }
    });

    _startGame();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _phaseController.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() {
      _isGameOver = false;
      _currentRound = null;
      _pendingRound = null;
      _previewQueue = [];
      _startErrorMessage = null;
      _timeProgress = 0.0;
      _expiresAt = null;
      _isShowingPreview = false;
      _previewItem = null;
      // 清掉上一場可能殘留的暫停時間點：如果玩家上一場在暫停選單裡直接
      // 按「重新開始」、沒有先按「繼續遊戲」，_pausedAt 會是舊的時間戳，
      // 沒清掉的話之後 _resumeTimers() 會拿這場全新遊戲的「現在」去減
      // 一個很舊的時間，算出離譜的補償秒數。
      _pausedAt = null;
      // 清掉上一場可能殘留的 reward 畫面旗標：如果上一場的最後一輪剛好
      // 是切菜／調味階段答對（會先顯示 reward 動畫才呼叫 finish/），
      // _isShowingReward 會停在 true、而且不會被任何地方清掉（結算對話框
      // 只是疊在上面的 overlay，底下的頁面還在）。這時如果玩家按「再玩
      // 一次」，_currentRound 會被上面重置成 null，但 _isShowingReward
      // 還是 true，_buildContent() 會再次呼叫 _buildRewardWidget()，裡面
      // 的 `_currentRound!` 就會對一個 null 值做 null check、直接崩潰
      // （紅底黃字 Null check operator used on a null value）。這裡一併
      // 清掉，連同 _pendingResult（_onRewardCompleted 的防呆分支也依賴
      // 它）、_hasAnswered／_selectedItem／_lastAnswerCorrect（舊答題
      // 狀態也不該帶到新的一場）。
      _isShowingReward = false;
      _pendingResult = null;
      _hasAnswered = false;
      _selectedItem = null;
      _lastAnswerCorrect = null;
    });
    _tickTimer?.cancel();

    // 規格書：使用者首次玩固定跑前測。後端 start/ 不帶 is_pretest 時
    // 預設是 false（不會自動判斷首次），所以前端自己用本地旗標記錄
    // 「玩過了嗎」（比照 go_to_market 的 hasPlayed 模式，討論確認過）。
    final prefs = await SharedPreferences.getInstance();
    final hasPlayedBefore = prefs.getBool(_prefsHasPlayedKey) ?? false;
    final isPretest = !hasPlayedBefore;

    try {
      final config = await MemoryRecallService.fetchConfig();
      _pretestTotalRounds = config.pretestTotalRounds;
      _baseTimeLimitSeconds = config.baseTimeLimitSeconds;
      _promoteBonusSeconds = config.promoteBonusSeconds;
    } catch (e) {
      debugPrint('⚠️ 讀取 config/ 失敗，前測輪數／時長維持預設值: $e');
    }
    if (!mounted) return;

    MemoryRecallSession session;
    try {
      session = await MemoryRecallService.startGame(isPretest: isPretest);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startErrorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (!mounted) return;

    if (isPretest) {
      await prefs.setBool(_prefsHasPlayedKey, true);
    }

    _sessionId = session.sessionId;
    _isPretest = session.isPretest;
    _currentStage = session.currentStage;
    _expiresAt = session.expiresAt;
    if (!mounted) return;

    // 每次開局都顯示教學，教學關閉後才開始出第一題。教學彈窗顯示期間要
    // 真正暫停計時（不能先 _startTicking() 再讓教學蓋在上面——那樣
    // expires_at 會在玩家閱讀教學的這段時間被背景偷跑掉），所以這裡先
    // 暫停、教學關閉後才用 _resumeTimers() 接續剩餘秒數、真正開始倒數。
    _pauseTimers();
    await CookingPrepTutorialDialog.show(context);
    if (!mounted) return;
    _resumeTimers();

    // 開局：抓第1輪資料，依序單獨展示兩個物品，展示完才揭曉第1輪的選項
    // 畫面。session.seedItem 是後端明確告訴我們「真正先出現」的那一個
    // （實測確認 option_items 陣列順序是隨機的，不能拿陣列順序當展示
    // 順序，見類別註解），一定要傳進去，不能省略。
    await _fetchNextRoundAndPreview(initialAnchor: session.seedItem);
  }

  void _restart() {
    _tickTimer?.cancel();
    _startGame();
  }

  /// 開始展示 _previewQueue 裡的下一個物品；佇列空了就揭曉 _pendingRound。
  void _startPreviewQueue() {
    if (_previewQueue.isEmpty) {
      debugPrint('🔍 [round-flow] 預覽佇列是空的，直接揭曉選項畫面');
      _revealPendingRound();
      return;
    }
    debugPrint('🔍 [round-flow] 開始預覽物品：${_previewQueue.first}'
        '（佇列剩餘 ${_previewQueue.length} 個）');
    setState(() {
      // 跟 _isShowingPreview 一起在同一個 setState 裡關閉，確保「reward
      // 動畫播完」跟「下一輪的展示畫面出現」是同一個畫面更新，中間不會有
      // 任何一個 frame 是兩者都是 false、導致 _buildContent() 掉回去畫
      // 舊選項畫面（答對後動畫播完不小心跳回選項畫面的成因就是這裡）。
      _isShowingReward = false;
      _isShowingPreview = true;
      _previewItem = _previewQueue.first;
    });
    _phaseController.duration = kItemPreviewDisplayDuration;
    _phaseController.forward(from: 0);
  }

  /// 一個物品展示完畢：佇列還有就接著展示下一個，沒有就揭曉選項卡。
  /// 暫停時 _phaseController 會被 stop()，不會觸發這個 callback；
  /// 繼續遊戲後 forward() 從暫停的地方接續，一樣會自然走到這裡。
  void _onPreviewDisplayDone() {
    debugPrint('🔍 [round-flow] 一個物品預覽結束'
        '（mounted=$mounted, isGameOver=$_isGameOver）');
    if (!mounted || _isGameOver) return;
    if (_previewQueue.isNotEmpty) {
      _previewQueue.removeAt(0);
    }
    if (_previewQueue.isNotEmpty) {
      debugPrint('🔍 [round-flow] 佇列還有物品，接著預覽：${_previewQueue.first}');
      setState(() => _previewItem = _previewQueue.first);
      _phaseController.forward(from: 0);
    } else {
      debugPrint('🔍 [round-flow] 佇列展示完畢，準備揭曉選項畫面');
      setState(() => _isShowingPreview = false);
      _revealPendingRound();
    }
  }

  /// 把已經抓好、正在等待展示完畢的 _pendingRound 揭曉成正式的選項畫面。
  void _revealPendingRound() {
    final round = _pendingRound;
    if (round == null) {
      debugPrint('⚠️ [round-flow] _revealPendingRound 被呼叫但 _pendingRound '
          '是 null，畫面不會跳出來就是卡在這裡——理論上不該發生，代表前面哪個'
          '步驟漏了設定 _pendingRound 就呼叫了這個方法');
      return;
    }
    if (!mounted || _isGameOver) {
      debugPrint('🔍 [round-flow] _revealPendingRound：頁面已離開或遊戲已結束，'
          '不揭曉了（mounted=$mounted, isGameOver=$_isGameOver）');
      return;
    }
    debugPrint('🔍 [round-flow] 揭曉選項畫面：round=${round.roundNumber} '
        'stage=${round.stage} options=${round.optionItems}');
    _pendingRound = null;
    setState(() {
      _currentRound = round;
      _optionOrder = List<String>.from(round.optionItems)..shuffle();
      _hasAnswered = false;
      _selectedItem = null;
      _lastAnswerCorrect = null;
      _isShowingReward = false;
    });
    _questionShownAt = DateTime.now();
  }

  // ── 倒數顯示（僅供顯示；真正判斷時間到不到全部看後端 action）──────────

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!mounted || _expiresAt == null || _isGameOver) return;

    final remaining = _expiresAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      setState(() => _timeProgress = 1.0);
      _tickTimer?.cancel();
      // 本地視覺時間到了：玩家可能還卡在畫面沒送出答案，這時主動呼叫
      // finish/（比照規格書「玩家中途離開時前端主動呼叫 finish/」的精神），
      // 不用一直等玩家送出答案才發現時間到。這不等於前端自己判定「時間到」
      // ——如果玩家剛好在這之前送出了答案，是否真的算逾時仍然以後端
      // round/answer/ 回傳的 action（time_up）為準。
      _finishGame();
      return;
    }

    setState(() {
      _timeProgress = 1 - (remaining.inSeconds / _approxTotalSeconds);
    });
  }

  // 用 config/ 給的真正數字算，不再用猜的固定值：basic 就是
  // baseTimeLimitSeconds，intermediate／advanced 各自再加上升階獎勵秒數
  // （每升一階 +1 次 promoteBonusSeconds），跟後端「每次升階直接延長
  // expires_at」的邏輯一致。
  int get _approxTotalSeconds {
    switch (_currentStage) {
      case 'intermediate':
        return _baseTimeLimitSeconds + _promoteBonusSeconds;
      case 'advanced':
        return _baseTimeLimitSeconds + _promoteBonusSeconds * 2;
      default:
        return _baseTimeLimitSeconds;
    }
  }

  // ── 出題／作答 ────────────────────────────────────────────────────

  /// 抓下一輪資料並準備好要展示的預覽佇列。整場遊戲開局（從 _startGame
  /// 呼叫，帶 [initialAnchor] = seed_item）跟之後每一輪答完（不管
  /// action 是 next_question 還是 promoted）都走這一個方法，不再分開
  /// 處理。
  ///
  /// 要展示什麼完全不用看「上一輪」的任何資料（見類別註解 ver6 說明）：
  /// - 整場遊戲第一輪（[_currentRound] 還是 null）：展示 [initialAnchor]
  ///   （= seed_item）再展示這一輪自己的 new_item，兩個都展示完才揭曉
  ///   第1輪的選項卡。
  /// - 第2輪開始：只展示這一輪自己的 new_item 一個——這個物品保證不在
  ///   這一輪自己的 option_items 裡（它是「下一輪」的伏筆，不是這一輪的
  ///   提示），這一輪選項卡的正解是「上一輪」的 new_item，那個已經在上
  ///   一輪處理時展示過了，這裡故意不重複展示。
  /// 不再有 ver5 那套「比較 stage 是否改變、換階段展示兩個物品」的邏輯，
  /// 整條鏈（含換階段）一律只有第1輪展示兩個，其餘每輪都展示 1 個。
  Future<void> _fetchNextRoundAndPreview({String? initialAnchor}) async {
    if (_isGameOver || _sessionId == null) return;
    final isFirstRound = _currentRound == null;
    final token = ++_roundToken;
    debugPrint('🔍 [round-flow] 下一輪：呼叫 round/ 開始');

    MemoryRecallRound round;
    try {
      round = await MemoryRecallService.fetchRound(sessionId: _sessionId!);
    } catch (e) {
      debugPrint('🔍 [round-flow] 下一輪：呼叫 round/ 失敗 $e');
      if (!mounted || token != _roundToken) return;
      if (isFirstRound) {
        // 整場遊戲開局就失敗，沒有舊畫面可以繼續顯示，只能停在錯誤畫面。
        setState(() {
          _startErrorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } else {
        // 遊戲進行中拿不到題目（例如剛好時間到、session 已結束），直接
        // 走結算流程比讓玩家卡在轉圈圈畫面好。
        await _finishGame();
      }
      return;
    }
    if (!mounted || token != _roundToken) return;

    debugPrint('🔍 [DIAG] round=${round.roundNumber} stage=${round.stage} '
        'option_items=${round.optionItems} new_item=${round.newItem} '
        'isFirstRound=$isFirstRound');

    if (isFirstRound) {
      if (initialAnchor != null && !round.optionItems.contains(initialAnchor)) {
        debugPrint('⚠️ [DIAG] seed_item ($initialAnchor) 對不上第1輪 '
            'optionItems (${round.optionItems})，資料可能異常，仍照原計畫展示');
      }
      _previewQueue = [?initialAnchor, ?round.newItem];
    } else {
      // 這一輪自己的 new_item 照定義不會出現在這一輪的 optionItems 裡，
      // 不需要（也不該）驗證它是不是 optionItems 的成員。
      _previewQueue = round.newItem != null ? [round.newItem!] : [];
    }

    _pendingRound = round;
    // 畫面主題（背景、頂部標題）一律用這一輪 round/ 自己回報的 stage，
    // 不用 round/answer/ 的 current_stage，理由見類別註解。
    _currentStage = round.stage;
    debugPrint('🔍 [DIAG] 畫面即將展示的預覽佇列（含順序）：$_previewQueue');
    _startPreviewQueue();
  }

  Future<void> _onOptionTap(String item) async {
    if (_hasAnswered || _currentRound == null) return;
    AudioService.play('normal.mp3');

    final responseTimeMs = _questionShownAt == null
        ? 0
        : DateTime.now().difference(_questionShownAt!).inMilliseconds;
    final questionStage = _currentRound!.stage;
    final roundNumber = _currentRound!.roundNumber;
    final currentOptions = _currentRound!.optionItems;

    setState(() {
      _hasAnswered = true;
      _selectedItem = item;
    });

    debugPrint('🔍 [round-flow] 送出答案開始：round=$roundNumber selected=$item');
    MemoryRecallAnswerResult result;
    try {
      result = await MemoryRecallService.submitAnswer(
        sessionId: _sessionId!,
        roundNumber: roundNumber,
        selectedItem: item,
        responseTimeMs: responseTimeMs,
      );
    } catch (e) {
      debugPrint('🔍 [round-flow] 送出答案失敗 $e');
      // SESSION_ALREADY_FINISHED／GAME_TIME_UP 這類錯誤，直接視同結束
      if (!mounted) return;
      await _finishGame();
      return;
    }
    if (!mounted) return;
    debugPrint('🔍 [DIAG] 玩家點了：$item（round=$roundNumber stage=$questionStage '
        'options=$currentOptions）→ 後端 is_correct=${result.isCorrect} '
        'action=${result.action} currentStage=${result.currentStage}');

    // 注意：這裡不更新 _currentStage（畫面主題用的那個）。result.currentStage
    // 在 promoted 當下就先變了，但畫面實際展示的物品要到下一次
    // _fetchNextRoundAndPreview 抓到「真正換階段那一輪」才會換，_currentStage
    // 統一由那邊更新，理由見類別註解。這裡的 result.currentStage 只用來組
    // 下面的升階提示文字，不寫回 state。
    setState(() {
      _lastAnswerCorrect = result.isCorrect;
      if (result.expiresAt != null) _expiresAt = result.expiresAt;
    });

    if (result.isCorrect) {
      AudioService.play('correct.mp3');
      if (questionStage == 'basic') {
        _playChopSound();
      }
    } else {
      AudioService.play('no.mp3');
    }

    if (result.action == 'promoted' && mounted) {
      final bonus = result.bonusSecondsGranted;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '太棒了！進入「${result.currentStage.cookingStageTitle}」關卡'
            '${bonus > 0 ? '，時間 +$bonus 秒' : ''}',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 答對才播主題裝飾動畫：切菜用 ChoppingRewardScene、調味用完整湯圖片。
    // 烹飪（advanced）答對後不用任何特效動畫，跟答錯一樣直接停留一下
    // 讓玩家看清楚選項卡的提示、就進下一輪，沒有額外的鍋鏟/攪拌效果。
    // 咖哩飯彩蛋不在這裡播——彩蛋只在整場遊戲結束時、且玩到過烹飪階段
    // 才播一次，見 _finishGame。
    if (result.isCorrect && questionStage != 'advanced') {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _pendingResult = result;
      setState(() => _isShowingReward = true);
      return; // 剩下交給 reward 動畫播完的 _onRewardCompleted
    }

    // 答錯，或是 advanced 階段答對：沒有 reward 動畫，停留一下讓玩家
    // 看清楚選項卡的提示再進下一題（答對停留短一點，答錯久一點）。
    await Future.delayed(
      Duration(milliseconds: result.isCorrect ? 1000 : 1800),
    );
    if (!mounted) return;

    await _afterAnswerResolved(result);
  }

  Future<void> _onRewardCompleted() async {
    if (!mounted) return;
    final result = _pendingResult;
    _pendingResult = null;
    if (result == null) {
      // 防呆：理論上不會發生（沒有 pending 結果代表流程哪裡漏接），
      // 這裡沒有下一個畫面可以接手，只好單獨關閉 reward 畫面避免卡住。
      setState(() => _isShowingReward = false);
      return;
    }

    // 不在這裡提前關閉 _isShowingReward——刻意讓 reward 動畫定格在最後一幀，
    // 一路撐到 _afterAnswerResolved 觸發的下一步（_startPreviewQueue／
    // _revealPendingRound／結算對話框）自己在它們的 setState 裡關閉，
    // 兩者合併成同一次畫面更新，才不會露出中間那個「兩者都是 false」的
    // 空窗，掉回去畫舊的選項畫面。
    await _afterAnswerResolved(result);
  }

  Future<void> _afterAnswerResolved(MemoryRecallAnswerResult result) async {
    if (result.action == 'finished' || result.action == 'time_up') {
      await _finishGame();
    } else {
      // next_question 跟 promoted 都走同一個方法：要不要展示開局的兩個
      // 物品，_fetchNextRoundAndPreview 自己會比較這一輪跟上一輪的
      // stage 決定，不需要在這裡用 action 分流（見類別註解 ver5 說明）。
      await _fetchNextRoundAndPreview();
    }
  }

  /// 進入結算前，如果這場遊戲有玩到烹飪（advanced）階段，播放一次彩蛋
  /// （咖哩飯圖片，固定顯示一段時間），播完才繼續進結算，只會在
  /// _finishGame 裡、確定 finalStage 是 advanced 時呼叫，不會跟著
  /// 「剛升階」的當下觸發。不再搭配影片播放（video_player 已經整個移除，
  /// 之前會導致 flutter run 卡在安裝 APK 到模擬器這一步）。
  Future<void> _playAdvancedCelebration() async {
    setState(() => _isCelebratingAdvanced = true);
    AudioService.play('correct.mp3');
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _isCelebratingAdvanced = false);
  }

  /// 切菜動畫播放同時觸發的音效，檔案是 assets/audio/game/cut.mp3。
  /// catchError 只是防止極端情況（例如音檔遺失）讓程式當掉。
  void _playChopSound() {
    AudioService.play('cut.mp3').catchError((e) {
      debugPrint('⚠️ 切菜音效播放失敗: $e');
    });
  }

  // ── 結算 ──────────────────────────────────────────────────────────

  Future<void> _finishGame() async {
    if (_isGameOver) return;
    _isGameOver = true;
    _tickTimer?.cancel();

    MemoryRecallResult? result;
    try {
      result = await MemoryRecallService.finishGame(sessionId: _sessionId!);
    } catch (e) {
      debugPrint('⚠️ finish/ 呼叫失敗: $e');
    }

    // 彩蛋只在「整場遊戲結束」且玩家有玩到烹飪（advanced）階段時才播放
    // 一次，播完才進結算——不再跟著「剛升階」的當下觸發。
    if (result?.finalStage == 'advanced' && mounted) {
      await _playAdvancedCelebration();
      if (!mounted) return;
    }

    // 正確率／分數／平均反應時間全部用後端 finish/ 回的真實數字，
    // 不自己算；前測 total_score 為 null，accuracy 仍然有值。
    final accuracyPercent =
        result == null ? 0 : (result.accuracy * 100).round();

    final history = <int>[];
    int highestScore = accuracyPercent;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_prefsScoreListKey);
      if (savedList != null) {
        for (final item in savedList) {
          final val = int.tryParse(item);
          if (val != null) history.add(val);
        }
      }

      history.add(accuracyPercent);
      while (history.length > 5) {
        history.removeAt(0);
      }

      await prefs.setStringList(
        _prefsScoreListKey,
        history.map((e) => e.toString()).toList(),
      );

      final storedHighest = prefs.getInt(_prefsHighestScoreKey) ?? 0;
      highestScore =
          storedHighest > accuracyPercent ? storedHighest : accuracyPercent;
      await prefs.setInt(_prefsHighestScoreKey, highestScore);
    } catch (e) {
      history
        ..clear()
        ..add(accuracyPercent);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MarketResultDialog(
        currentScore: accuracyPercent,
        highestScore: highestScore,
        history: history,
        onPlayAgain: _restart,
        onExit: _exitToHome,
        avgResponseTimeMs: result?.avgResponseTimeMs,
        totalScore: result?.totalScore,
      ),
    );
  }

  // ── 暫停／導航 ────────────────────────────────────────────────────

  /// 真正暫停遊戲計時：取消倒數 timer（_tick() 完全不會再執行，不是只有
  /// 畫面被蓋住）、凍結物品展示動畫、記錄暫停時間點。暫停選單跟教學彈窗
  /// （不論開局自動彈出還是從暫停選單點出來）都要呼叫這個。
  ///
  /// 用 `??=` 而不是直接賦值：如果呼叫時已經處於暫停狀態（例如從暫停
  /// 選單又點開教學，教學本身也呼叫一次這個方法），不能把 _pausedAt
  /// 洗成「現在」，不然等到真正恢復時只會補償到最後一段暫停的時長，
  /// 前面那段（暫停選單開著、還沒點教學）的時間就漏算、害 expires_at
  /// 實際上還是被背景偷跑掉。
  void _pauseTimers() {
    _tickTimer?.cancel();
    _phaseController.stop();
    _pausedAt ??= DateTime.now();
  }

  /// 真正恢復遊戲計時：把從 _pauseTimers() 到現在這段實際經過的時間
  /// 補回 expiresAt／questionShownAt，接續原本剩餘秒數繼續倒數，不是
  /// 重新開始算，也不是放任背景偷跑的時間真的生效。
  void _resumeTimers() {
    if (_pausedAt != null) {
      final pausedDuration = DateTime.now().difference(_pausedAt!);
      if (_expiresAt != null) {
        _expiresAt = _expiresAt!.add(pausedDuration);
      }
      // 回想階段的反應時間也要把暫停期間排除，不然玩家暫停越久、
      // response_time_ms 就會被灌越多不合理的水份。
      if (_questionShownAt != null && !_hasAnswered) {
        _questionShownAt = _questionShownAt!.add(pausedDuration);
      }
    }
    _pausedAt = null;
    if (_expiresAt != null) _startTicking();

    // 物品展示的計時也要跟著恢復，forward() 不帶 from 會從剛剛 stop()
    // 當下的 value 接續，不會重新開始。只在真的還在展示物品時才呼叫
    // ——其他情況 _phaseController 已經停在 value=1.0，這時再呼叫
    // forward() 可能會讓 completed 狀態被觸發第二次。
    if (_isShowingPreview) {
      _phaseController.forward();
    }
  }

  void _showPauseMenu() {
    _pauseTimers();
    GamePause.show(
      context,
      onResume: _resumeTimers,
      onTutorial: _showTutorialFromPauseMenu,
      onRestart: _restart,
      onExit: _exitToHome,
    );
  }

  /// 從暫停選單點「玩法教學」：遊戲本來就已經暫停（_showPauseMenu 進來
  /// 時呼叫過 _pauseTimers()），教學彈窗顯示期間繼續保持暫停狀態；教學
  /// 關閉後不直接恢復遊戲，而是回到暫停選單，讓玩家自己決定要繼續遊戲、
  /// 重新開始還是退出，避免教學關掉後畫面卡在「沒有任何彈窗、但遊戲其實
  /// 還是暫停」的中間狀態。
  void _showTutorialFromPauseMenu() {
    CookingPrepTutorialDialog.show(context).then((_) {
      if (!mounted) return;
      _showPauseMenu();
    });
  }

  void _exitToHome() {
    _tickTimer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const GameHomeScreen()),
      (route) => false,
    );
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  // ── 畫面 ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CookingPrepBackground(
        stage: _currentStage,
        child: SafeArea(
          child: Column(
            children: [
              GameInProgressTopBar(
                title: '料理準備・${_currentStage.cookingStageTitle}',
                onPauseTap: _showPauseMenu,
                onNotificationTap: _goToNotifications,
              ),
              if (_expiresAt != null) _buildGlobalTimeBar(),
              if (_isPretest) _buildPretestBadge(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalTimeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: _timeProgress.clamp(0.0, 1.0),
          minHeight: 10,
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          color: const Color(0xFF2D5A43),
        ),
      ),
    );
  }

  /// 前測沒有 expires_at（不啟用倒數），改顯示「第幾輪／固定4輪」讓玩家
  /// 知道進度（前測固定 4 輪、非計時制，規格書第三節）。
  Widget _buildPretestBadge() {
    final roundNumber = _currentRound?.roundNumber ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '練習題 $roundNumber / $_pretestTotalRounds',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5A43),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_startErrorMessage != null) {
      return _buildStartError();
    }

    if (_isCelebratingAdvanced) {
      return Center(child: _buildCelebration());
    }

    if (_isShowingReward) {
      return Center(child: _buildRewardWidget());
    }

    if (_isShowingPreview) {
      return _buildPreviewPhase();
    }

    if (_currentRound == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5A43)),
      );
    }

    return _buildRecallPhase();
  }

  Widget _buildStartError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
            const SizedBox(height: 16),
            Text(
              _startErrorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _startGame, child: const Text('重試')),
          ],
        ),
      ),
    );
  }

  /// 單獨展示一個物品：不作答、不計分、不算一輪，顯示
  /// kItemPreviewDisplayDuration 之後自動接續佇列或揭曉選項卡。場景照
  /// 當下 _currentStage 換皮（切菜=砧板+刀、調味=鍋子+倒入、烹飪=鍋子+
  /// 裝飾食材堆）。這裡在 ver3 改成每一輪答完都會播放（不是只有開局一次），
  /// 所以場景尺寸一定要用 LayoutBuilder 量出這個位置實際可用的高度，
  /// 不能只靠螢幕寬度概算，不然橫向螢幕高度不夠時會整個溢出（見場景元件
  /// 各自的 maxHeight 參數）；外層再包一層 SingleChildScrollView 當保險，
  /// 就算量出來的空間還是不夠，也是捲動而不是硬溢出。
  Widget _buildPreviewPhase() {
    final imagePath = imagePathForMemoryRecallItem(_previewItem ?? '');

    return LayoutBuilder(
      builder: (context, constraints) {
        // 扣掉上方留白（16px）、提示標籤（26px 字級+上下 padding 12*2，
        // 約 58px）、標籤跟進度條間距（14px）、進度條本身（8px）後，剩下
        // 的才是場景本身能用的高度——這個數字之前是 72，只夠裝舊版較小
        // 字級的純文字，改成膠囊標籤＋進度條之後空間不夠，會被底部邊界
        // 裁切，這裡照實際版面重新算過（16+58+14+8=96，抓 110 留一點餘裕）。
        // 上限抓 400、下限抓 80 避免極端情況算出離譜的值。
        final sceneMaxHeight = (constraints.maxHeight - 110).clamp(80.0, 400.0);

        Widget scene;
        switch (_currentStage) {
          case 'intermediate':
            scene = SeasoningPourScene(
              potImagePath: kSeasoningPotImagePath,
              seasoningImagePath: imagePath,
              maxHeight: sceneMaxHeight,
            );
            break;
          case 'advanced':
            scene = CookingPotScene(
              itemImagePath: imagePath,
              maxHeight: sceneMaxHeight,
            );
            break;
          default:
            scene = ChoppingDisplayScene(
              foodImagePath: imagePath,
              boardImagePath: kCuttingBoardImagePath,
              knifeImagePath: kChoppingPropIconPath,
              maxHeight: sceneMaxHeight,
            );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              // 整組畫面（場景＋提示標籤＋進度條）用 AnimatedSwitcher 做
              // 淡入＋輕微放大進場，key 用 _previewItem，每次換成新物品
              // 都會被視為「新的一個」，重新播一次進場動畫，不會整批
              // 僵硬地瞬間出現。
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOut),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(_previewItem),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    scene,
                    const SizedBox(height: 20),
                    _buildPreviewLabel(),
                    const SizedBox(height: 14),
                    _buildPreviewProgressBar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 「請記住這個」提示標籤：白底圓角膠囊卡片，比原本的純文字更醒目。
  Widget _buildPreviewLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '請記住這個',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D5A43),
        ),
      ),
    );
  }

  /// 物品展示階段的進度條：跟著 _phaseController 的進度隨時間縮短，
  /// 顏色跟選項卡（MemoryRecallOptionCards）同色系（深綠主色＋淺綠底）。
  Widget _buildPreviewProgressBar() {
    return SizedBox(
      width: 160,
      child: AnimatedBuilder(
        animation: _phaseController,
        builder: (context, child) {
          final remaining = (1 - _phaseController.value).clamp(0.0, 1.0);
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: const Color(0xFFDCE8DC),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: remaining,
                child: Container(color: const Color(0xFF2D5A43)),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 每一輪：2 個選項卡片同時顯示，玩家選出比較早出現的那個。答錯不重試，
  /// 直接送出結果換下一題。三階段共用 MemoryRecallOptionCards 版式。
  Widget _buildRecallPhase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: MemoryRecallOptionCards(
        items: _optionOrder,
        selectedItem: _selectedItem,
        hasAnswered: _hasAnswered,
        isCorrect: _lastAnswerCorrect,
        onTap: _onOptionTap,
      ),
    );
  }

  /// advanced 階段答對後不會走到這裡（見 _onOptionTap 的
  /// `result.isCorrect && questionStage != 'advanced'` 判斷，烹飪階段
  /// 答對就直接進下一輪，沒有額外特效動畫），這裡只剩 basic／intermediate
  /// 兩種情況。
  Widget _buildRewardWidget() {
    final round = _currentRound!;
    // 這裡只會在 result.isCorrect 時播放，答對代表「剛剛選的那張就是
    // 正解」，用 _selectedItem 就是正確的物品。
    final item = _selectedItem!;
    if (round.stage == 'basic') {
      return ChoppingRewardScene(
        beforeImagePath: imagePathForMemoryRecallItem(item),
        afterImagePath: choppedFlavorImagePath(item),
        boardImagePath: kCuttingBoardImagePath,
        knifeImagePath: kChoppingPropIconPath,
        onCompleted: _onRewardCompleted,
      );
    }
    // 直接淡入顯示對應的完整湯圖片，不疊鍋子圖、不疊顏色濾鏡。
    return SeasoningSoupRewardScene(
      soupImagePath: kSeasoningSoupImages[item] ?? kSeasoningPotImagePath,
      onCompleted: _onRewardCompleted,
    );
  }

  /// 整場遊戲結束彩蛋：只顯示咖哩飯圖片，看完直接進結算頁，不搭配影片。
  Widget _buildCelebration() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          kCelebrationImagePath,
          width: 180,
          height: 180,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE9B0),
            ),
            child: const Icon(
              Icons.emoji_food_beverage,
              size: 90,
              color: Color(0xFFE8A33D),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '恭喜完成烹飪關卡！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5A43),
          ),
        ),
      ],
    );
  }
}
