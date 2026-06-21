import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../parallax/widgets/ground_layer.dart';

/// 主角 Mario（Layer 3，叠在 Layer 2 地面之上）
///
/// 默认动态：跑步 3 帧循环 + 上下轻微浮动，配合 [ParallaxBackground] 和
/// [GroundLayer] 的横向滚动，呈现"Mario 在无限往前跑"的经典横版卷轴效果。
///
/// 传 `staticMode: true` 可切到静态站立（仅在确实需要静态摆件时使用）。
///
/// 替换素材点：换其他 Mario 变身状态（小/Super/Fiery），
/// 只需改 [_runFrames] / [_standFrame] 数组指向新的 PNG 文件名即可。
class MarioWidget extends StatefulWidget {
  const MarioWidget({
    super.key,
    this.staticMode = false,
  });

  /// true = 静态站立（big_stand），false = 跑步 3 帧循环 + 上下浮动。
  /// 默认 false，配合场景横向滚动呈现 Mario 向前跑的视觉效果。
  final bool staticMode;

  @override
  State<MarioWidget> createState() => _MarioWidgetState();
}

class _MarioWidgetState extends State<MarioWidget>
    with TickerProviderStateMixin {
  late final AnimationController _frameCtrl; // 帧切换（仅跑步模式）
  late final AnimationController _floatCtrl; // 上下浮动（仅跑步模式）

  /// Big Mario 跑步 3 帧（NES 原版，16×32）
  static const _runFrames = [
    'assets/sprites/mario_big_run_f0.png',
    'assets/sprites/mario_big_run_f1.png',
    'assets/sprites/mario_big_run_f2.png',
  ];

  /// Big Mario 站立帧（NES 原版，16×32）
  static const _standFrame = 'assets/sprites/mario_big_stand.png';

  /// 放大倍数（NES 16×32 → 64×128）
  static const _scale = 4.0;

  @override
  void initState() {
    super.initState();
    if (!widget.staticMode) {
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
  }

  @override
  void didUpdateWidget(covariant MarioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.staticMode && !oldWidget.staticMode) {
      _frameCtrl.dispose();
      _floatCtrl.dispose();
    } else if (!widget.staticMode && oldWidget.staticMode) {
      _initRunAnimations();
    }
  }

  void _initRunAnimations() {
    _frameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..repeat();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    if (!widget.staticMode) {
      _frameCtrl.dispose();
      _floatCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.staticMode) {
      // 静态站立：直接渲染 big_stand，不开任何 AnimationController
      return Image.asset(
        _standFrame,
        width: 16 * _scale,
        height: 32 * _scale,
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      );
    }

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
/// Step 2：Mario 站在 GroundLayer 顶部（地砖之上）。
///
/// Mario 的 bottom = 屏高 × [GroundLayer.groundRatio]，
/// 这样 Mario 脚底正好贴在地砖顶部，不悬浮也不埋进地砖。
class PositionedMario extends StatelessWidget {
  const PositionedMario({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Mario 脚底 = 屏底往上 groundHeight 处（= GroundLayer 顶部）
    final bottom = size.height * GroundLayer.groundRatio;
    // 水平方向偏左 18%（保留原位置）
    return Positioned(
      left: size.width * 0.18,
      bottom: bottom,
      child: const MarioWidget(),
    );
  }
}