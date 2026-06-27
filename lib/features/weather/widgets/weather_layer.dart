import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';

/// 天气效果层（L1 Weather，独立成层为后期天气系统预留位置）
///
/// 未来扩展点：
/// - 接 weatherProvider（雨/雪/雾/闪电/沙尘等状态），
///   根据状态在 Stack 内派发对应 weather widget。
/// - 单个 weather widget 内部可自行区分视觉深度：
///   比如雨可以同时有"远景雨"（在 Background 之上、Character 之下）
///   和"近景雨滴"（在 Character 之上、HUD 之下）。
///
/// 当前实现：已接入 view-only [weatherProvider]，但不绘制任何假雨雪。
/// 等真实 weather raster 素材入库后，再在 [_AssetBackedWeatherOverlay] 中
/// 按 condition 渲染对应资产。
class WeatherLayer extends ConsumerWidget {
  const WeatherLayer({super.key});

  static const layerKey = ValueKey<String>('weather-layer');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);

    // 故意 IgnorePointer：天气不应拦截用户点击（Debug 面板在更高层 L5 System）。
    return IgnorePointer(
      key: layerKey,
      child: _AssetBackedWeatherOverlay(weather: weather),
    );
  }
}

/// 真实素材驱动的天气叠层入口。
///
/// 这个 widget 目前对所有天气都返回透明层：下雨/下雪等全屏粒子必须由
/// 真实 raster 素材驱动，不能用 CustomPaint 或几何方块临时代替。
class _AssetBackedWeatherOverlay extends StatelessWidget {
  const _AssetBackedWeatherOverlay({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    switch (weather.condition) {
      case WeatherCondition.clear:
      case WeatherCondition.rain:
      case WeatherCondition.snow:
      case WeatherCondition.fog:
      case WeatherCondition.storm:
        return const SizedBox.expand();
    }
  }
}
