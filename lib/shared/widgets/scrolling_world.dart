import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/parallax/widgets/ground_layer.dart';
import '../../features/parallax/widgets/parallax_background.dart';

/// 滚动世界顶层容器
///
/// 解决问题：原来 [ParallaxBackground] 和 [GroundLayer] 各自用 [LayoutBuilder]
/// 算 panelWidth/tileWidth/groundHeight，缩放时两层独立计算，屏宽变化时
/// `floor(屏宽/tileWidth)` 不整除 → 末格 tile 没铺到 + tile 像素不对齐 →
/// 视觉抖动 + 右侧露出 sky。
///
/// 修法：ScrollingWorld 顶层统一算基础尺寸，并通过 [ScrollingMetrics]
/// InheritedWidget 暴露给两个层；共享 progress（同一 AnimationController）。
/// tileWidth 锁死 = panelWidth / [GroundLayer.tilesPerPanel]（整数比 1:32），
/// tileCount 固定 [GroundLayer.totalTiles]（永远铺满 + 多 2 列滚动备用）。
///
/// 当前视差设置：
/// - [ParallaxBackground] shift = -progress × panelWidth（一个 controller 周期走一个 panel）
/// - [GroundLayer] shift = -progress × tileWidth × scrollTilesPerPeriod
///   （一个 controller 周期走 [GroundLayer.scrollTilesPerPeriod] 个 tile 周期，
///   60s 走 5 tile = 12s/tile；远景 6.4× 慢 = 经典视差）
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

            return ScrollingMetrics(
              progress: _ctrl.value,
              panelWidth: panelWidth,
              panelHeight: panelHeight,
              tileWidth: tileWidth,
              groundHeight: groundHeight,
              totalWidth: width,
              totalHeight: height,
              child: Stack(
                fit: StackFit.expand,
                children: const [
                  ParallaxBackground(),
                  GroundLayer(),
                ],
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
      panelWidth != old.panelWidth ||
      panelHeight != old.panelHeight ||
      tileWidth != old.tileWidth ||
      groundHeight != old.groundHeight ||
      totalWidth != old.totalWidth ||
      totalHeight != old.totalHeight;
}
