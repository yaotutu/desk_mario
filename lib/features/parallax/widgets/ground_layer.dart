import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 地面层（Layer 2：地面砖块）
///
/// 方案：sprite-resource SMB1 NES Overworld "World 1-1" sheet 真实素材。
///
/// 实现要点：
/// - 真实 ground tile = 32×32 像素（对应 NES 原生 16×16 tile，已从
///   World 1-1 sheet y=208..240 / x=0..32 切出），
///   上半：棕色砖块（顶面）+ 黑色边框；下半：棕色砖块 + 黑色铆钉（侧面）。
/// - **窗口自适应**：以屏高 × groundRatio 作为地面高度，等比计算 tile 渲染宽度
///   （tile 宽 = 地面高 × tileAspect = 地面高 × 1.0），保持 32:32 原图比例。
/// - **地面贴底**：定位在屏幕底部，向上延伸 [groundRatio] × 屏高。
/// - **水平方向**：用 [Stack] + 多个 [Positioned] 手动铺 tile（避开 Image.repeat
///   在自定义 width/height 下被填满 box 而不真正 repeat 的坑，以及 Row overflow
///   警告）。多出的最后半格 tile 由 ClipRect 裁掉，视觉上看不出来。
/// - 没有 CustomPaint，100% sprite-resource 真实素材。
class GroundLayer extends ConsumerStatefulWidget {
  const GroundLayer({super.key});

  /// 地面占屏高比例（约一个 NES tile 行的高度）。
  static const double groundRatio = 0.12;

  /// 单 tile 原图比例 32:32（宽:高）。
  static const double tileAspect = 32 / 32;

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
        final tileWidth = groundHeight * GroundLayer.tileAspect;
        // tile 数 +1 多铺一格，让 ClipRect 裁掉超出部分，避免末格留白。
        final tileCount = (screenWidth / tileWidth).floor() + 1;

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
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      for (int i = 0; i < tileCount; i++)
                        Positioned(
                          left: i * tileWidth,
                          top: 0,
                          width: tileWidth,
                          height: groundHeight,
                          child: Image.asset(
                            'assets/sprites/ground_tile.png',
                            width: tileWidth,
                            height: groundHeight,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            gaplessPlayback: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}