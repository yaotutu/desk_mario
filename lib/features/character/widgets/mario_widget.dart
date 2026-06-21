import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 主角 Mario（Layer 2）
///
/// v2 重构：
/// - 用 Big Mario（16×32 NES 原版）×4 = 64×128 设计尺寸
/// - 3 帧跑步 + 上下轻微浮动
/// - 定位：站在"地平线"上（屏高 58% 处的近景顶部）
///
/// 替换素材点：换其他 Mario 变身状态（小/Super/Fiery），
/// 只需改 _runFrames 数组指向新的 PNG 文件名即可。
class MarioWidget extends StatefulWidget {
  const MarioWidget({super.key});

  @override
  State<MarioWidget> createState() => _MarioWidgetState();
}

class _MarioWidgetState extends State<MarioWidget>
    with TickerProviderStateMixin {
  late final AnimationController _frameCtrl; // 帧切换
  late final AnimationController _floatCtrl; // 上下浮动

  /// Big Mario 跑步 3 帧（NES 原版，16×32）
  static const _runFrames = [
    'assets/sprites/mario_big_run_f0.png',
    'assets/sprites/mario_big_run_f1.png',
    'assets/sprites/mario_big_run_f2.png',
  ];

  /// 放大倍数（NES 16×32 → 64×128）
  static const _scale = 4.0;

  @override
  void initState() {
    super.initState();
    // 帧动画：3 帧循环，每帧 120ms
    _frameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..repeat();
    // 上下浮动：与帧动画节奏相近，模拟颠簸
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _frameCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, _) {
        // 上下浮动（设计尺寸）
        final dy = (_floatCtrl.value - 0.5) * -6.h;
        return Transform.translate(
          offset: Offset(0, dy),
          child: _buildSprite(),
        );
      },
    );
  }

  Widget _buildSprite() {
    return AnimatedBuilder(
      animation: _frameCtrl,
      builder: (context, _) {
        final frameIndex = (_frameCtrl.value * _runFrames.length).floor() %
            _runFrames.length;
        return Image.asset(
          _runFrames[frameIndex],
          width: 16 * _scale,
          height: 32 * _scale,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

/// 屏幕定位 wrapper
///
/// v2：Mario 站在近景层顶部（屏高 farHeightFactor 之下）。
/// 远景占 farHeightFactor（默认 0.58），所以 Mario bottom = 屏高 × (1 - farHeightFactor)。
class PositionedMario extends StatelessWidget {
  const PositionedMario({super.key});

  /// 远景占屏高比例（与 [ParallaxBackground.farHeightFactor] 保持一致）
  static const double farHeightFactor = 0.58;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Mario 底部站在近景顶部
    final bottom = size.height * (1 - farHeightFactor);
    // 水平方向偏左 18%（保留原位置）
    return Positioned(
      left: size.width * 0.18,
      bottom: bottom,
      child: const MarioWidget(),
    );
  }
}