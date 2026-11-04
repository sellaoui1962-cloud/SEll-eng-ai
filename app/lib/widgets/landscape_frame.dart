import 'package:flutter/material.dart';

/// 横屏友好的内容框（阶段 3-横屏）。
///
/// 竖屏时原样显示；横屏时把内容限制在 [maxWidth] 宽并居中，
/// 避免文字和卡片横向拉得过长、难以阅读。
class LandscapeFrame extends StatelessWidget {
  const LandscapeFrame({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.orientation != Orientation.landscape) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
