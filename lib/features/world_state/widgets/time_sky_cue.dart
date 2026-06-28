import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/world_state_loop_provider.dart';

/// 天空中的时间相位提示。
///
/// 这不是传统时间文字，而是用现有真实 SMB raster sprite 表达一天中的
/// morning/day/dusk/night。它放在世界层上方、Mario 下方，作为场景气氛
/// 的一部分参与 Atmosphere 色温。
class TimeSkyCue extends ConsumerWidget {
  const TimeSkyCue({super.key});

  static const layerKey = ValueKey<String>('time-sky-cue-layer');
  static const morningCueKey = ValueKey<String>('time-cue-morning');
  static const dayCueKey = ValueKey<String>('time-cue-day');
  static const duskCueKey = ValueKey<String>('time-cue-dusk');
  static const nightCueKey = ValueKey<String>('time-cue-night');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(worldStateLoopProvider).timePhase;
    final cue = switch (phase) {
      WorldTimePhase.morning => const _MorningCue(),
      WorldTimePhase.day => const _DayCue(),
      WorldTimePhase.dusk => const _DuskCue(),
      WorldTimePhase.night => const _NightCue(),
    };

    return IgnorePointer(
      key: layerKey,
      child: Stack(fit: StackFit.expand, children: [cue]),
    );
  }
}

class _MorningCue extends StatelessWidget {
  const _MorningCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: TimeSkyCue.morningCueKey,
      right: 300.w,
      top: 152.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _TimeSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 34,
            height: 34,
          ),
          Positioned(
            left: 36.w,
            top: 8.h,
            child: const _TimeSprite(
              asset: 'assets/sprites/coin_f0.png',
              width: 18,
              height: 25.2,
            ),
          ),
          Positioned(
            left: 58.w,
            top: 28.h,
            child: const _TimeSprite(
              asset: 'assets/sprites/coin_f0.png',
              width: 14,
              height: 19.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCue extends StatelessWidget {
  const _DayCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: TimeSkyCue.dayCueKey,
      right: 292.w,
      top: 90.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _TimeSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 38,
            height: 38,
          ),
          SizedBox(width: 8.w),
          const _TimeSprite(
            asset: 'assets/sprites/coin_f0.png',
            width: 18,
            height: 25.2,
          ),
        ],
      ),
    );
  }
}

class _DuskCue extends StatelessWidget {
  const _DuskCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: TimeSkyCue.duskCueKey,
      right: 286.w,
      top: 164.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _TimeSprite(
            asset: 'assets/sprites/block_brick.png',
            width: 30,
            height: 30,
          ),
          SizedBox(width: 8.w),
          Transform.translate(
            offset: Offset(0, -18.h),
            child: const _TimeSprite(
              asset: 'assets/sprites/coin_f0.png',
              width: 24,
              height: 33.6,
            ),
          ),
          SizedBox(width: 8.w),
          const _TimeSprite(
            asset: 'assets/sprites/block_brick.png',
            width: 30,
            height: 30,
          ),
        ],
      ),
    );
  }
}

class _NightCue extends StatelessWidget {
  const _NightCue();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: TimeSkyCue.nightCueKey,
      right: 360.w,
      top: 112.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _TimeSprite(
            asset: 'assets/sprites/starman_f0.png',
            width: 20,
            height: 20,
          ),
          Positioned(
            left: 40.w,
            top: 18.h,
            child: const _TimeSprite(
              asset: 'assets/sprites/starman_f0.png',
              width: 14,
              height: 14,
            ),
          ),
          Positioned(
            left: 72.w,
            top: -8.h,
            child: const _TimeSprite(
              asset: 'assets/sprites/starman_f0.png',
              width: 16,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSprite extends StatelessWidget {
  const _TimeSprite({
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
