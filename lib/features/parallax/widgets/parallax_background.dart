import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视差滚动背景（Layer 1：世界远景）
///
/// 方案：sprite-resource SMB1 NES Overworld "Background 1 panel 1" 真实素材。
///
/// 实现要点：
/// - 素材已经预处理：去掉原图 y=0..32 的"地平线紫横条"（用主天空纹理覆盖），
///   避免拉伸到全屏时屏幕顶部出现突兀的实色横条。
/// - **窗口自适应**：以窗口高度 H 为基准，等比计算 panel 1 渲染宽度 W = H × 3.69，
///   panel 1 渲染尺寸 (W, H) 始终保持原图比例 3.69:1，避免山的轮廓变形。
/// - panel 1 居中显示：宽度不足时左右透出 skyTop（外层 Scaffold 提供）。
/// - 水平方向：2 张 panel 1 横向拼接 + 按 [progress] 平移，120s 一周期循环滚动。
///   慢速滚动缓解 sprite 资源云种类有限带来的"视觉重复感"。
/// - 没有 CustomPaint / 没有重复叠放，100% sprite-resource 真实素材。
class ParallaxBackground extends ConsumerStatefulWidget {
  const ParallaxBackground({super.key});

  /// 远景滚动速度倍率：与 [AnimationController.duration] 相除得到实际周期。
  /// duration=60s × speed=0.5 → 实际 120s 一周期。
  static const double speed = 0.5;

  /// panel 1 原图比例 768:208（已处理过顶紫横条，仍按 208 算高度比例）。
  static const double imageAspect = 768 / 208; // ≈ 3.692

  @override
  ConsumerState<ParallaxBackground> createState() =>
      _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends ConsumerState<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // 60s × speed 0.5 = 120s 一周期
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress = (_ctrl.value * ParallaxBackground.speed) % 1.0;
        return SizedBox.expand(child: _BackgroundLayer(progress: progress));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  背景层：等比缩放 + 居中 + 水平循环
// ─────────────────────────────────────────────────────────────────────────

/// 背景层：
/// - 以窗口高度 H 为基准，panel 1 渲染宽度 = H × imageAspect（保持 3.69:1 等比）
/// - panel 1 居中显示：左右透出 skyTop（外层 Scaffold 提供）
/// - 水平方向 2 张 panel 1 拼接 + 按 progress 平移（周期 = panel 1 渲染宽度）
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.progress});

  final double progress;

  static const String _assetPath =
      'assets/backgrounds/smb_background_overworld.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // panel 1 等比渲染：高度 = 屏高，宽度 = 屏高 × 原图比例
        final panelWidth = screenHeight * ParallaxBackground.imageAspect;
        final panelHeight = screenHeight;

        // panel 1 水平居中起始位置
        final centerLeft = (screenWidth - panelWidth) / 2;
        // 滚动位移：1 周期 = 1 张 panel 1 渲染宽度
        final shift = progress * panelWidth;

        return SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 第 1 张 panel 1：随 shift 向左滑出
                Positioned(
                  left: centerLeft - shift,
                  top: 0,
                  width: panelWidth,
                  height: panelHeight,
                  child: Image.asset(
                    _assetPath,
                    width: panelWidth,
                    height: panelHeight,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                // 第 2 张 panel 1：紧贴第 1 张右侧
                Positioned(
                  left: centerLeft + panelWidth - shift,
                  top: 0,
                  width: panelWidth,
                  height: panelHeight,
                  child: Image.asset(
                    _assetPath,
                    width: panelWidth,
                    height: panelHeight,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}