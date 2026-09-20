import 'package:flutter/material.dart';
import '../services/fridge_inventory_service.dart';
import '../models/fridge_inventory_model.dart';

class FridgeGamePage extends StatefulWidget {
  const FridgeGamePage({super.key});

  @override
  State<FridgeGamePage> createState() => _FridgeGamePageState();
}

class _FridgeGamePageState extends State<FridgeGamePage> {
  bool _isLoading = true;
  int? _sessionId;
  FridgeQuestion? _currentQuestion;

  // 遊戲狀態追蹤
  int _currentQuestionIndex = 1;
  int _totalQuestions = 10;
  int _currentScore = 0;
  String _difficulty = 'easy';
  int _remainingAttempts = 3;

  // 計時器 (計算反應時間 ms)
  final Stopwatch _stopwatch = Stopwatch();

  // Hard 模式下玩家選中的待放食材代碼
  String? _selectedSourceFoodCode;

  // 視覺回饋狀態 (答對/答錯時閃爍或變色)
  String? _highlightedPosition;
  bool? _lastAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _initGameSession();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  // 1. 初始化遊戲 Session
  Future<void> _initGameSession() async {
    setState(() => _isLoading = true);
    try {
      final session = await FridgeInventoryService.startSession();
      setState(() {
        _sessionId = session.sessionId;
        _totalQuestions = session.totalQuestions;
        _currentQuestionIndex = session.currentQuestion;
        _difficulty = session.difficulty;
        _currentQuestion = session.question;
        _isLoading = false;
      });
      _stopwatch.reset();
      _stopwatch.start();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('初始化遊戲失敗: $e')));
      }
    }
  }

  // 2. 提交答案
  Future<void> _handleAnswerSubmit({String? foodCode, String? position}) async {
    if (_sessionId == null || _currentQuestion == null) return;
    _stopwatch.stop();
    int reactionTimeMs = _stopwatch.elapsedMilliseconds;
    if (reactionTimeMs < 200) reactionTimeMs = 1500; // 確保數值合理

    final questionId = _currentQuestion!.questionId;

    try {
      final result = await FridgeInventoryService.submitAnswer(
        sessionId: _sessionId!,
        questionId: questionId,
        reactionTimeMs: reactionTimeMs,
        foodCode: foodCode,
        position: position,
      );

      bool isCorrect = result['is_correct'] ?? false;
      bool isCompleted = result['is_completed'] ?? false;
      bool retry = result['retry'] ?? false;

      setState(() {
        _lastAnswerCorrect = isCorrect;
        _currentScore = result['current_score'] ?? _currentScore;
        _remainingAttempts = result['remaining_attempts'] ?? 3;
        _difficulty = result['difficulty'] ?? _difficulty;
        _currentQuestionIndex =
            result['current_question'] ?? _currentQuestionIndex;
      });

      if (isCompleted) {
        _showGameOverDialog(result);
      } else if (isCorrect || !retry) {
        // 答對或錯滿 3 次強制跳題
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              if (result['next_question'] != null) {
                _currentQuestion = FridgeQuestion.fromJson(
                  result['next_question'],
                );
              }
              _selectedSourceFoodCode = null;
              _lastAnswerCorrect = null;
              _remainingAttempts = 3;
            });
            _stopwatch.reset();
            _stopwatch.start();
          }
        });
      } else {
        // 還可以重試
        setState(() {
          _selectedSourceFoodCode = null;
        });
        _stopwatch.reset();
        _stopwatch.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('送出答案發生錯誤: $e')));
      }
    }
  }

  void _showGameOverDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 遊戲完成！',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最終得分：${result['final_score']} 分'),
            Text(
              '平均反應時間：${(result['average_reaction_time_ms'] ?? 0) / 1000} 秒',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF557A46),
            ),
            onPressed: () {
              Navigator.pop(context); // 關閉對話框
              Navigator.pop(context); // 離開遊戲頁面
            },
            child: const Text('返回主選單', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF557A46)),
        ),
      );
    }

    final prompt = _currentQuestion?.prompt ?? '';
    final board = _currentQuestion?.board ?? [];
    final questionType = _currentQuestion?.questionType ?? '';
    final sourceFood = _currentQuestion?.sourceFood;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF557A46)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '冰箱清點 (${_difficulty.toUpperCase()})',
          style: const TextStyle(
            color: Color(0xFF2C3E2D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            _buildTopProgress(),
            const SizedBox(height: 12),
            _buildQuestionCard(prompt),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC5D5BC),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4E0CD),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildGameBoard(board, questionType)),
                  ],
                ),
              ),
            ),
            if (questionType == 'place_item' && sourceFood != null) ...[
              const SizedBox(height: 12),
              _buildBottomSourceTray(sourceFood),
            ],
            const SizedBox(height: 12),
            _buildRemainingAttemptsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProgress() {
    double progress = _currentQuestionIndex / _totalQuestions;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD4E0CD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '分數: $_currentScore',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38532E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_currentQuestionIndex / $_totalQuestions',
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
              backgroundColor: const Color(0xFFE2EBE0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF557A46),
              ),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(String prompt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4E0CD), width: 1.2),
      ),
      child: Text(
        prompt,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E2D),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildShelfDivider() {
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD5E2CE),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildGameBoard(List<FridgeItem> board, String questionType) {
    // 將 9 格切成 3 Rows (r1, r2, r3)
    List<FridgeItem> r1 = board
        .where((item) => item.position.startsWith('r1'))
        .toList();
    List<FridgeItem> r2 = board
        .where((item) => item.position.startsWith('r2'))
        .toList();
    List<FridgeItem> r3 = board
        .where((item) => item.position.startsWith('r3'))
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBoardRow(r1, questionType),
        _buildShelfDivider(),
        _buildBoardRow(r2, questionType),
        _buildShelfDivider(),
        _buildBoardRow(r3, questionType),
      ],
    );
  }

  Widget _buildBoardRow(List<FridgeItem> items, String questionType) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        String pos = item.position;
        String? foodCode = item.foodCode;
        String? foodName = item.foodName;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (questionType == 'relative_position' ||
                  questionType == 'locate_position') {
                // Easy / Medium 直接點擊格子作答
                _handleAnswerSubmit(foodCode: foodCode, position: pos);
              } else if (questionType == 'place_item') {
                // Hard 模式：必須先點下方待放食材，再點九宮格位置
                if (_selectedSourceFoodCode != null) {
                  _handleAnswerSubmit(
                    foodCode: _selectedSourceFoodCode,
                    position: pos,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('請先點擊下方冰箱外面的待放食材！'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSourceFoodCode != null
                      ? const Color(0xFF557A46)
                      : const Color(0xFFD4E0CD),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: foodCode != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/game/fridge_inventory/$foodCode.png',
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.fastfood,
                              size: 30,
                              color: Color(0xFF557A46),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            foodName ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF556B56),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(), // Hard 模式空格
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSourceTray(SourceFood sourceFood) {
    String code = sourceFood.foodCode;
    String name = sourceFood.foodName;
    bool isSelected = _selectedSourceFoodCode == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSourceFoodCode = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4E0CD) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF557A46),
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '待放入食材：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF556B56),
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/images/game/fridge_inventory/$code.png',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.fastfood,
                size: 32,
                color: Color(0xFF557A46),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E2D),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF557A46),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingAttemptsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '本題剩餘作答機會：',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: List.generate(3, (index) {
            bool isActive = index < _remainingAttempts;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                isActive ? Icons.favorite : Icons.favorite_border,
                color: isActive ? Colors.red.shade400 : Colors.grey.shade400,
                size: 20,
              ),
            );
          }),
        ),
      ],
    );
  }
}
