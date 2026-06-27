import 'package:flutter/material.dart';

import 'scrolling_world.dart';

/// 视差背景（Layer 1：世界远景）
///
/// 方案：sprite-resource SMB1 NES Overworld "Background 1 (Mountains) panel 1" 真实素材。
///
/// 实现要点：
/// - 真实 panel 1 = 768×176（已裁掉 sheet 上方调色板标签 + 底部 horizon 边框），
///   比例 [imageAspect] = 4.364。
/// - **作为整体滚动世界的成员**：本层只负责画 panel 1 内容，**不**自己算 shift/Transform。
///   统一的 Transform.translate 由 [ScrollingWorld] 顶层包住，
///   整个世界（panel + ground）永远同步平移，杜绝两层独立 shift 算错导致错位。
/// - 水平方向：2 张 panel 1 用 Stack + Positioned 横向拼接（总宽 = 2 × panelWidth），
///   拼接后无论平移到哪一格，0..totalWidth 区间永远有 panel 内容可见。
/// - panel 1 渲染宽度由 Positioned 强制 = panelWidth，BoxFit.fill 把原图
///   768×176 拉伸到 panelWidth × panelHeight（比例恰好匹配 imageAspect，无失真）。
///
/// 为什么用 Stack + Positioned 而非 Row：Row 子项总宽 = 2 × panelWidth >> totalWidth，
/// 在 1280×720 设计尺寸下 overflow ~4250px 触发 RenderFlex overflow assertion。
/// Stack + Positioned 子项可以超出 Stack 边界（被外层 ClipRect 裁掉），不报错。
class ParallaxBackground extends StatelessWidget {
  const ParallaxBackground({super.key});

  /// panel 1 原图比例 768:176（已裁掉 sheet 上方调色板标签 + 底部 horizon 边框）。
  static const double imageAspect = 768 / 176; // ≈ 4.364

  static const String _assetPath =
      'assets/backgrounds/smb_background_overworld.png';

  @override
  Widget build(BuildContext context) {
    final m = ScrollingMetrics.of(context);

    // 拼接 2 张 panel 1 横向铺开（总宽 2 × panelWidth），平移由 ScrollingWorld 统一管。
    // 这里只画内容。
    //
    // 关键：用 [OverflowBox] 给内部一个无界 maxWidth 约束，
    // 避免被父 [Stack] 的 tight constraint 强制拉伸到 totalWidth 宽度，
    // 否则 SizedBox(width: 2 × panelWidth) 会被 Stack 忽略，
    // 导致第 2 张 panel 永远渲染不出来（位于 Stack 边界外被裁）。
    return OverflowBox(
      minWidth: 0,
      minHeight: 0,
      maxWidth: m.panelWidth * 2,
      maxHeight: m.panelHeight,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: m.panelWidth * 2,
        height: m.panelHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: m.panelWidth,
              height: m.panelHeight,
              child: Image.asset(
                _assetPath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
            Positioned(
              left: m.panelWidth,
              top: 0,
              width: m.panelWidth,
              height: m.panelHeight,
              child: Image.asset(
                _assetPath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
