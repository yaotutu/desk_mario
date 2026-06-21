import 'package:flutter/material.dart';

import '../../../shared/widgets/scrolling_world.dart';

/// 视差背景（Layer 1：世界远景）
///
/// 方案：sprite-resource SMB1 NES Overworld "Background 1 (Mountains) panel 1" 真实素材。
///
/// 实现要点：
/// - 真实 panel 1 = 768×176（已裁掉 sheet 上方调色板标签 + 底部 horizon 边框），
///   比例 [imageAspect] = 4.364。
/// - **窗口自适应 + 与 ground 绑死**：所有基础尺寸由 [ScrollingWorld] 统一算，
///   本层只从 [ScrollingMetrics] 读 panelWidth / panelHeight / progress，
///   缩放/滚动天然与 [GroundLayer] 协调。
/// - 水平方向：2 张 panel 1 用 Stack + Positioned 横向拼接
///   （总宽度 = 2 × panelWidth >> totalWidth），
///   整 Stack 一起 shift = -progress × panelWidth，一个完整周期 = 一个 panel 宽度。
/// - panel 1 渲染宽度由 Positioned 强制 = panelWidth，BoxFit.fill 把原图
///   768×176 拉伸到 panelWidth × panelHeight（比例恰好匹配 imageAspect，无失真）。
///
/// 为什么不用 Row：Row 子项总宽 = 2 × panelWidth >> totalWidth，
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
    // 一个 controller 周期走完一个 panel 宽度（panel 1 + panel 2 拼接后永远铺满）。
    final shift = -m.progress * m.panelWidth;

    return SizedBox.expand(
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(shift, 0),
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
      ),
    );
  }
}