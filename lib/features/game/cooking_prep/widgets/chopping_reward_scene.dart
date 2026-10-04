import 'package:flutter/material.dart';

/// 切菜階段答對後的「砧板＋食材＋菜刀」組合場景。
///
/// 三個元素刻意放在同一個 Stack 裡、用彼此的相對位置定位（不是像之前那樣，
/// 砧板是背景層裡對整個螢幕置中、食材跟刀是前景內容區裡另外置中——兩個不同
/// 座標系統各自置中，才會兜不起來，看起來各自散落）：
/// - 砧板當底，寬度是螢幕寬度的 40~50%，整個場景置中
/// - 食材疊在砧板中央偏上，確保完整落在砧板範圍內
/// - 菜刀初始直立在砧板右側（刀尖朝上，維持原圖預設朝向、不旋轉），這個元件
///   一掛載（代表答對了）就會用 AnimationController 控制水平位移，讓刀平滑
///   地從右滑到左；同時食材用 AnimatedSwitcher 淡入淡出切成切好的樣子，兩者
///   共用同一個 controller 的進度，天然同步、不會有瞬間跳動或瞬間切換
class ChoppingRewardScene extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;
  final String boardImagePath;
  final String knifeImagePath;
  final VoidCallback onCompleted;

  const ChoppingRewardScene({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    required this.boardImagePath,
    required this.knifeImagePath,
    required this.onCompleted,
  });

  @override
  State<ChoppingRewardScene> createState() => _ChoppingRewardSceneState();
}

class _ChoppingRewardSceneState extends State<ChoppingRewardScene>
    with SingleTickerProviderStateMixin {
  // 抓中間值 600ms（規格要求 500~700ms 之間）
  static const Duration _slideDuration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  late final Animation<double> _knifeSlide;
  bool _showAfter = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _slideDuration);
    _knifeSlide = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    // 刀滑到一半時（大約掃過食材的時間點）才切換食材圖片，讓兩個動畫感覺是
    // 同步發生的「刀劃過去，食材就變了」，而不是各自獨立、時間對不齊
    _controller.addListener(() {
      if (!_showAfter && _controller.value >= 0.5) {
        setState(() => _showAfter = true);
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
    final screenWidth = MediaQuery.of(context).size.width;
    // 砧板寬度＝螢幕寬度的 40~50%，夾在 170~300 之間避免太小的裝置擠爆版面
    final boardWidth = (screenWidth * 0.45).clamp(170.0, 300.0);
    final boardHeight = boardWidth * 0.66; // 依常見砧板圖片比例估的，實際圖出來可能要再調
    final knifeWidth = boardWidth * 0.42;
    final foodSize = boardWidth * 0.38;

    // 場景本身的外框：砧板 + 右側留給刀直立起始位置的空間
    final sceneWidth = boardWidth + knifeWidth * 0.6;
    final sceneHeight = boardHeight * 1.35;

    // 刀的水平移動範圍：起點貼著砧板右側、終點滑到砧板左側
    final knifeStartX = boardWidth * 0.70;
    final knifeEndX = boardWidth * 0.02;

    return SizedBox(
      width: sceneWidth,
      height: sceneHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 砧板：貼左下角放（右邊留給刀），整個場景外層會再置中
          Positioned(
            left: 0,
            bottom: 0,
            child: Image.asset(
              widget.boardImagePath,
              width: boardWidth,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          // 食材：疊在砧板中央偏上，確保完整落在砧板範圍內
          Positioned(
            left: boardWidth * 0.31,
            bottom: boardHeight * 0.42,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Image.asset(
                _showAfter ? widget.afterImagePath : widget.beforeImagePath,
                key: ValueKey(_showAfter),
                width: foodSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  size: foodSize * 0.6,
                  color: Colors.black26,
                ),
              ),
            ),
          ),
          // 菜刀：初始直立在砧板右側（刀尖朝上，不旋轉），答對後平滑地
          // 水平滑到左側；只控制水平位移，維持同一個高度
          AnimatedBuilder(
            animation: _knifeSlide,
            builder: (context, child) {
              final dx = knifeStartX +
                  (knifeEndX - knifeStartX) * _knifeSlide.value;
              return Positioned(
                left: dx,
                bottom: boardHeight * 0.5,
                child: child!,
              );
            },
            child: Image.asset(
              widget.knifeImagePath,
              width: knifeWidth,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
