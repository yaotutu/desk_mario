import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L1 Weather 与 L3 HUD 共用的视图态天气类型。
///
/// 这里先只表达"现在是什么天气"，不接真实数据源。全屏天气视觉必须等
/// 真实 raster 素材入库后再渲染，避免用手绘粒子违反素材规则。
enum WeatherCondition {
  clear(label: 'CLEAR'),
  rain(label: 'RAIN'),
  snow(label: 'SNOW'),
  fog(label: 'FOG'),
  storm(label: 'STORM');

  const WeatherCondition({required this.label});

  final String label;
}

/// 天气快照（当前阶段为 view-only mock 数据）。
class WeatherSnapshot {
  const WeatherSnapshot({required this.condition, required this.temperatureC});

  final WeatherCondition condition;
  final int temperatureC;

  String get displayText => '${condition.label} ${temperatureC}C';

  WeatherSnapshot copyWith({WeatherCondition? condition, int? temperatureC}) {
    return WeatherSnapshot(
      condition: condition ?? this.condition,
      temperatureC: temperatureC ?? this.temperatureC,
    );
  }
}

/// 当前天气视图状态。
///
/// 默认用下雨态，让 HUD 第一屏能表达"天气数据入口已经存在"；L1 全屏
/// 雨效仍保持透明，直到真实雨滴/雪花 raster 素材可用。
final weatherProvider = StateProvider<WeatherSnapshot>(
  (ref) =>
      const WeatherSnapshot(condition: WeatherCondition.rain, temperatureC: 18),
);
