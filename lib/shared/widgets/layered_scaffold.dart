import 'package:flutter/material.dart';

import '../../features/parallax/widgets/ground_layer.dart';
import '../../features/parallax/widgets/parallax_background.dart';

/// 主页装配点
///
/// 当前层级：
/// - Layer 1：[ParallaxBackground] 视差远景（云 + 远山 + 草坡，120s 一周期）
/// - Layer 2：[GroundLayer] 地面砖块（贴底，单 tile 横向 repeat）
/// 后续 Step 2-5 会在此基础上叠加 Mario / HUD / 通知 / Debug。
class LayeredScaffold extends StatelessWidget {
  const LayeredScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          // Layer 1：远景视差（最底）
          ParallaxBackground(),
          // Layer 2：地面砖块（贴在远景之上、底部对齐）
          Positioned.fill(child: GroundLayer()),
        ],
      ),
    );
  }
}