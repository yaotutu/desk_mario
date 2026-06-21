import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 地面层（Layer 2：地面砖块）
///
/// 方案：sprite-resource SMB1 NES Overworld "World 1-1" sheet 真实素材。
///
/// 实现要点：
/// - 真实 ground tile = 16×32 NES 像素（已从 World 1-1 sheet y=208..240 切出），
///   上半部分：棕色砖块（顶面）+ 黑色边框；下半部分：棕色砖块 + 黑色铆钉（侧面）。
/// - **窗口自适应**：以屏高 × groundRatio 作为地面高度，等比计算 tile 渲染宽度
///   （tile 宽度 = 地面高度 × tileAspect，其中 tileAspect = 16/32 = 0.5），
///   tile 渲染尺寸始终保持 16:32 原图比例，避免铆钉位置变形。
/// - **地面贴底**：定位在屏幕底部，向上延伸 [groundRatio] × 屏高。
/// - **水平方向**：单个 tile 横向 repeat 铺满，不滚动。
/// - 没有 CustomPaint，100% sprite-resource 真实素材。
class GroundLayer extends ConsumerStatefulWidget {
  const GroundLayer({super.key});

  /// 地面占屏高比例。
  static const double groundRatio = 0.18;

  /// 单 tile 原图比例 16:32（宽:高）。
  static const double tileAspect = 16 / 32;

  @override
  ConsumerState<GroundLayer> createState() => _GroundLayerState();
}

class _GroundLayerState extends ConsumerState<GroundLayer> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final groundHeight = screenHeight * GroundLayer.groundRatio;
        // tile 渲染高度 = groundHeight，宽度按 16:16 算出
        final tileWidth = groundHeight * GroundLayer.tileAspect;

        return SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: screenHeight - groundHeight,
                width: screenWidth,
                height: groundHeight,
                child: Image.asset(
                  'assets/sprites/ground_tile.png',
                  width: tileWidth,
                  height: groundHeight,
                  fit: BoxFit.fill,
                  repeat: ImageRepeat.repeatX,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}