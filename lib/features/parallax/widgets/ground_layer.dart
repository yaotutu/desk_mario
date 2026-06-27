import 'package:flutter/material.dart';

import 'scrolling_world.dart';

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
/// - **永远铺满 + 2 个完整循环 + 1 列备用**：tileCount = 2 × [tilesPerPanel] + 1 = 65，
///   渲染总宽度 = 65 × tileWidth = 2 × panelWidth + tileWidth（与 [ParallaxBackground]
///   的"2 张 panel 拼接"严格对称）。多出的 1 列做接缝冗余。
///   一个 controller 周期（shift 走 panelWidth = 32 tile 宽度）正好让 ground 走完
///   1 个完整 tile 循环，与 panel 1 的 1 次完整切换严格同步。
/// - 没有 CustomPaint，100% sprite-resource 真实素材。
///
/// 为什么不能只铺 [tilesPerPanel] + 1 = 33：ground 总宽 = 33 × tileWidth
/// = 1.03 × panelWidth，shift 接近 -panelWidth 时 ground 整体已经移出屏幕右端，
/// 但 panel 1+2 还能覆盖屏幕 → "有背景、底部没瓷砖"bug。必须铺 2 × panelWidth 才对。
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

  /// 一个 controller 周期（shift 走完 panelWidth）内 panel 走 [tilesPerPanel] 个 tile
  /// 宽度（=1 个 ground 完整循环）。要让 ground 在任何 shift 时刻都铺满屏幕，
  /// ground 渲染总宽必须 ≥ 一个 panel 渲染总宽 = 2 × panelWidth = 2 × [tilesPerPanel]
  /// × tileWidth。多铺 1 列做接缝冗余。
  /// ⚠️ 必须和 [ParallaxBackground] 的"2 张 panel 拼接"对称，否则在某段 shift 范围
  /// 内 panel 已铺满但 ground 漏出 sky（实测 bug_11 截图：ground 宽度仅 204 dp）。
  static const int extraTiles = 1;

  /// tile 总数 = 2 × [tilesPerPanel] + [extraTiles]（铺满 2 个 panel 宽度 + 备用），
  /// 与 [ParallaxBackground] 的 2 张 panel 拼接严格对称。
  static const int totalTiles = 2 * tilesPerPanel + extraTiles;

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
