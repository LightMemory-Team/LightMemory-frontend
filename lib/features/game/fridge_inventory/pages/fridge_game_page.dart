import 'package:flutter/material.dart';

import '../../go_to_market/services/audio_service.dart';
import '../../widgets/game_pause.dart';
import '../../widgets/game_in_progress_top_bar.dart';
import '../../../../screens/notification_screen.dart';
import '../models/fridge_inventory_model.dart';
import '../services/fridge_inventory_service.dart';
import 'fridge_result_page.dart';
import 'fridge_tutorial_page.dart';

class FridgeGamePage extends StatefulWidget {
  const FridgeGamePage({super.key});

  @override
  State<FridgeGamePage> createState() => _FridgeGamePageState();
}

class _FridgeGamePageState extends State<FridgeGamePage>
    with WidgetsBindingObserver {
  // ============================================================
  // 遊戲基本資料
  // ============================================================

  // 後端的 session_id 是 UUID 字串，必須用 String 保存
  String? _sessionId;

  bool _isLoading = true;
  String? _errorMessage;

  int _questionId = 101;
  int _reactionStartTime = 0;

  int _currentQuestionIndex = 1;
  int _totalQuestions = 10;

  double _currentScore = 0.0;

  String _difficulty = 'easy';
  int _remainingAttempts = 3;

  final Stopwatch _stopwatch = Stopwatch();

  // ============================================================
  // 玩家操作狀態
  // ============================================================

  String? _selectedSourceFoodCode;
  String? _feedbackState;

  FridgeQuestion? _currentQuestion;

  bool _isPausedBySystem = false;

  // ============================================================
  // 初始化
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initBackendGame();
  }

  // ============================================================
  // 釋放資源
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _stopwatch.stop();

    super.dispose();
  }

  // ============================================================
  // App 進入背景 / 回到前景
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !_isPausedBySystem) {
      _isPausedBySystem = true;

      _stopwatch.stop();

      _showGamePauseDialog();
    }
  }

  // ============================================================
  // 啟動後端遊戲
  // ============================================================

  Future<void> _initBackendGame() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final session = await FridgeInventoryService.startSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _sessionId = session.sessionId;

        _totalQuestions = session.totalQuestions;

        _currentQuestionIndex = session.currentQuestion;

        _difficulty = session.difficulty;

        _currentQuestion = session.question;

        _questionId = session.question.questionId;

        _remainingAttempts = 3;

        _currentScore = 0.0;

        _selectedSourceFoodCode = null;

        _feedbackState = null;

        _isLoading = false;
      });

      _stopwatch
        ..reset()
        ..start();

      _reactionStartTime = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('❌ 連線後端失敗: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = '無法連線至後端伺服器\n$e';
      });
    }
  }

  // ============================================================
  // 遊戲暫停
  // ============================================================

  void _showGamePauseDialog() {
    AudioService.playClick();

    _stopwatch.stop();

    GamePause.show(
      context,
      onResume: () {
        AudioService.playClick();

        _isPausedBySystem = false;

        _stopwatch.start();
      },
      onTutorial: () {
        AudioService.playClick();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FridgeTutorialPage()),
        ).then((_) {
          if (!mounted) {
            return;
          }

          _isPausedBySystem = false;

          _stopwatch.start();
        });
      },
      onRestart: () {
        AudioService.playClick();

        _isPausedBySystem = false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FridgeGamePage()),
        );
      },
      onExit: () {
        AudioService.playClick();

        Navigator.of(context).pop();

        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  // ============================================================
  // 玩家送出答案
  // ============================================================

  Future<void> _handleAnswerSubmit({String? foodCode, String? position}) async {
    // 已經有答題結果或沒有 session 時，不允許重複送出
    if (_feedbackState != null || _sessionId == null || _sessionId!.isEmpty) {
      return;
    }

    final int reactionTimeMs =
        DateTime.now().millisecondsSinceEpoch - _reactionStartTime;

    try {
      final result = await FridgeInventoryService.submitAnswer(
        sessionId: _sessionId!,
        questionId: _questionId,
        reactionTimeMs: reactionTimeMs,
        foodCode: foodCode,
        position: position,
      );

      // ========================================================
      // 取得後端結果
      // ========================================================

      final bool isCorrect = result['is_correct'] == true;

      final bool isCompleted = result['is_completed'] == true;

      // ========================================================
      // 答對
      // ========================================================

      if (isCorrect) {
        AudioService.playCorrect();

        final dynamic rawScore = result['current_score'];

        final double newScore = rawScore is num
            ? rawScore.toDouble()
            : _currentScore + 10.0;

        if (!mounted) {
          return;
        }

        setState(() {
          _feedbackState = 'correct';

          _currentScore = newScore;
        });

        // 顯示答對效果
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) {
            return;
          }

          if (isCompleted || _currentQuestionIndex >= _totalQuestions) {
            final dynamic rawFinal = result['final_score'];

            final double finalScore = rawFinal is num
                ? rawFinal.toDouble()
                : _currentScore;

            _showGameOverDialog(finalScore);
          } else {
            _loadNextQuestion(result);
          }
        });

        return;
      }

      // ========================================================
      // 答錯
      // ========================================================

      AudioService.playWrong();

      final dynamic rawAttempts = result['remaining_attempts'];

      final int remainingAttempts = rawAttempts is num
          ? rawAttempts.toInt()
          : (_remainingAttempts - 1).clamp(0, 3);

      if (!mounted) {
        return;
      }

      setState(() {
        _remainingAttempts = remainingAttempts;

        _feedbackState = 'wrong';
      });

      // ========================================================
      // 沒有剩餘次數 → 下一題
      // ========================================================

      if (_remainingAttempts <= 0 || result['retry'] == false) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已達最大嘗試次數，進入下一題'),
              duration: Duration(milliseconds: 800),
            ),
          );

          if (isCompleted || _currentQuestionIndex >= _totalQuestions) {
            final dynamic rawFinal = result['final_score'];

            final double finalScore = rawFinal is num
                ? rawFinal.toDouble()
                : _currentScore;

            _showGameOverDialog(finalScore);
          } else {
            _loadNextQuestion(result);
          }
        });
      } else {
        // ======================================================
        // 還有機會 → 清除錯誤狀態，讓玩家重新作答
        // ======================================================

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) {
            return;
          }

          setState(() {
            _feedbackState = null;

            _selectedSourceFoodCode = null;
          });
        });
      }
    } catch (e) {
      debugPrint('❌ 送出答案錯誤: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('後端判題發生錯誤：$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // 載入下一題
  // ============================================================

  void _loadNextQuestion(Map<String, dynamic> result) {
    final dynamic nextQData = result['next_question'];

    if (nextQData == null) {
      return;
    }

    try {
      final FridgeQuestion nextQuestion = FridgeQuestion.fromJson(nextQData);

      final dynamic rawQuestionIndex = result['current_question'];

      final int nextQuestionIndex = rawQuestionIndex is num
          ? rawQuestionIndex.toInt()
          : _currentQuestionIndex + 1;

      final dynamic rawAttempts = result['remaining_attempts'];

      final int nextAttempts = rawAttempts is num ? rawAttempts.toInt() : 3;

      final String nextDifficulty =
          result['difficulty']?.toString() ?? _difficulty;

      if (!mounted) {
        return;
      }

      setState(() {
        _currentQuestionIndex = nextQuestionIndex;

        _difficulty = nextDifficulty;

        _remainingAttempts = nextAttempts;

        _feedbackState = null;

        _selectedSourceFoodCode = null;

        _currentQuestion = nextQuestion;

        _questionId = nextQuestion.questionId;
      });

      _reactionStartTime = DateTime.now().millisecondsSinceEpoch;

      _stopwatch
        ..reset()
        ..start();
    } catch (e) {
      debugPrint('❌ 載入下一題失敗: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入下一題失敗：$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // ⭐ 測試成績頁
  //
  // 後端沒有開啟時，可以直接測試成績頁。
  // isTestMode = true 會讓成績頁使用測試歷史資料。
  // ============================================================

  void _openTestResultPage(double score) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FridgeResultPage(finalScore: score, isTestMode: true),
      ),
    );
  }

  // ============================================================
  // 遊戲結束 → 結果頁
  // ============================================================

  void _showGameOverDialog(double finalScore) {
    _stopwatch.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FridgeResultPage(finalScore: finalScore),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // 載入中
    // ==========================================================

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F1),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF355E3B)),
        ),
      );
    }

    // ==========================================================
    // 載入失敗
    // ==========================================================

    if (_errorMessage != null || _currentQuestion == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F5F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF355E3B)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: Color(0xFF52715A),
                ),

                const SizedBox(height: 16),

                Text(
                  _errorMessage ?? '無法取得題目資料',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF29442F),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // 重新連線
                // ==================================================
                SizedBox(
                  width: 220,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355E3B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _initBackendGame,
                    child: const Text(
                      '重新連線',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // 測試說明
                // ==================================================
                const Text(
                  '後端尚未開啟時，可以先測試成績頁',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A8C7E)),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // ==================================================
                // 100 分
                // ==================================================
                SizedBox(
                  width: 220,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF355E3B),
                      side: const BorderSide(
                        color: Color(0xFF355E3B),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _openTestResultPage(100);
                    },
                    child: const Text(
                      '測試成績頁（100 分）',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // 80 分
                // ==================================================
                SizedBox(
                  width: 220,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF355E3B),
                      side: const BorderSide(
                        color: Color(0xFF355E3B),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _openTestResultPage(80);
                    },
                    child: const Text(
                      '測試成績頁（80 分）',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // 45 分
                // ==================================================
                SizedBox(
                  width: 220,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF355E3B),
                      side: const BorderSide(
                        color: Color(0xFF355E3B),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _openTestResultPage(45);
                    },
                    child: const Text(
                      '測試成績頁（45 分）',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // 目前題目資料
    // ==========================================================

    final String prompt = _currentQuestion!.prompt;

    final List board = _currentQuestion!.board;

    final String questionType = _currentQuestion!.questionType;

    final SourceFood? sourceFood = _currentQuestion!.sourceFood;

    // ==========================================================
    // 冰箱邊框顏色
    // ==========================================================

    Color boardBorderColor = const Color(0xFF52715A);

    double boardBorderWidth = 2;

    if (_feedbackState == 'correct') {
      boardBorderColor = Colors.green;
      boardBorderWidth = 3.5;
    } else if (_feedbackState == 'wrong') {
      boardBorderColor = Colors.deepOrange;
      boardBorderWidth = 3.5;
    }

    // ==========================================================
    // 主畫面
    // ==========================================================

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),

      // 共用頂部列放在 appBar 的位置，下面 body 的版面完全不用動
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: GameInProgressTopBar(
            title: '冰箱清點',
            onMenuTap: _showGamePauseDialog,
            onNotificationTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ========================================================
            // 上方進度
            // ========================================================
            _buildTopProgress(),

            const SizedBox(height: 12),

            // ========================================================
            // 題目
            // ========================================================
            _buildQuestionCard(prompt),

            const SizedBox(height: 12),

            // ========================================================
            // 冰箱
            // ========================================================
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7E0D8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: boardBorderColor,
                        width: boardBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),

                        if (_feedbackState != null)
                          BoxShadow(
                            color: _feedbackState == 'correct'
                                ? Colors.green.withOpacity(0.35)
                                : Colors.deepOrange.withOpacity(0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: _buildFridgeInterior(board, questionType),
                  ),

                  // 答對提示
                  if (_feedbackState == 'correct')
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 64,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ),

            // ========================================================
            // 困難模式：待放入食材
            // ========================================================
            if (questionType == 'place_item' && sourceFood != null) ...[
              const SizedBox(height: 12),
              _buildBottomSourceTray(sourceFood),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 上方進度
  // ============================================================

  Widget _buildTopProgress() {
    final double progress = _totalQuestions > 0
        ? (_currentQuestionIndex / _totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    String difficultyText = '簡單難度';

    if (_difficulty == 'medium') {
      difficultyText = '中等難度';
    } else if (_difficulty == 'hard') {
      difficultyText = '困難難度';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE7DD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFAFC0B1)),
          ),
          child: Text(
            difficultyText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF355E3B),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          '$_currentQuestionIndex/$_totalQuestions',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFDDE5DF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF355E3B)),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 題目卡片
  // ============================================================

  Widget _buildQuestionCard(String prompt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8D5CA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        prompt,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29442F),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ============================================================
  // 冰箱內部
  // ============================================================

  Widget _buildFridgeInterior(List board, String questionType) {
    final List r1 = board
        .where((item) => item.position.toString().startsWith('r1'))
        .toList();

    final List r2 = board
        .where((item) => item.position.toString().startsWith('r2'))
        .toList();

    final List r3 = board
        .where((item) => item.position.toString().startsWith('r3'))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECE6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7E9784), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            _buildFridgeHeader(),

            Expanded(
              flex: 10,
              child: _buildBoardRow(r1, questionType, verticalPadding: 4),
            ),

            _buildGlassShelf(),

            Expanded(
              flex: 10,
              child: _buildBoardRow(r2, questionType, verticalPadding: 4),
            ),

            _buildGlassShelf(),

            Expanded(
              flex: 10,
              child: _buildCrisperDrawer(
                child: _buildBoardRow(
                  r3,
                  questionType,
                  verticalPadding: 4,
                  lowerItems: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 冰箱上方冷藏室
  // ============================================================

  Widget _buildFridgeHeader() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF3EF), Color(0xFFD5DFD7)],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF9DB2A1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8DD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4CFA9), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFF4A8).withOpacity(0.65),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          const Icon(Icons.ac_unit, size: 18, color: Color(0xFF587563)),

          const SizedBox(width: 6),

          const Text(
            '冷藏室',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF355E3B),
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(left: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6E8675),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 玻璃層板
  // ============================================================

  Widget _buildGlassShelf() {
    return Container(
      height: 13,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAFC0B4), Color(0xFFDDE6DF), Color(0xFF91A697)],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF7D9484), width: 1),
          bottom: BorderSide(color: Color(0xFFF8FAF9), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 蔬果保鮮抽屜
  // ============================================================

  Widget _buildCrisperDrawer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 3, 5, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDE8DF), Color(0xFFC8D8CB)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF91A697), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 8),
              child: child,
            ),
          ),

          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 90,
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6E8675), Color(0xFFAFC0B4)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFF617969),
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 九宮格
  // ============================================================

  Widget _buildBoardRow(
    List items,
    String questionType, {
    double verticalPadding = 4,
    bool lowerItems = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: items.map((item) {
        final String position = item.position.toString();

        final String? foodCode = item.foodCode?.toString();

        final String? foodName = item.foodName?.toString();

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AudioService.playClick();

              // ==================================================
              // 簡單模式
              // ==================================================

              if (_difficulty == 'easy') {
                _handleAnswerSubmit(foodCode: foodCode);
              }
              // ==================================================
              // 中等模式
              // ==================================================
              else if (_difficulty == 'medium') {
                _handleAnswerSubmit(position: position);
              }
              // ==================================================
              // 困難模式
              // ==================================================
              else if (_difficulty == 'hard') {
                if (_selectedSourceFoodCode != null) {
                  _handleAnswerSubmit(
                    foodCode: _selectedSourceFoodCode,
                    position: position,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('請先點擊下方待放入的食材！'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
                }
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 2,
                vertical: verticalPadding,
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: foodCode != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/game/'
                              'fridge_inventory/'
                              '$foodCode.png',
                              height: 72,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.fastfood,
                                  size: 44,
                                  color: Color(0xFF355E3B),
                                );
                              },
                            ),

                            const SizedBox(height: 2),

                            Text(
                              foodName ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF355E3B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 困難模式：待放入食材
  // ============================================================

  Widget _buildBottomSourceTray(SourceFood sourceFood) {
    final String code = sourceFood.foodCode;

    final String name = sourceFood.foodName;

    final bool isSelected = _selectedSourceFoodCode == code;

    return GestureDetector(
      onTap: () {
        AudioService.playClick();

        setState(() {
          _selectedSourceFoodCode = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? const [Color(0xFFDCE8DE), Color(0xFFC8DCCB)]
                : const [Colors.white, Color(0xFFEDF3EE)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF355E3B)
                : const Color(0xFFB9C9BC),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.06),
              blurRadius: isSelected ? 8 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '待放入食材',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF355E3B),
              ),
            ),

            const SizedBox(width: 12),

            Container(
              width: 76,
              height: 62,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB9C9BC)),
              ),
              child: Image.asset(
                'assets/images/game/'
                'fridge_inventory/'
                '$code.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.fastfood,
                    size: 44,
                    color: Color(0xFF355E3B),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29442F),
              ),
            ),

            if (isSelected) ...[
              const SizedBox(width: 10),

              const Icon(
                Icons.check_circle,
                color: Color(0xFF355E3B),
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
