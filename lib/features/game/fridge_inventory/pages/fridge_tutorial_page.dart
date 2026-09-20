import 'package:flutter/material.dart';
import 'fridge_game_page.dart'; // 如果遊戲頁面與教學頁面在同一個 pages 資料夾，這樣寫即可！

class FridgeTutorialPage extends StatefulWidget {
  const FridgeTutorialPage({super.key});

  @override
  State<FridgeTutorialPage> createState() => _FridgeTutorialPageState();
}

class _FridgeTutorialPageState extends State<FridgeTutorialPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _showIntroOverlay = true;
  String _introTitle = '簡單難度玩法教學';

  final List<Map<String, String>> _simpleFoods = [
    {'name': '雞蛋', 'img': 'assets/images/game/fridge_inventory/egg.png'},
    {'name': '牛奶', 'img': 'assets/images/game/fridge_inventory/milk.png'},
    {'name': '豆腐', 'img': 'assets/images/game/fridge_inventory/tofu.png'},
    {'name': '番茄', 'img': 'assets/images/game/fridge_inventory/tomato.png'},
    {'name': '高麗菜', 'img': 'assets/images/game/fridge_inventory/cabbage.png'},
    {
      'name': '青椒',
      'img': 'assets/images/game/fridge_inventory/red bell pepper.png',
    },
    {'name': '胡蘿蔔', 'img': 'assets/images/game/fridge_inventory/carrot.png'},
    {'name': '蘋果', 'img': 'assets/images/game/fridge_inventory/apple.png'},
    {'name': '香蕉', 'img': 'assets/images/game/fridge_inventory/banana.png'},
  ];

  @override
  void initState() {
    super.initState();
    _triggerIntroPopup('簡單難度玩法教學');
  }

  void _triggerIntroPopup(String title) {
    setState(() {
      _introTitle = title;
      _showIntroOverlay = true;
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showIntroOverlay = false);
    });
  }

  void _nextPage() {
    if (_currentPageIndex < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 已經到最後一頁，點擊「開始遊戲」直接跳轉到正式遊戲畫面
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FridgeGamePage()),
      );
    }
  }

  void _prevPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String diffTitle = _currentPageIndex < 2
        ? '簡單難度教學'
        : (_currentPageIndex < 4 ? '中等難度教學' : '困難難度教學');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF557A46)),
          onPressed: _prevPage,
        ),
        title: const Text(
          '冰箱清點',
          style: TextStyle(
            color: Color(0xFF2C3E2D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              children: [
                _buildTopProgress(diffTitle),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 6,
                    onPageChanged: (i) {
                      setState(() => _currentPageIndex = i);
                      if (i == 2) _triggerIntroPopup('中等難度玩法教學');
                      if (i == 4) _triggerIntroPopup('困難難度玩法教學');
                    },
                    itemBuilder: (context, index) {
                      bool showHighlight = (index % 2 == 1);

                      if (index < 2) {
                        return _buildTutorialLayout(
                          '請找出牛奶右邊的是什麼？',
                          _buildSimpleGrid(showHighlight),
                        );
                      } else if (index < 4) {
                        return _buildTutorialLayout(
                          '請找出第二排中間的雞蛋',
                          _buildMediumGrid(showHighlight),
                        );
                      } else {
                        return Column(
                          children: [
                            Expanded(
                              child: _buildTutorialLayout(
                                '把胡蘿蔔移到第二排中間',
                                _buildHardGrid(showHighlight),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildBottomItemTray(),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomButtons(),
              ],
            ),
          ),
          if (_showIntroOverlay) _buildIntroPopup(),
        ],
      ),
    );
  }

  Widget _buildTopProgress(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD4E0CD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38532E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '1 / 10',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.1,
              backgroundColor: Color(0xFFE2EBE0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF557A46)),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4E0CD), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E2D),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC5D5BC), width: 1.5),
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
                const SizedBox(height: 6),
                Expanded(child: fridgeContent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfDivider() {
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD5E2CE),
        borderRadius: BorderRadius.circular(2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleGrid(bool showHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRowItems(
          [0, 1, 2],
          showHighlight,
          2,
          (i) => _simpleFoods[i]['name']!,
          (i) => _simpleFoods[i]['img']!,
        ),
        _buildShelfDivider(),
        _buildRowItems(
          [3, 4, 5],
          false,
          -1,
          (i) => _simpleFoods[i]['name']!,
          (i) => _simpleFoods[i]['img']!,
        ),
        _buildShelfDivider(),
        _buildRowItems(
          [6, 7, 8],
          false,
          -1,
          (i) => _simpleFoods[i]['name']!,
          (i) => _simpleFoods[i]['img']!,
        ),
      ],
    );
  }

  Widget _buildMediumGrid(bool showHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRowItems(
          [0, 1, 2],
          false,
          -1,
          (_) => '雞蛋',
          (_) => 'assets/images/game/fridge_inventory/egg.png',
        ),
        _buildShelfDivider(),
        _buildRowItems(
          [3, 4, 5],
          showHighlight,
          4,
          (_) => '雞蛋',
          (_) => 'assets/images/game/fridge_inventory/egg.png',
        ),
        _buildShelfDivider(),
        _buildRowItems(
          [6, 7, 8],
          false,
          -1,
          (_) => '雞蛋',
          (_) => 'assets/images/game/fridge_inventory/egg.png',
        ),
      ],
    );
  }

  Widget _buildHardGrid(bool showHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildEmptyRow([0, 1, 2], -1, showHighlight),
        _buildShelfDivider(),
        _buildEmptyRow([3, 4, 5], 4, showHighlight),
        _buildShelfDivider(),
        _buildEmptyRow([6, 7, 8], -1, showHighlight),
      ],
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
      children: indices.map((idx) {
        bool isTarget = (idx == targetIndex);
        return Expanded(
          child: TutorialFoodItem(
            name: getName(idx),
            imgPath: getImg(idx),
            isHighlighted: showHighlight && isTarget,
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: indices.map((idx) {
        bool isTarget = (idx == targetIndex);
        bool showFood = (showHighlight && isTarget);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 65,
            decoration: BoxDecoration(
              color: showFood ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: showFood ? const Color(0xFF557A46) : Colors.transparent,
                width: showFood ? 2.0 : 0.0,
              ),
            ),
            child: Center(
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
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.touch_app,
                              size: 36,
                              color: Color(0xFF38532E),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomItemTray() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC5D5BC), width: 1.5),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/game/fridge_inventory/carrot.png',
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Text(
                '胡蘿蔔',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E2D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    bool isLastPage = _currentPageIndex == 5;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF557A46), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _prevPage,
              child: const Text(
                '上一步',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF557A46),
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
                backgroundColor: const Color(0xFF557A46),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _nextPage,
              child: Text(
                isLastPage ? '開始遊戲' : '下一步',
                style: const TextStyle(
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
              border: Border.all(color: const Color(0xFF557A46), width: 2),
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
                  color: Color(0xFF557A46),
                ),
                const SizedBox(height: 12),
                Text(
                  _introTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E2D),
                    decoration: TextDecoration.none,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.shade700,
                      width: 2.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        imgPath,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Color(0xFF557A46),
                        ),
                      ),
                      Positioned(
                        bottom: -16,
                        right: -16,
                        child: Image.asset(
                          'assets/images/game/fridge_inventory/finger.png',
                          height: 42,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.touch_app,
                            size: 32,
                            color: Color(0xFF38532E),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      imgPath,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Color(0xFF557A46),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF556B56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
