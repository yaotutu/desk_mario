import 'package:flutter/material.dart';

import '../../../shared/widgets/scrolling_world.dart';

/// 地面层（Layer 2：地面砖块）
///
/// 方案：sprite-resource SMB1 NES Overworld "World 1-1" sheet 真实素材。
///
/// 实现要点：
/// - 真实 ground tile = 32×32（已从 World 1-1 sheet y=208..240 / x=0..32 切出），
///   上半棕色砖块 + 黑色边框，下半棕色砖块 + 黑色铆钉。
/// - **窗口自适应 + 与 background 绑死**：所有基础尺寸由 [ScrollingWorld] 统一算，
///   本层只从 [ScrollingMetrics] 读 tileWidth / groundHeight / progress。
///   tileWidth = panelWidth / [tilesPerPanel] = panelWidth / 32（整数比，对齐 panel 边界）。
/// - **永远铺满**：tileCount 固定 [totalTiles] = [tilesPerPanel] + [extraTiles] = 34，
///   渲染总宽度 = 34 × tileWidth = 1.0625 × panelWidth，多出的 0.0625 × panelWidth
///   供平移时备用，ClipRect 裁掉屏幕外部分 → 任何 shift 值都不露 sky。
/// - **横向滚动（视差）**：shift = -progress × tileWidth × [scrollTilesPerPeriod]，
///   一个 controller 周期内 ground 走 5 个 tile 周期 = 12s/tile
///   （视差比例 = panelWidth / (5 × tileWidth) = 32/5 = 6.4 倍，远景慢 = 经典视差）。
/// - 没有 CustomPaint，100% sprite-resource 真实素材。
///
/// 为什么用 Stack + Positioned 而非 Row：Row 子项总宽 = 34 × tileWidth 远超 totalWidth，
/// 在 1280×720 设计尺寸下 overflow ~1658px 触发 RenderFlex overflow assertion。
/// Stack + Positioned 子项可以超出 Stack 边界（被外层 ClipRect 裁掉），不报错。
class GroundLayer extends StatelessWidget {
  const GroundLayer({super.key});

  /// 地面占屏高比例（约一个 NES tile 行的高度）。
  static const double groundRatio = 0.12;

  /// 单 tile 原图比例 32:32（宽:高）。
  static const double tileAspect = 32 / 32;

  /// 一个 panel 宽度 = [tilesPerPanel] 个 tile 宽度（绑死比例）。
  /// 计算来源：((1 - 0.12) × 4.364) / 0.12 = 3.84 / 0.12 = 32（精确整数）。
  /// ⚠️ 改 [groundRatio] 或 [ParallaxBackground.imageAspect] 必须同步改这个值。
  static const int tilesPerPanel = 32;

  /// 一个 controller 周期内 ground 走多少个 tile 周期。
  /// 5 × tileWidth / 60s = 12s/tile（保留原节奏）；视差 = 32/5 = 6.4 倍远景慢。
  static const int scrollTilesPerPeriod = 5;

  /// 多铺 [extraTiles] 列 tile 备用（避免末格留白 + 平移时右边露出）。
  static const int extraTiles = 2;

  /// tile 总数 = [tilesPerPanel] + [extraTiles]（铺满一个 panel 宽度 + 备用）。
  static const int totalTiles = tilesPerPanel + extraTiles;

  @override
  Widget build(BuildContext context) {
    final m = ScrollingMetrics.of(context);

    // 视差 shift：一个 controller 周期走完 [scrollTilesPerPeriod] 个 tile 周期
    final shift = -m.progress * m.tileWidth * scrollTilesPerPeriod;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 0,
            top: m.totalHeight - m.groundHeight,
            width: m.totalWidth,
            height: m.groundHeight,
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(shift, 0),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (int i = 0; i < totalTiles; i++)
                      Positioned(
                        left: i * m.tileWidth,
                        top: 0,
                        width: m.tileWidth,
                        height: m.groundHeight,
                        child: Image.asset(
                          'assets/sprites/ground_tile.png',
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}