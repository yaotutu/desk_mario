import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';

/// 全屏氛围层（L-1 Atmosphere，最底层滤镜）
///
/// 作用：给整个场景叠一层统一的"空气感"，让 L0~L5 看起来像在同一个
/// 时空里（而不是各自漂浮）。具体表现为：
/// 1. **色温覆盖**：黑夜模式叠冷蓝色（夜色），白天模式基本透明（暖色由
///    背景自带）。色温取自 [ColorFiltered]，作用于 L0 之上所有层。
/// 2. **边缘暗角**：用 [RadialGradient] 给屏幕四角加一层淡黑渐变，
///    让视线自然聚焦到中央 Mario 区域，是 16:9 横屏摆件的常见构图技巧。
///
/// 不与 L4 backgroundDimProvider 冲突：backgroundDim 是临时告警触发的
/// 灰度+模糊（只覆盖 L0~L1），而本层是常态氛围（覆盖 L0~L5）。
///
/// 不拦截用户点击：Debug 面板在 L5 System，本层在 L-1 不会被任何层
/// 覆盖，但为了保险依然包一层 [IgnorePointer]。
class AtmosphericLayer extends ConsumerWidget {
  const AtmosphericLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return IgnorePointer(
      child: SizedBox.expand(
        // ColorFiltered 会作用于 L0 之上的所有层（含 L1~L5），
        // 但放在 Atmosphere 内会导致自己也染色（死循环）。
        // 所以本层用纯 Stack：色温由内层 ColorFiltered 在 L0 之上叠加。
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 色温覆盖（黑天叠冷蓝，白天基本透明）
            if (isDark)
              const _ColorTemperatureOverlay(temperature: Color(0xFF1A2E4A)),
            // 2. 边缘暗角（昼夜通用，加强视觉聚焦）
            const _VignetteOverlay(),
          ],
        ),
      ),
    );
  }
}

/// 色温覆盖层：黑天叠冷蓝色，白天叠极淡暖色。
///
/// 用 [IgnorePointer] + [Positioned.fill] 包住一层 [Container.color]，
/// 透明度 0.40（黑夜）能在不破坏 Mario 红/草绿等关键 sprite 颜色的
/// 前提下，让画面整体明显偏冷；白天不叠（alpha=0）。
class _ColorTemperatureOverlay extends StatelessWidget {
  const _ColorTemperatureOverlay({required this.temperature});

  /// 覆盖色（黑夜 = 冷蓝，白天 = 暖黄）。alpha 决定强度。
  final Color temperature;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: temperature.withValues(alpha: 0.28),
      ),
    );
  }
}

/// 边缘暗角：从中心全透明 → 四角黑色半透明，营造电影感聚焦。
class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay();

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
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.32),
            ],
            stops: const [0.0, 0.55, 0.85, 1.0],
          ),
        ),
      ),
    );
  }
}