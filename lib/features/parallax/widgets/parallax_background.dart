import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视差滚动背景（Layer 1：世界远景）
///
/// 方案：sprite-resource SMB1 NES Overworld "Background 1 panel 1" 真实素材。
///
/// 实现要点：
/// - 素材已经预处理：去掉原图 y=0..32 的"地平线紫横条"（用主天空纹理覆盖），
///   避免拉伸到全屏时屏幕顶部出现突兀的实色横条。
/// - `BoxFit.fill` 强制拉伸到全屏（1280×720），横向 1.67×、纵向 3.46×。
///   失真可控 —— 8-bit 像素艺术拉伸反而强化了复古感。
/// - 水平方向：2 张 panel 1 横向拼接 + 按 [progress] 平移，30s 一周期循环滚动。
/// - 没有 CustomPaint / 没有重复叠放，100% sprite-resource 真实素材。
class ParallaxBackground extends ConsumerStatefulWidget {
  const ParallaxBackground({super.key});

  /// 远景滚动速度（30s 一周期）。
  static const double speed = 0.5;

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
      duration: const Duration(seconds: 30),
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

/// 背景层：panel 1 拉伸到全屏 + 水平 2 张拼接循环。
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({required this.progress});

  final double progress;

  static const String _assetPath =
      'assets/backgrounds/smb_background_overworld.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final shift = progress * width;

        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -shift,
                  top: 0,
                  width: width,
                  height: height,
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                Positioned(
                  left: width - shift,
                  top: 0,
                  width: width,
                  height: height,
                  child: Image.asset(
                    _assetPath,
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