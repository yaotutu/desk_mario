import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/parallax/widgets/ground_layer.dart';
import '../../features/parallax/widgets/parallax_background.dart';

/// 滚动世界顶层容器
///
/// 解决问题：
/// 1. 尺寸：原来 [ParallaxBackground] 和 [GroundLayer] 各自用 [LayoutBuilder]
///    算 panelWidth/tileWidth/groundHeight，缩放时两层独立计算，屏宽变化时
///    `floor(屏宽/tileWidth)` 不整除 → 末格 tile 没铺到 + tile 像素不对齐
///    → 视觉抖动 + 右侧露出 sky。ScrollingWorld 顶层统一算基础尺寸，
///    通过 [ScrollingMetrics] InheritedWidget 暴露给两个层。
/// 2. 同步：原来 panel 和 ground 各自算 shift，1 个周期内 panel 走 panelWidth、
///    ground 走 5 tile 宽度（视差反了：panel 比 ground 快 6.4×），容易错位。
///    现在 ScrollingWorld 顶层统一算 shift = -progress × panelWidth，
///    用单个 [Transform.translate] 包住整个 panel + ground 子树，
///    整个世界永远同步平移。
///
/// 关键比例：tileWidth 锁死 = panelWidth / [GroundLayer.tilesPerPanel]
/// （整数比 1:32），所以 1 个 controller 周期内整个世界正好平移 1 个 panel 宽度
/// = 32 个 tile 宽度 = 1 个完整 tile 循环，与 panel 1 的 1 次完整切换严格同步。
///
/// 视差（远景慢/近景快）后续可在 panel 内部拆更细的子层（云朵 / 山脉 / 远景）实现，
/// 但 panel 和 ground 这两层保持严格 1:1 同步，避免错位 bug。
class ScrollingWorld extends ConsumerStatefulWidget {
  const ScrollingWorld({super.key});

  /// 远景滚动一个完整 controller 周期（秒）。
  /// 60s 内 progress [0, 1)，panel 走完一个 panel 宽度。
  static const int periodSeconds = 60;

  @override
  ConsumerState<ScrollingWorld> createState() => _ScrollingWorldState();
}

class _ScrollingWorldState extends ConsumerState<ScrollingWorld>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: ScrollingWorld.periodSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 必须 AnimatedBuilder 包 LayoutBuilder，否则 _ctrl.value 变化不触发 rebuild，
    // background 和 ground 会静止不动（只 MarioWidget 自己的 _ctrl + AnimatedBuilder
    // 能让 Mario 跑）。这是经典错：直接读 Listenable.value 不会订阅。
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 基础尺寸（绑死 panelWidth 和 tileWidth 比例 = tilesPerPanel:1）
            final groundHeight = height * GroundLayer.groundRatio;
            final panelHeight = height - groundHeight;
            final panelWidth = panelHeight * ParallaxBackground.imageAspect;
            // tileWidth = panelWidth / tilesPerPanel（整数比，确保对齐）
            final tileWidth = panelWidth / GroundLayer.tilesPerPanel;

            // 整体 shift：panel 和 ground 共享同一个 Transform.translate，
            // 永远同步。1 个周期内整个世界向左平移 panelWidth = 32 tile 宽度。
            // 视差（远景慢/近景快）后续可在 panel 内部拆更细的子层实现，
            // 但 panel 和 ground 这两层保持严格 1:1 同步，避免错位 bug。
            final shift = -_ctrl.value * panelWidth;

            return ScrollingMetrics(
              progress: _ctrl.value,
              shift: shift,
              panelWidth: panelWidth,
              panelHeight: panelHeight,
              tileWidth: tileWidth,
              groundHeight: groundHeight,
              totalWidth: width,
              totalHeight: height,
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRect(
                  child: Transform.translate(
                    offset: Offset(shift, 0),
                    child: Stack(
                      // loose 让 ParallaxBackground (4616×529) 和 GroundLayer
                      // (33*tileWidth × groundHeight) 保持自己的尺寸不被拉伸，
                      // 超出 totalWidth 的部分由外层 ClipRect 裁掉。
                      children: const [
                        ParallaxBackground(),
                        GroundLayer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 共享滚动指标（InheritedWidget）
///
/// 由 [ScrollingWorld] 提供给 [ParallaxBackground] 和 [GroundLayer]。
/// 任一字段变化都触发子树 rebuild，确保 background 和 ground 完全同步。
class ScrollingMetrics extends InheritedWidget {
  /// AnimationController 当前进度，0.0 ~ 1.0（一个 controller 周期内）。
  final double progress;

  /// 整体水平偏移（已应用 Transform.translate），子层直接叠在 Transform 内即可。
  /// 一个周期内 shift 从 0 走到 -panelWidth，panel 切换一次 + ground 循环 32 tile 一次。
  final double shift;

  /// 背景 panel 1 渲染宽度（一个完整滚动周期 = 这个距离）。
  final double panelWidth;

  /// 背景 panel 1 渲染高度（= totalHeight - groundHeight）。
  final double panelHeight;

  /// 地面 tile 渲染宽度 = panelWidth / [GroundLayer.tilesPerPanel]。
  final double tileWidth;

  /// 地面渲染高度。
  final double groundHeight;

  /// 整个屏幕宽度。
  final double totalWidth;

  /// 整个屏幕高度。
  final double totalHeight;

  const ScrollingMetrics({
    super.key,
    required this.progress,
    required this.shift,
    required this.panelWidth,
    required this.panelHeight,
    required this.tileWidth,
    required this.groundHeight,
    required this.totalWidth,
    required this.totalHeight,
    required super.child,
  });

  static ScrollingMetrics of(BuildContext context) {
    final m = context.dependOnInheritedWidgetOfExactType<ScrollingMetrics>();
    assert(m != null, 'ScrollingMetrics not found in tree');
    return m!;
  }

  @override
  bool updateShouldNotify(ScrollingMetrics old) =>
      progress != old.progress ||
      shift != old.shift ||
      panelWidth != old.panelWidth ||
      panelHeight != old.panelHeight ||
      tileWidth != old.tileWidth ||
      groundHeight != old.groundHeight ||
      totalWidth != old.totalWidth ||
      totalHeight != old.totalHeight;
}
