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
      left: 56.w,
      bottom: 108.h,
      child: const _WeatherPipeStation(
        accent: _ClearStationAccent(),
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
      left: 56.w,
      bottom: 108.h,
      child: const _WeatherPipeStation(
        accent: _RainStationAccent(),
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
      left: 56.w,
      bottom: 108.h,
      child: const _WeatherPipeStation(
        accent: _SnowStationAccent(),
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
      left: 56.w,
      bottom: 108.h,
      child: const _WeatherPipeStation(
        accent: _FogStationAccent(),
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
      left: 56.w,
      bottom: 108.h,
      child: const _WeatherPipeStation(
        accent: _StormStationAccent(),
      ),
    );
  }
}

class _WeatherPipeStation extends StatelessWidget {
  const _WeatherPipeStation({required this.accent});

  final Widget accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190.w,
      height: 210.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 32.w,
            bottom: 0,
            child: const _WeatherSprite(
              asset: 'assets/sprites/pipe_tall.png',
              width: 88,
              height: 117.3,
            ),
          ),
          Positioned(left: 0, top: 0, child: accent),
        ],
      ),
    );
  }
}

class _ClearStationAccent extends StatelessWidget {
  const _ClearStationAccent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _WeatherSprite(
          asset: 'assets/sprites/starman_f0.png',
          width: 34,
          height: 34,
        ),
        Positioned(
          left: 42.w,
          top: 28.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 18,
            height: 25.2,
          ),
        ),
      ],
    );
  }
}

class _RainStationAccent extends StatelessWidget {
  const _RainStationAccent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _WeatherSprite(
          asset: 'assets/sprites/cloud_small.png',
          width: 96,
          height: 41.1,
        ),
        Positioned(
          left: 18.w,
          top: 45.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 16,
            height: 22.4,
          ),
        ),
        Positioned(
          left: 58.w,
          top: 62.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 14,
            height: 19.6,
          ),
        ),
      ],
    );
  }
}

class _SnowStationAccent extends StatelessWidget {
  const _SnowStationAccent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _WeatherSprite(
          asset: 'assets/sprites/cloud_small.png',
          width: 92,
          height: 39.4,
        ),
        Positioned(
          left: 16.w,
          top: 48.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 17,
            height: 17,
          ),
        ),
        Positioned(
          left: 62.w,
          top: 68.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 13,
            height: 13,
          ),
        ),
      ],
    );
  }
}

class _FogStationAccent extends StatelessWidget {
  const _FogStationAccent();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _WeatherSprite(
            asset: 'assets/sprites/cloud_small.png',
            width: 92,
            height: 39.4,
          ),
          Positioned(
            left: 42.w,
            top: 30.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/cloud_small.png',
              width: 82,
              height: 35.1,
            ),
          ),
          Positioned(
            left: -16.w,
            top: 62.h,
            child: const _WeatherSprite(
              asset: 'assets/sprites/cloud_small.png',
              width: 104,
              height: 44.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StormStationAccent extends StatelessWidget {
  const _StormStationAccent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _WeatherSprite(
          asset: 'assets/sprites/cloud_small.png',
          width: 100,
          height: 42.9,
        ),
        Positioned(
          left: 14.w,
          top: 54.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/block_question_f0.png',
            width: 28,
            height: 28,
          ),
        ),
        Positioned(
          left: 52.w,
          top: 42.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 20,
            height: 28,
          ),
        ),
        Positioned(
          left: 84.w,
          top: 54.h,
          child: const _WeatherSprite(
            asset: 'assets/sprites/block_question_f1.png',
            width: 28,
            height: 28,
          ),
        ),
      ],
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
