import 'package:flutter/material.dart';

/// 調味階段答對後的回饋畫面：直接淡入顯示對應的完整湯圖片（本身就含
/// 容器），不疊鍋子圖、不疊顏色濾鏡，畫面上只有這一張圖。
class SeasoningSoupRewardScene extends StatefulWidget {
  final String soupImagePath;
  final VoidCallback onCompleted;
  final double size;

  const SeasoningSoupRewardScene({
    super.key,
    required this.soupImagePath,
    required this.onCompleted,
    this.size = 200,
  });

  @override
  State<SeasoningSoupRewardScene> createState() =>
      _SeasoningSoupRewardSceneState();
}

class _SeasoningSoupRewardSceneState extends State<SeasoningSoupRewardScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showSoup = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.addListener(() {
      if (!_showSoup && _controller.value >= 0.1) {
        setState(() => _showSoup = true);
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showSoup
            ? Image.asset(
                widget.soupImagePath,
                key: ValueKey(widget.soupImagePath),
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.soup_kitchen_outlined,
                  size: widget.size * 0.5,
                  color: Colors.black26,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}
