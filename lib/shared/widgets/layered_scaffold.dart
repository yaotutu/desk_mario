import 'package:flutter/material.dart';

import '../../features/character/widgets/mario_widget.dart';
import '../widgets/scrolling_world.dart';

/// 主页装配点
///
/// 当前层级（Step 2+）：
/// - ScrollingWorld（Layer 1 + Layer 2 合并）：视差背景 + 地面砖块，
///   共享滚动 controller + 共享基础尺寸（panelWidth / tileWidth / groundHeight），
///   缩放和滚动天然协调。
/// - PositionedMario（Layer 3）：Mario 主角，独立原地跑步 + 上下浮动，不参与横向滚动。
/// 后续 Step 3-5 会叠加 HUD / 通知 / Debug。
class LayeredScaffold extends StatelessWidget {
  const LayeredScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          ScrollingWorld(),
          PositionedMario(),
        ],
      ),
    );
  }
}
