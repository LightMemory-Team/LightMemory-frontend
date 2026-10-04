import 'package:flutter/material.dart';

/// 玩法教學，全螢幕頁面（PageView 多頁）。
/// 三頁的示意畫面都是純程式碼畫的簡化圖形＋Icon＋文字，不放真實美術
/// 截圖，排版風格延續白色圓角卡片、綠色系配色。
///
/// 版面說明：套在全螢幕頁面（用 Navigator.push 而不是 showDialog）裡，
/// 頭部／頁面指示點／下一頁按鈕都是固定高度的「外層」，中間 PageView 的
/// 區域用 Expanded 吃剩下的全部空間。static 的 [show] 方法簽名跟回傳值都
/// 不變，呼叫端（cooking_prep_game_page.dart）完全不用改。
class CookingPrepTutorialDialog extends StatefulWidget {
  const CookingPrepTutorialDialog({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const CookingPrepTutorialDialog(),
      ),
    );
  }

  @override
  State<CookingPrepTutorialDialog> createState() =>
      _CookingPrepTutorialDialogState();
}

class _CookingPrepTutorialDialogState
    extends State<CookingPrepTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  static const List<String> _titles = ['基本玩法', '三個關卡', '限時挑戰'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: const [
                    _BasicRulePage(),
                    _StagesPage(),
                    _TimeLimitPage(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildPageIndicator(),
              const SizedBox(height: 16),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 32,
          child: _currentPage > 0
              ? GestureDetector(
                  onTap: _goToPreviousPage,
                  child: const Icon(Icons.arrow_back, color: Color(0xFF2D5A43)),
                )
              : null,
        ),
        Text(
          _titles[_currentPage],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5A43),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2D5A43) : const Color(0xFFDCE8DC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton() {
    final isLastPage = _currentPage == _totalPages - 1;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A43),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: _goToNextPage,
        child: Text(
          isLastPage ? '開始遊戲 →' : '下一頁 →',
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 教學頁共用的白底圓角卡片外框，包住示意圖，統一三頁的版面風格。
class _TutorialCard extends StatelessWidget {
  final Widget illustration;
  final String caption;

  const _TutorialCard({required this.illustration, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF7),
              border: Border.all(color: const Color(0xFFDCE8DC), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: illustration),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 小方塊圖示：圓角、淺綠底、深綠邊框，中間放一個 Icon，可選右上角打勾徽章。
class _IconTile extends StatelessWidget {
  static const Color _color = Color(0xFF2D5A43);

  final IconData icon;
  final double size;
  final bool showCheck;

  const _IconTile({
    required this.icon,
    this.size = 64,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              border: Border.all(color: _color, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: size * 0.5, color: _color),
          ),
          if (showCheck)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 第1頁：基本玩法——左邊「先出現的東西」，箭頭，右邊兩個並排的「選項」
/// （其中一個打勾）。
class _BasicRulePage extends StatelessWidget {
  const _BasicRulePage();

  @override
  Widget build(BuildContext context) {
    return _TutorialCard(
      illustration: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _IconTile(icon: Icons.grain),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, size: 28, color: Color(0xFF6B7E73)),
          const SizedBox(width: 12),
          const _IconTile(icon: Icons.grain, showCheck: true),
          const SizedBox(width: 8),
          const _IconTile(icon: Icons.eco),
        ],
      ),
      caption: '畫面會依序出現兩樣東西，\n接著出現兩個選項，選出「上一個」看過的',
    );
  }
}

/// 第2頁：三個關卡——切菜／調味／烹飪三個 Icon 依序排列，代表過關順序。
class _StagesPage extends StatelessWidget {
  const _StagesPage();

  @override
  Widget build(BuildContext context) {
    return const _TutorialCard(
      illustration: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StageIcon(icon: Icons.content_cut, label: '切菜'),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 22, color: Color(0xFF6B7E73)),
          SizedBox(width: 8),
          _StageIcon(icon: Icons.local_dining, label: '調味'),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 22, color: Color(0xFF6B7E73)),
          SizedBox(width: 8),
          _StageIcon(icon: Icons.soup_kitchen, label: '烹飪'),
        ],
      ),
      caption: '依序過三關：先切菜、再調味、最後烹飪，\n答對會自動進入下一關卡',
    );
  }
}

class _StageIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StageIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconTile(icon: icon, size: 56),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5A43),
          ),
        ),
      ],
    );
  }
}

/// 第3頁：限時挑戰——時鐘圖示 + 說明文字。
class _TimeLimitPage extends StatelessWidget {
  const _TimeLimitPage();

  @override
  Widget build(BuildContext context) {
    return const _TutorialCard(
      illustration: _ClockIllustration(),
      caption: '限時作答，過關會增加時間，\n時間到會自動結束並顯示結果',
    );
  }
}

class _ClockIllustration extends StatelessWidget {
  const _ClockIllustration();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2D5A43), width: 3),
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                size: 52,
                color: Color(0xFF2D5A43),
              ),
            ),
            Positioned(
              right: -12,
              top: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+15s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
