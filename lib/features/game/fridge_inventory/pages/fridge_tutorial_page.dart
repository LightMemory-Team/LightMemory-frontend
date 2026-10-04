import 'package:flutter/material.dart';
import 'fridge_game_page.dart';
import '../../widgets/game_pause.dart';
import '../../go_to_market/services/audio_service.dart';

class FridgeTutorialPage extends StatefulWidget {
  const FridgeTutorialPage({super.key});
  @override
  State<FridgeTutorialPage> createState() => _FridgeTutorialPageState();
}

class _FridgeTutorialPageState extends State<FridgeTutorialPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _showIntroOverlay = true;
  bool _showCompletionPopup = false;
  String _introTitle = '簡單難度玩法教學';
  final List<Map<String, String>> _simpleFoods = [
    {'name': '雞蛋', 'img': 'assets/images/game/fridge_inventory/egg.png'},
    {'name': '牛奶', 'img': 'assets/images/game/fridge_inventory/milk.png'},
    {'name': '豆腐', 'img': 'assets/images/game/fridge_inventory/tofu.png'},
    {'name': '番茄', 'img': 'assets/images/game/fridge_inventory/tomato.png'},
    {'name': '高麗菜', 'img': 'assets/images/game/fridge_inventory/cabbage.png'},
    {'name': '青椒', 'img': 'assets/images/game/fridge_inventory/pepper.png'},
    {'name': '胡蘿蔔', 'img': 'assets/images/game/fridge_inventory/carrot.png'},
    {'name': '蘋果', 'img': 'assets/images/game/fridge_inventory/apple.png'},
    {'name': '香蕉', 'img': 'assets/images/game/fridge_inventory/banana.png'},
  ];
  @override
  void initState() {
    super.initState();
    _triggerIntroPopup('簡單難度玩法教學');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _triggerIntroPopup(String title) {
    setState(() {
      _introTitle = title;
      _showIntroOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showIntroOverlay = false);
      }
    });
  }

  void _showGamePauseDialog() {
    AudioService.playClick();
    GamePause.show(
      context,
      onResume: () {
        AudioService.playClick();
      },
      onTutorial: () {
        AudioService.playClick();
        _pageController.jumpToPage(0);
      },
      onRestart: () {
        AudioService.playClick();
        _pageController.jumpToPage(0);
      },
      onExit: () {
        AudioService.playClick();
        Navigator.of(context).pop();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  void _nextPage() {
    AudioService.playClick();
    if (_currentPageIndex < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _showCompletionPopup = true);
    }
  }

  void _prevPage() {
    AudioService.playClick();
    if (_showCompletionPopup) {
      setState(() => _showCompletionPopup = false);
      return;
    }
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showGamePauseDialog();
    }
  }

  void _startGame() {
    AudioService.playClick();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FridgeGamePage()),
    );
  }

  void _restartTutorial() {
    AudioService.playClick();
    setState(() => _showCompletionPopup = false);
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final String diffTitle = _currentPageIndex < 2
        ? '簡單難度教學'
        : (_currentPageIndex < 4 ? '中等難度教學' : '困難難度教學');
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF355E3B)),
          onPressed: _showGamePauseDialog,
        ),
        title: const Text(
          '冰箱清點',
          style: TextStyle(
            color: Color(0xFF29442F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _startGame,
            child: const Text(
              '略過教學',
              style: TextStyle(
                color: Color(0xFF355E3B),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _buildTopProgress(diffTitle),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 6,
                    onPageChanged: (index) {
                      setState(() => _currentPageIndex = index);
                      if (index == 2) {
                        _triggerIntroPopup('中等難度玩法教學');
                      } else if (index == 4) {
                        _triggerIntroPopup('困難難度玩法教學');
                      }
                    },
                    itemBuilder: (context, index) {
                      final bool showHighlight = index.isOdd;
                      if (index < 2) {
                        return _buildTutorialLayout(
                          '請找出牛奶右邊的是什麼？',
                          _buildSimpleFridge(showHighlight),
                        );
                      }
                      if (index < 4) {
                        return _buildTutorialLayout(
                          '請找出第二排中間的雞蛋',
                          _buildMediumFridge(showHighlight),
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: _buildTutorialLayout(
                              '把胡蘿蔔移到第二排中間',
                              _buildHardFridge(showHighlight),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildBottomItemTray(),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomButtons(),
              ],
            ),
          ),
          if (_showIntroOverlay) _buildIntroPopup(),
          if (_showCompletionPopup) _buildCompletionPopupBox(),
        ],
      ),
    );
  }

  Widget _buildTopProgress(String title) {
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
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF355E3B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_currentPageIndex + 1} / 6',
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
              value: (_currentPageIndex + 1) / 6,
              backgroundColor: const Color(0xFFE0E4E1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF355E3B)),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialLayout(String question, Widget fridgeContent) {
    return Column(
      children: [
        Container(
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
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF29442F),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFD7DCD9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7E9784), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildTutorialFridgeFrame(fridgeContent),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialFridgeFrame(Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECE6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7E9784), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          children: [
            _buildTutorialFridgeHeader(),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(5), child: content),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialFridgeHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF3EF), Color(0xFFD5DFD7)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF9DB2A1))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 17,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8DD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4CFA9), width: 0.8),
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

  Widget _buildShelfDivider() {
    return Container(
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAFC0B4), Color(0xFFDDE6DF), Color(0xFF91A697)],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF7D9484)),
          bottom: BorderSide(color: Colors.white, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFridge(bool showHighlight) {
    return _buildThreeRowFridge(
      _buildRowItems(
        [0, 1, 2],
        showHighlight,
        2,
        (i) => _simpleFoods[i]['name']!,
        (i) => _simpleFoods[i]['img']!,
      ),
      _buildRowItems(
        [3, 4, 5],
        false,
        -1,
        (i) => _simpleFoods[i]['name']!,
        (i) => _simpleFoods[i]['img']!,
      ),
      _buildRowItems(
        [6, 7, 8],
        false,
        -1,
        (i) => _simpleFoods[i]['name']!,
        (i) => _simpleFoods[i]['img']!,
      ),
    );
  }

  Widget _buildMediumFridge(bool showHighlight) {
    const eggImage = 'assets/images/game/fridge_inventory/egg.png';
    return _buildThreeRowFridge(
      _buildRowItems([0, 1, 2], false, -1, (_) => '雞蛋', (_) => eggImage),
      _buildRowItems([3, 4, 5], showHighlight, 4, (_) => '雞蛋', (_) => eggImage),
      _buildRowItems([6, 7, 8], false, -1, (_) => '雞蛋', (_) => eggImage),
    );
  }

  Widget _buildThreeRowFridge(
    Widget firstRow,
    Widget secondRow,
    Widget thirdRow,
  ) {
    return Column(
      children: [
        Expanded(child: firstRow),
        _buildShelfDivider(),
        Expanded(child: secondRow),
        _buildShelfDivider(),
        Expanded(child: _buildCrisperArea(child: thirdRow)),
      ],
    );
  }

  Widget _buildHardFridge(bool showHighlight) {
    return Column(
      children: [
        Expanded(child: _buildEmptyRow([0, 1, 2], -1, showHighlight)),
        _buildShelfDivider(),
        Expanded(child: _buildEmptyRow([3, 4, 5], 4, showHighlight)),
        _buildShelfDivider(),
        Expanded(
          child: _buildCrisperArea(
            child: _buildEmptyRow([6, 7, 8], -1, showHighlight),
          ),
        ),
      ],
    );
  }

  Widget _buildCrisperArea({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 3, 5, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDE8DF), Color(0xFFC8D8CB)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF91A697)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
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

  Widget _buildRowItems(
    List<int> indices,
    bool showHighlight,
    int targetIndex,
    String Function(int) getName,
    String Function(int) getImg,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: indices.map((index) {
        return Expanded(
          child: TutorialFoodItem(
            name: getName(index),
            imgPath: getImg(index),
            isHighlighted: showHighlight && index == targetIndex,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRow(
    List<int> indices,
    int targetIndex,
    bool showHighlight,
  ) {
    return Row(
      children: indices.map((index) {
        final bool showFood = showHighlight && index == targetIndex;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 65,
            decoration: BoxDecoration(
              color: showFood ? Colors.white : const Color(0xFFE8EFEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: showFood
                    ? const Color(0xFF355E3B)
                    : const Color(0xFFB8C9BC),
                width: showFood ? 2 : 1,
              ),
            ),
            child: showFood
                ? Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/images/game/fridge_inventory/carrot.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        bottom: -16,
                        right: -16,
                        child: Image.asset(
                          'assets/images/game/fridge_inventory/finger.png',
                          height: 42,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) {
                            return const Icon(
                              Icons.touch_app,
                              size: 36,
                              color: Color(0xFF355E3B),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomItemTray() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEDF3EE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9C9BC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '待放入食材：',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF355E3B),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFB9C9BC)),
            ),
            child: Image.asset(
              'assets/images/game/fridge_inventory/carrot.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '胡蘿蔔',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF29442F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF355E3B), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _prevPage,
              child: const Text(
                '上一步',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF355E3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355E3B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _nextPage,
              child: const Text(
                '下一步',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroPopup() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF355E3B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 48,
                  color: Color(0xFF355E3B),
                ),
                const SizedBox(height: 12),
                Text(
                  _introTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29442F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionPopupBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF355E3B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: Color(0xFF355E3B),
                ),
                const SizedBox(height: 12),
                const Text(
                  '所有難度教學已完成',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29442F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355E3B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _startGame,
                    child: const Text(
                      '開始遊戲',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF355E3B),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _restartTutorial,
                    child: const Text(
                      '再看一次教學',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF355E3B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TutorialFoodItem extends StatelessWidget {
  final String name;
  final String imgPath;
  final bool isHighlighted;
  const TutorialFoodItem({
    super.key,
    required this.name,
    required this.imgPath,
    required this.isHighlighted,
  });
  @override
  Widget build(BuildContext context) {
    final Widget foodImage = Image.asset(
      imgPath,
      height: isHighlighted ? 50 : 54,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) {
        return const Icon(Icons.fastfood, size: 40, color: Color(0xFF355E3B));
      },
    );
    if (isHighlighted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF355E3B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  foodImage,
                  Positioned(
                    bottom: -16,
                    right: -16,
                    child: Image.asset(
                      'assets/images/game/fridge_inventory/finger.png',
                      height: 42,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        return const Icon(
                          Icons.touch_app,
                          size: 32,
                          color: Color(0xFF355E3B),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF355E3B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          foodImage,
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF355E3B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
