import 'package:flutter/material.dart';

import '../../../shared/widgets/scrolling_world.dart';

/// 地面层（Layer 2：地面砖块）
///
/// 方案：sprite-resource SMB1 NES Overworld "World 1-1" sheet 真实素材。
///
/// 实现要点：
/// - 真实 ground tile = 32×32（已从 World 1-1 sheet y=208..240 / x=0..32 切出），
///   上半棕色砖块 + 黑色边框，下半棕色砖块 + 黑色铆钉。
/// - **作为整体滚动世界的成员**：本层只负责画 tile 内容，**不**自己算 shift/Transform。
///   统一的 Transform.translate 由 [ScrollingWorld] 顶层包住，
///   整个世界（panel + ground）永远同步平移，杜绝两层独立 shift 算错导致错位。
/// - 尺寸绑死：tileWidth = panelWidth / [tilesPerPanel] = panelWidth / 32（整数比），
///   与 panel 1 横向完美对齐。
/// - **永远铺满 + 多铺 1 列备用**：tileCount = [tilesPerPanel] + 1 = 33，
///   渲染总宽度 = 33 × tileWidth = panelWidth × 33/32 = 1.03125 × panelWidth，
///   多出的 0.03125 × panelWidth 供平移时备用，外层 ClipRect 裁掉屏幕外部分。
///   一个 controller 周期（shift 走 panelWidth）正好让 ground 走完 [tilesPerPanel] = 32
///   个 tile 循环（一个完整 tile 循环），与 panel 1 的 1 个完整切换严格同步。
/// - 没有 CustomPaint，100% sprite-resource 真实素材。
///
/// 为什么用 Stack + Positioned 而非 Row：Row 子项总宽 = 33 × tileWidth 远超 totalWidth，
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

  /// 多铺 [extraTiles] 列 tile 备用（避免平移时右边露出 sky）。
  static const int extraTiles = 1;

  /// tile 总数 = [tilesPerPanel] + [extraTiles]（铺满一个 panel 宽度 + 备用）。
  static const int totalTiles = tilesPerPanel + extraTiles;

  @override
  Widget build(BuildContext context) {
    final m = ScrollingMetrics.of(context);

    // tile 区域定位：贴屏幕底部，宽度 = totalTiles × tileWidth（横铺到 panelWidth 外多 1 列备用）。
    // 高度 = groundHeight。整体平移由 [ScrollingWorld] 顶层统一 Transform.translate 管。
    //
    // 关键：用 [OverflowBox] 给内部一个无界 maxWidth 约束，
    // 避免被父 [Stack] 的 tight constraint 强制拉伸到 totalWidth 宽度，
    // 否则多铺的备用列 tile 会丢失。
    return Padding(
      padding: EdgeInsets.only(top: m.totalHeight - m.groundHeight),
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: m.tileWidth * totalTiles,
        maxHeight: m.groundHeight,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: m.tileWidth * totalTiles,
          height: m.groundHeight,
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
    );
  }
}