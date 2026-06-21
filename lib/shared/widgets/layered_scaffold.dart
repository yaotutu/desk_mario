import 'package:flutter/material.dart';

import '../../features/parallax/widgets/parallax_background.dart';

/// 主页装配点（Step 1 简化版）
///
/// Step 1 阶段：只显示 [ParallaxBackground] 视差滚动背景。
/// 后续 Step 2-5 会在此基础上叠加 Mario / HUD / 通知 / Debug。
class LayeredScaffold extends StatelessWidget {
  const LayeredScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ParallaxBackground(),
    );
  }
}