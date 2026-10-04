import 'package:flutter/material.dart';

/// 頁面背景：上半灰、下半綠（比例約 1:4），三個階段（切菜／調味／烹飪）
/// 都共用這個基礎分層樣式，不會因為階段不同而整片變色。
/// 三個階段各自的場景（砧板＋刀、鍋子＋調味料罐、鍋子＋裝飾食材堆）都是
/// 前景內容自己畫的組合場景，不需要背景層再另外疊一份裝飾，避免前景
/// 展示畫面本身的鍋子跟背景常駐的鍋子重疊、視覺很亂（advanced 階段
/// 之前在這裡固定顯示過一個半透明鍋子，已經拿掉）。
class CookingPrepBackground extends StatelessWidget {
  /// 後端的 current_stage 字串（'basic'／'intermediate'／'advanced'），
  /// 目前背景本身不依階段變化，保留這個參數是給未來萬一真的需要依階段
  /// 微調背景時用，不是沒用到的參數。
  final String stage;
  final Widget child;

  const CookingPrepBackground({
    super.key,
    required this.stage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Column(
          children: [
            Expanded(flex: 1, child: ColoredBox(color: Color(0xFFE8E8E1))),
            Expanded(flex: 4, child: ColoredBox(color: Color(0xFF7BAF8E))),
          ],
        ),
        child,
      ],
    );
  }
}
