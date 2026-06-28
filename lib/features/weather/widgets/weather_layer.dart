import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  static const clearCueKey = ValueKey<String>('weather-cue-clear');
  static const rainCueKey = ValueKey<String>('weather-cue-rain');
  static const snowCueKey = ValueKey<String>('weather-cue-snow');
  static const fogCueKey = ValueKey<String>('weather-cue-fog');
  static const stormCueKey = ValueKey<String>('weather-cue-storm');

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
/// 当前阶段不画假雨雪粒子，只用已有 SMB raster sprite 做天气世界提示。
/// 未来有真实雨滴/雪花/雾片资产后，可在这里替换为粒子/片层版本。
class _AssetBackedWeatherOverlay extends StatelessWidget {
  const _AssetBackedWeatherOverlay({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    final cue = switch (weather.condition) {
      WeatherCondition.clear => const _ClearCue(),
      WeatherCondition.rain => const _RainCue(),
      WeatherCondition.snow => const _SnowCue(),
      WeatherCondition.fog => const _FogCue(),
      WeatherCondition.storm => const _StormCue(),
    };

    return Stack(fit: StackFit.expand, children: [cue]);
  }
}

class _ClearCue extends StatelessWidget {
  const _ClearCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: WeatherLayer.clearCueKey,
      left: 88.w,
      top: 92.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _WeatherSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 34,
            height: 34,
          ),
          SizedBox(width: 8.w),
          const _WeatherSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 18,
            height: 25.2,
          ),
        ],
      ),
    );
  }
}

class _RainCue extends StatelessWidget {
  const _RainCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: WeatherLayer.rainCueKey,
      left: 76.w,
      top: 108.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _WeatherSprite(
            asset: 'assets/sprites/cloud_small.png',
            width: 118,
            height: 50.6,
          ),
          Positioned(
            left: 92.w,
            top: 31.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/cloud_small.png',
              width: 72,
              height: 30.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnowCue extends StatelessWidget {
  const _SnowCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: WeatherLayer.snowCueKey,
      left: 86.w,
      top: 104.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _WeatherSprite(
            asset: 'assets/sprites/cloud_small.png',
            width: 116,
            height: 49.7,
          ),
          Positioned(
            left: 26.w,
            top: 48.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/starman_f0.png',
              width: 18,
              height: 18,
            ),
          ),
          Positioned(
            left: 72.w,
            top: 64.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/starman_f0.png',
              width: 14,
              height: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FogCue extends StatelessWidget {
  const _FogCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: WeatherLayer.fogCueKey,
      left: 58.w,
      top: 118.h,
      child: Opacity(
        opacity: 0.72,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _WeatherSprite(
              asset: 'assets/sprites/cloud_small.png',
              width: 88,
              height: 37.7,
            ),
            Transform.translate(
              offset: Offset(-18.w, 12.h),
              child: const _WeatherSprite(
                asset: 'assets/sprites/cloud_small.png',
                width: 112,
                height: 48,
              ),
            ),
            Transform.translate(
              offset: Offset(-36.w, 2.h),
              child: const _WeatherSprite(
                asset: 'assets/sprites/cloud_small.png',
                width: 78,
                height: 33.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StormCue extends StatelessWidget {
  const _StormCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: WeatherLayer.stormCueKey,
      left: 78.w,
      top: 94.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _WeatherSprite(
            asset: 'assets/sprites/cloud_small.png',
            width: 126,
            height: 54,
          ),
          Positioned(
            left: 22.w,
            top: 54.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/block_question_f0.png',
              width: 30,
              height: 30,
            ),
          ),
          Positioned(
            left: 62.w,
            top: 38.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/coin_f0.png',
              width: 22,
              height: 30.8,
            ),
          ),
          Positioned(
            left: 96.w,
            top: 54.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/block_question_f1.png',
              width: 30,
              height: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSprite extends StatelessWidget {
  const _WeatherSprite({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width.w,
      height: height.h,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      fit: BoxFit.contain,
    );
  }
}
