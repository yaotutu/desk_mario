import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../creative_mode/providers/creative_mode_provider.dart';
import '../../hud/providers/clock_provider.dart';
import '../../notifications/models/notification_severity.dart';
import '../../notifications/providers/background_dim_provider.dart';
import '../../notifications/providers/notification_queue_provider.dart';
import '../../weather/providers/weather_provider.dart';

/// 一天中的 Mario 世界相位。
///
/// 这个相位不是普通主题开关，而是给 L-1 Atmosphere / Diorama 道具使用的
/// 世界时间语义。测试可以直接覆盖 [clockProvider] 来验证不同时间段。
enum WorldTimePhase {
  morning(label: 'MORNING'),
  day(label: 'DAY'),
  dusk(label: 'DUSK'),
  night(label: 'NIGHT');

  const WorldTimePhase({required this.label});

  final String label;
}

/// 强事件告警相位。
///
/// 先保留 enter/release 枚举，为后续做转场动画预留；当前实现只需要 idle
/// 和 holding，就能表达 S4 告警是否已经接管世界。
enum WorldAlertPhase { idle, entering, holding, releasing }

/// Diorama 道具密度。
///
/// Scene 保持最克制，Theater 让通知优先，Diorama 才展开可检查的数据道具。
enum DioramaDensity { minimal, normal, inspectable }

/// L-1 Atmosphere 的渲染配方。
///
/// 这里存的是"世界状态解释结果"，不是 widget。这样天气、时间和 S4 告警
/// 的优先级只在一个地方计算，避免每层各自判断后互相打架。
class AtmosphereRecipe {
  const AtmosphereRecipe({
    required this.tint,
    required this.tintOpacity,
    required this.vignetteMidOpacity,
    required this.vignetteOuterOpacity,
    required this.readabilityPriority,
  });

  final Color tint;
  final double tintOpacity;
  final double vignetteMidOpacity;
  final double vignetteOuterOpacity;
  final bool readabilityPriority;

  static AtmosphereRecipe forState({
    required WeatherCondition condition,
    required WorldTimePhase timePhase,
    required WorldAlertPhase alertPhase,
  }) {
    if (alertPhase == WorldAlertPhase.holding) {
      return const AtmosphereRecipe(
        tint: Color(0xFF050505),
        tintOpacity: 0.14,
        vignetteMidOpacity: 0.28,
        vignetteOuterOpacity: 0.44,
        readabilityPriority: true,
      );
    }

    final base = _timeRecipe(timePhase);

    return switch (condition) {
      WeatherCondition.clear => base,
      WeatherCondition.rain => base.copyWith(
        tint: timePhase == WorldTimePhase.night
            ? const Color(0xFF1C3556)
            : const Color(0xFF2F5D82),
        tintOpacity: _max(
          base.tintOpacity,
          timePhase == WorldTimePhase.night ? 0.34 : 0.22,
        ),
        vignetteMidOpacity: _max(
          base.vignetteMidOpacity,
          timePhase == WorldTimePhase.night ? 0.30 : 0.23,
        ),
        vignetteOuterOpacity: _max(
          base.vignetteOuterOpacity,
          timePhase == WorldTimePhase.night ? 0.48 : 0.38,
        ),
      ),
      WeatherCondition.snow => base.copyWith(
        tint: const Color(0xFFDDEEFF),
        tintOpacity: _max(base.tintOpacity, 0.16),
        vignetteMidOpacity: _max(base.vignetteMidOpacity, 0.14),
        vignetteOuterOpacity: _max(base.vignetteOuterOpacity, 0.28),
      ),
      WeatherCondition.fog => base.copyWith(
        tint: const Color(0xFFC6D2D5),
        tintOpacity: _max(base.tintOpacity, 0.20),
        vignetteMidOpacity: _max(base.vignetteMidOpacity, 0.12),
        vignetteOuterOpacity: _max(base.vignetteOuterOpacity, 0.24),
      ),
      WeatherCondition.storm => base.copyWith(
        tint: const Color(0xFF17233F),
        tintOpacity: _max(base.tintOpacity, 0.34),
        vignetteMidOpacity: _max(base.vignetteMidOpacity, 0.30),
        vignetteOuterOpacity: _max(base.vignetteOuterOpacity, 0.48),
      ),
    };
  }

