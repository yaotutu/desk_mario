import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/world_state/providers/world_state_loop_provider.dart';

/// 全屏氛围层（L-1 Atmosphere，最底层滤镜）
///
/// 作用：给整个场景叠一层统一的"空气感"，让 L0~L5 看起来像在同一个
/// 时空里（而不是各自漂浮）。具体表现为：
/// 1. **色温覆盖**：由 [worldStateLoopProvider] 把天气、时间、告警
///    解释成一套 tint 配方，统一覆盖在 L0~L4 之上。
/// 2. **边缘暗角**：暗角强度同样来自世界状态；雨夜/风暴更重，晴天更轻，
///    让视线自然聚焦到中央 Mario 区域，是 16:9 横屏摆件的常见构图技巧。
///
/// 不与 L4 backgroundDimProvider 冲突：backgroundDim 是临时告警触发的
/// 灰度+模糊（只覆盖 L0~L1），而本层是常态氛围（覆盖 L0~L5）。
///
/// 不拦截用户点击：Debug 面板在 L5 System，本层在 L-1 不会被任何层
/// 覆盖，但为了保险依然包一层 [IgnorePointer]。
class AtmosphericLayer extends ConsumerWidget {
  const AtmosphericLayer({super.key});

  static const temperatureOverlayKey = ValueKey<String>(
    'atmosphere-temperature-overlay',
  );
  static const vignetteOverlayKey = ValueKey<String>('atmosphere-vignette');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(worldStateLoopProvider).atmosphere;

    return IgnorePointer(
      child: SizedBox.expand(
        // 本层故意只叠半透明颜色和暗角，不绘制任何天气粒子。雨雪雾等
        // 粒子效果必须等真实 raster 素材入库后再放到 L1 WeatherLayer。
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 色温覆盖：由天气 + 时间 + 告警共同决定。
            if (recipe.tintOpacity > 0)
              _ColorTemperatureOverlay(
                key: temperatureOverlayKey,
                temperature: recipe.tint,
                opacity: recipe.tintOpacity,
              ),
            // 2. 边缘暗角：按当前世界状态调整聚焦强度。
            _VignetteOverlay(
              key: vignetteOverlayKey,
              midOpacity: recipe.vignetteMidOpacity,
              outerOpacity: recipe.vignetteOuterOpacity,
            ),
          ],
        ),
      ),
    );
  }
}

/// 色温覆盖层：把世界状态配方转成全屏半透明色温。
///
/// 这里只处理光照和空气感，不创建新物体，因此不违反真实素材规则。
class _ColorTemperatureOverlay extends StatelessWidget {
  const _ColorTemperatureOverlay({
    super.key,
    required this.temperature,
    required this.opacity,
  });

  /// 覆盖色（黑夜 = 冷蓝，白天 = 暖黄）。alpha 决定强度。
  final Color temperature;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(color: temperature.withValues(alpha: opacity)),
    );
  }
}

/// 边缘暗角：从中心全透明 → 四角黑色半透明，营造电影感聚焦。
class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay({
    super.key,
    required this.midOpacity,
    required this.outerOpacity,
  });

  final double midOpacity;
  final double outerOpacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: midOpacity),
              Colors.black.withValues(alpha: outerOpacity),
            ],
            stops: const [0.0, 0.55, 0.85, 1.0],
          ),
        ),
      ),
    );
  }
}
