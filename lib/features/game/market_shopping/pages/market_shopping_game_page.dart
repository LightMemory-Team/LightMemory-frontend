import 'package:flutter/material.dart';
import '../models/market_shopping_models.dart';
import '../services/market_shopping_service.dart';
import '../services/tutorial_preference.dart';
import '../widgets/market_shopping_tutorial_dialog.dart';
import 'market_shopping_memorize_page.dart';
import 'market_shopping_play_page.dart';
import 'market_shopping_checkout_page.dart';
import 'market_shopping_result_page.dart';

enum _GameStage { loading, memorize, play, checkout, error }

class MarketShoppingGamePage extends StatefulWidget {
  const MarketShoppingGamePage({super.key});

  @override
  State<MarketShoppingGamePage> createState() => _MarketShoppingGamePageState();
}

class _MarketShoppingGamePageState extends State<MarketShoppingGamePage> {
  int? _sessionId;
  ShoppingQuestion? _currentQuestion;
  ItemAnswerResult? _itemAnswerResult;

  _GameStage _stage = _GameStage.loading;
  String _errorMessage = '';
  int? _finalAccuracy;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
  setState(() => _stage = _GameStage.loading);
  try {
    final session = await MarketShoppingService.startGame();
    _sessionId = session.sessionId;
    _currentQuestion = session.firstQuestion;

    if (mounted) {
      await MarketShoppingTutorialDialog.show(context);  // 每次開局都顯示，不再檢查是否第一次玩
    }

    if (mounted) {
      setState(() => _stage = _GameStage.memorize);  // 教學關閉後才切換畫面、開始倒數
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _stage = _GameStage.error;
    });
  }
}

  /// 重新開始：整場遊戲重來一次
  void _restart() {
    _startGame();
  }

  void _onMemorizeTimeUp() {
    setState(() => _stage = _GameStage.play);
  }

  Future<ItemAnswerResult> _submitItemAnswer(List<MarketFood> selectedFoods) async {
    final result = await MarketShoppingService.submitItemAnswer(
      sessionId: _sessionId!,
      selectedFoodCodes: selectedFoods.map((f) => f.foodCode).toList(),
    );
    _itemAnswerResult = result;

    if (result.isCompleted) {
      // 選菜階段就把整場遊戲結束了（第10題錯滿3次），這裡沒有 accuracy 資訊
      // 但既然遊戲結束了，先導向結果頁（accuracy 用 0 或既有值頂著）
      // 實務上這種情況應極少發生（因為錯滿3次通常是找零階段才會是最後一步）
    } else if (result.nextQuestion != null) {
      setState(() {
        _currentQuestion = result.nextQuestion;
        _stage = _GameStage.memorize;
      });
    }

    return result;
  }

  void _goToCheckout() {
    setState(() => _stage = _GameStage.checkout);
  }

  Future<ChangeAnswerResult> _submitChangeAnswer(int selectedAmount) async {
    final result = await MarketShoppingService.submitChangeAnswer(
      sessionId: _sessionId!,
      selectedAmount: selectedAmount,
    );

    if (result.isCompleted) {
      _finalAccuracy = result.accuracy;
    }
    // 不再在這裡自動切換 stage，交給 CheckoutPage 自己在看完勾勾/叉叉後才呼叫

    return result;
  }

  void _proceedToNextQuestion(ShoppingQuestion nextQuestion) {
    setState(() {
      _currentQuestion = nextQuestion;
      _stage = _GameStage.memorize;
    });
  }

  void _goToResultPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MarketShoppingResultPage(accuracy: _finalAccuracy ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _GameStage.loading:
        return const Scaffold(
          backgroundColor: Color(0xFFF6F8F3),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF5B8A6B))),
        );

      case _GameStage.error:
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F3),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
                  const SizedBox(height: 16),
                  Text(_errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _startGame, child: const Text('重試')),
                ],
              ),
            ),
          ),
        );

      case _GameStage.memorize:
        return MarketShoppingMemorizePage(
          question: _currentQuestion!,
          onTimeUp: _onMemorizeTimeUp,
          onRestart: _restart,
        );

      case _GameStage.play:
        return MarketShoppingPlayPage(
          question: _currentQuestion!,
          onSubmitAnswer: _submitItemAnswer,
          onProceedToCheckout: _goToCheckout,
          onRestart: _restart,
        );

      case _GameStage.checkout:
        return MarketShoppingCheckoutPage(
          question: _currentQuestion!,
          itemAnswerResult: _itemAnswerResult!,
          onSubmitAnswer: _submitChangeAnswer,
          onProceedToNextQuestion: _proceedToNextQuestion,
          onGameCompleted: _goToResultPage,
          onRestart: _restart,
        );
    }
  }
}