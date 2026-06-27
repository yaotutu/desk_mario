import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../parallax/widgets/ground_layer.dart';

/// 主角 Mario 的共享渲染常量
///
/// NES 16×32 原始 sprite 放大 4× → 64×128（设计尺寸）。
/// 公开给 [PositionedMario] 居中计算和两个独立 widget 共用。
class MarioDisplay {
  const MarioDisplay._();

  /// 放大倍数（NES 16×32 → 64×128）
  static const double kScale = 4.0;

  /// Mario 渲染宽度（逻辑像素）
  static const double width = 16 * kScale;

  /// Mario 渲染高度（逻辑像素）
  static const double height = 32 * kScale;
}

/// 跑步版 Mario（Layer 2 主角，默认使用）
///
/// 跑步 3 帧循环 + 上下轻微浮动，配合 [ParallaxBackground] 和
/// [GroundLayer] 的横向滚动，呈现"Mario 在无限往前跑"的经典横版卷轴效果。
///
/// 替换素材点：换其他 Mario 变身状态（小/Super/Fiery），
/// 只需改 [_runFrames] 数组指向新的 PNG 文件名即可。
class MarioWidget extends StatefulWidget {
  const MarioWidget({super.key});

  /// Big Mario 跑步 3 帧（NES 原版，16×32）
  static const _runFrames = [
    'assets/sprites/mario_big_run_f0.png',
    'assets/sprites/mario_big_run_f1.png',
    'assets/sprites/mario_big_run_f2.png',
  ];

  @override
  State<MarioWidget> createState() => _MarioWidgetState();
}

class _MarioWidgetState extends State<MarioWidget>
    with TickerProviderStateMixin {
  late final AnimationController _frameCtrl; // 帧切换
  late final AnimationController _floatCtrl; // 上下浮动

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
        final frameIndex =
            (_frameCtrl.value * MarioWidget._runFrames.length).floor() %
            MarioWidget._runFrames.length;
        return Image.asset(
          MarioWidget._runFrames[frameIndex],
          width: MarioDisplay.width,
          height: MarioDisplay.height,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

/// 静态站立版 Mario（仅在确实需要静态摆件时使用，例如截图/设置页）
///
/// 无任何动画，渲染单张 `mario_big_stand.png`。
class StaticMario extends StatelessWidget {
  const StaticMario({super.key});

  static const String _asset = 'assets/sprites/mario_big_stand.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: MarioDisplay.width,
      height: MarioDisplay.height,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      fit: BoxFit.contain,
    );
  }
}

/// 屏幕定位 wrapper
///
/// Step 2：Mario 站在 GroundLayer 顶部（地砖之上）。
///
/// Mario 的 bottom = 屏高 × [GroundLayer.groundRatio]，
/// 这样 Mario 脚底正好贴在地砖顶部，不悬浮也不埋进地砖。
///
/// 水平方向：Mario 中心点固定在屏宽 1/3 处（经典横版游戏视觉焦点），
/// 留更多右侧空间给『前进方向』，横竖屏切换 / 屏幕宽度变化时
/// Mario 都保持在这个相对位置。
class PositionedMario extends StatelessWidget {
  const PositionedMario({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Mario 脚底 = 屏底往上 groundHeight 处（= GroundLayer 顶部）
    final bottom = size.height * GroundLayer.groundRatio;
    // 水平方向：Mario 中心点 = 屏宽 / 3
    final left = size.width / 3 - MarioDisplay.width / 2;
    return Positioned(left: left, bottom: bottom, child: const MarioWidget());
  }
}
