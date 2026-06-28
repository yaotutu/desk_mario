import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/design_size.dart';
import '../../../core/theme/app_theme.dart';
import '../../hud/providers/clock_provider.dart';
import '../../notifications/providers/notification_queue_provider.dart';
import '../../world_state/providers/world_state_loop_provider.dart';
import 'scrolling_world.dart';

/// Diorama 模式的数据摆件层。
///
/// 这层属于 L0 世界，而不是 L3 HUD：所有物件贴着地面出现，参与全屏
/// Atmosphere/告警滤镜，避免像 App 控件一样盖在云层和角色上。
class DioramaWorldProps extends ConsumerWidget {
  const DioramaWorldProps({super.key});

  static const propsKey = ValueKey<String>('diorama-world-props');
  static const weatherBlocksKey = ValueKey<String>(
    'diorama-world-weather-blocks',
  );
  static const messageFlagKey = ValueKey<String>('diorama-world-message-flag');
  static const timeCastleKey = ValueKey<String>('diorama-world-time-castle');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(worldStateLoopProvider);
    if (world.dioramaDensity != DioramaDensity.inspectable) {
      return const SizedBox.shrink();
    }

    final queueState = ref.watch(notificationQueueProvider);
    final now = ref.watch(clockProvider);
    final pendingCount =
        queueState.queue.length + (queueState.current == null ? 0 : 1);
    final pendingLabel = 'x${pendingCount.toString().padLeft(2, '0')}';
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final metrics = ScrollingMetrics.of(context);
    final scale = (metrics.totalHeight / DesignSize.height).clamp(0.92, 1.12);

    return IgnorePointer(
      key: propsKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 72.w,
            bottom: metrics.groundHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _WeatherBlockProp(
                  label: world.weather.displayText,
                  scale: scale,
                ),
                SizedBox(width: 30.w),
                _FlagMessageProp(label: pendingLabel, scale: scale),
              ],
            ),
          ),
          Positioned(
            right: 162.w,
            bottom: metrics.groundHeight,
            child: _TimeCastleProp(
              phaseLabel: world.timePhase.label,
              timeLabel: timeLabel,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherBlockProp extends StatelessWidget {
  const _WeatherBlockProp({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: DioramaWorldProps.weatherBlocksKey,
      width: 140 * scale,
      height: 176 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 140 * scale,
            child: _WorldPixelText(text: label, fontSize: 9),
          ),
          Positioned(
            bottom: 98 * scale,
            child: _Sprite(
              asset: 'assets/sprites/cloud_small.png',
              width: 84,
              height: 36,
              scale: scale,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Sprite(
                      asset: 'assets/sprites/block_question_f0.png',
                      width: 48,
                      height: 48,
                      scale: scale,
                    ),
                    _Sprite(
                      asset: 'assets/sprites/block_brick.png',
                      width: 48,
                      height: 48,
                      scale: scale,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Sprite(
                      asset: 'assets/sprites/block_brick.png',
                      width: 48,
                      height: 48,
                      scale: scale,
                    ),
                    _Sprite(
                      asset: 'assets/sprites/block_brick.png',
                      width: 48,
                      height: 48,
                      scale: scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagMessageProp extends StatelessWidget {
  const _FlagMessageProp({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: DioramaWorldProps.messageFlagKey,
      width: 112 * scale,
      height: 180 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            left: 62 * scale,
            bottom: 0,
            child: _Sprite(
              asset: 'assets/sprites/flagpole.png',
              width: 24,
              height: 178,
              scale: scale,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 22 * scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Sprite(
                  asset: 'assets/sprites/coin_f0.png',
                  width: 40,
                  height: 56,
                  scale: scale,
                ),
                SizedBox(height: 6 * scale),
                _WorldPixelText(text: label, fontSize: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCastleProp extends StatelessWidget {
  const _TimeCastleProp({
    required this.phaseLabel,
    required this.timeLabel,
    required this.scale,
  });

  final String phaseLabel;
  final String timeLabel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: DioramaWorldProps.timeCastleKey,
      width: 126 * scale,
      height: 206 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 180 * scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WorldPixelText(text: timeLabel, fontSize: 9),
                SizedBox(height: 6 * scale),
                _WorldPixelText(text: phaseLabel, fontSize: 7),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: _Sprite(
              asset: 'assets/sprites/castle.png',
              width: 86,
              height: 178,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sprite extends StatelessWidget {
  const _Sprite({
    required this.asset,
    required this.width,
    required this.height,
    required this.scale,
  });

  final String asset;
  final double width;
  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width * scale,
      height: height * scale,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      fit: BoxFit.contain,
    );
  }
}

class _WorldPixelText extends StatelessWidget {
  const _WorldPixelText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.pixel,
      fontSize: fontSize.sp,
      height: 1,
      letterSpacing: 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final offset in const [
          Offset(-1.5, 0),
          Offset(1.5, 0),
          Offset(0, -1.5),
          Offset(0, 1.5),
        ])
          Transform.translate(
            offset: offset,
            child: Text(text, style: style.copyWith(color: p.hudShadow)),
          ),
        Text(text, style: style.copyWith(color: p.hudText)),
      ],
    );
  }
}