  AtmosphereRecipe copyWith({
    Color? tint,
    double? tintOpacity,
    double? vignetteMidOpacity,
    double? vignetteOuterOpacity,
    bool? readabilityPriority,
  }) {
    return AtmosphereRecipe(
      tint: tint ?? this.tint,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      vignetteMidOpacity: vignetteMidOpacity ?? this.vignetteMidOpacity,
      vignetteOuterOpacity: vignetteOuterOpacity ?? this.vignetteOuterOpacity,
      readabilityPriority: readabilityPriority ?? this.readabilityPriority,
    );
  }
}

/// 当前整张桌搭画面的世界状态快照。
class WorldStateLoopSnapshot {
  const WorldStateLoopSnapshot({
    required this.weather,
    required this.timePhase,
    required this.creativeMode,
    required this.alertPhase,
    required this.dioramaDensity,
    required this.atmosphere,
  });

  final WeatherSnapshot weather;
  final WorldTimePhase timePhase;
  final CreativeMode creativeMode;
  final WorldAlertPhase alertPhase;
  final DioramaDensity dioramaDensity;
  final AtmosphereRecipe atmosphere;

  bool get isStrongAlert => alertPhase == WorldAlertPhase.holding;
}

/// 统一的 DeskMario 世界状态解释层。
///
/// 它不替代已有 provider，只把天气、时间、通知、模式这些原始状态解释成
/// 渲染层更容易消费的一张快照。所有创意闭环都从这里拿优先级。
final worldTimePhaseOverrideProvider = StateProvider<WorldTimePhase?>(
  (ref) => null,
);

final worldStateLoopProvider = Provider<WorldStateLoopSnapshot>((ref) {
  final weather = ref.watch(weatherProvider);
  final now = ref.watch(clockProvider);
  final overrideTimePhase = ref.watch(worldTimePhaseOverrideProvider);
  final notification = ref.watch(notificationQueueProvider);
  final creativeMode = ref.watch(creativeModeProvider);
  final isDimmed = ref.watch(backgroundDimProvider);

  final alertPhase =
      notification.current?.severity == NotificationSeverity.severity4 ||
          isDimmed
      ? WorldAlertPhase.holding
      : WorldAlertPhase.idle;
  final timePhase = overrideTimePhase ?? worldTimePhaseFromDateTime(now);

  return WorldStateLoopSnapshot(
    weather: weather,
    timePhase: timePhase,
    creativeMode: creativeMode.effectiveMode,
    alertPhase: alertPhase,
    dioramaDensity: switch (creativeMode.effectiveMode) {
      CreativeMode.scene => DioramaDensity.minimal,
      CreativeMode.theater => DioramaDensity.normal,
      CreativeMode.diorama => DioramaDensity.inspectable,
    },
    atmosphere: AtmosphereRecipe.forState(
      condition: weather.condition,
      timePhase: timePhase,
      alertPhase: alertPhase,
    ),
  );
});

WorldTimePhase worldTimePhaseFromDateTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour <= 8) return WorldTimePhase.morning;
  if (hour >= 9 && hour <= 16) return WorldTimePhase.day;
  if (hour >= 17 && hour <= 19) return WorldTimePhase.dusk;
  return WorldTimePhase.night;
}

AtmosphereRecipe _timeRecipe(WorldTimePhase timePhase) {
  return switch (timePhase) {
    WorldTimePhase.morning => const AtmosphereRecipe(
      tint: Color(0xFFFFE8A3),
      tintOpacity: 0.08,
      vignetteMidOpacity: 0.16,
      vignetteOuterOpacity: 0.30,
      readabilityPriority: false,
    ),
    WorldTimePhase.day => const AtmosphereRecipe(
      tint: Color(0xFFFFFFFF),
      tintOpacity: 0.00,
      vignetteMidOpacity: 0.18,
      vignetteOuterOpacity: 0.32,
      readabilityPriority: false,
    ),
    WorldTimePhase.dusk => const AtmosphereRecipe(
      tint: Color(0xFFFF9C55),
      tintOpacity: 0.10,
      vignetteMidOpacity: 0.22,
      vignetteOuterOpacity: 0.36,
      readabilityPriority: false,
    ),
    WorldTimePhase.night => const AtmosphereRecipe(
      tint: Color(0xFF1A2E4A),
      tintOpacity: 0.28,
      vignetteMidOpacity: 0.26,
      vignetteOuterOpacity: 0.42,
      readabilityPriority: false,
    ),
  };
}

double _max(double a, double b) => a > b ? a : b;
