import 'package:flutter/material.dart';

class MarketShoppingTutorialDialog extends StatefulWidget {
  const MarketShoppingTutorialDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MarketShoppingTutorialDialog(),
    );
  }

  @override
  State<MarketShoppingTutorialDialog> createState() => _MarketShoppingTutorialDialogState();
}

class _MarketShoppingTutorialDialogState extends State<MarketShoppingTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  static const List<String> _titles = [ '第一步', '第二步', '第三步'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            SizedBox(
              height: 420,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: const [
                  _TutorialStepPage(
                    imagePath: 'assets/images/game/market_shopping/tutorial_memorize.png',
                    caption: '系統會先出示購物清單，記住上面有哪些食材',
                  ),
                  _TutorialStepPage(
                    imagePath: 'assets/images/game/market_shopping/tutorial_select.png',
                    caption: '接著從選項中，點選清單上出現過的食材',
                  ),
                  _TutorialStepPage(
                    imagePath: 'assets/images/game/market_shopping/tutorial_checkout.png',
                    caption: '最後算出正確的找零金額，就完成一題！',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPageIndicator(),
            const SizedBox(height: 16),
            _buildBottomButton(),
          ],
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
                  child: const Icon(Icons.arrow_back, color: Color(0xFF3D6B4A)),
                )
              : null,
        ),
        Text(
          _titles[_currentPage],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D6B4A)),
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
            color: isActive ? const Color(0xFF5B8A6B) : const Color(0xFFDCE8DC),
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
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B8A6B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: _goToNextPage,
        child: Text(
          isLastPage ? '開始遊戲 →' : '下一頁 →',
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


class _TutorialStepPage extends StatelessWidget {
  final String imagePath;
  final String caption;

  const _TutorialStepPage({required this.imagePath, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE8DC), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.black26),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}