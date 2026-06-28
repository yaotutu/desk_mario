import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/design_size.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_queue_provider.dart';
import '../../world_state/providers/world_state_loop_provider.dart';
import '../providers/clock_provider.dart';

/// 顶部时间 HUD（Layer 3）。
///
/// 采用 SMB1 顶部 HUD 式布局：左天气、中时间、右消息。HUD 只用像素
/// 文字和少量真实 sprite 图标做信息提示，不绘制整条背景，避免遮挡云层。
class TimeHud extends ConsumerWidget {
  const TimeHud({super.key});

  /// 测试和后续自动化视觉验证用的稳定锚点。
  static const clockKey = ValueKey<String>('time-hud');
  static const weatherKey = ValueKey<String>('world-hud-weather');
  static const statusKey = ValueKey<String>('world-hud-status');
  static const weatherObjectKey = ValueKey<String>('world-hud-weather-object');
  static const statusObjectKey = ValueKey<String>('world-hud-status-object');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final world = ref.watch(worldStateLoopProvider);
    final overrideTimePhase = ref.watch(worldTimePhaseOverrideProvider);
    if (world.dioramaDensity == DioramaDensity.inspectable) {
      return const IgnorePointer(child: SizedBox.shrink());
    }

    final displayTime = overrideTimePhase == null
        ? now
        : _debugDisplayTimeForPhase(now, overrideTimePhase);
    final weather = world.weather;
    final queueState = ref.watch(notificationQueueProvider);
    final pendingCount =
        queueState.queue.length + (queueState.current == null ? 0 : 1);

    final hh = displayTime.hour.toString().padLeft(2, '0');
    final mm = displayTime.minute.toString().padLeft(2, '0');
    final timeText = '$hh:$mm';
    final pendingLabel = 'x${pendingCount.toString().padLeft(2, '0')}';

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 300.w,
            top: 12.h,
            width: 240.w,
            child: _HudColumn(
              key: weatherKey,
              title: 'WEATHER',
              alignment: CrossAxisAlignment.start,
              value: _WeatherObjectHud(
                objectKey: weatherObjectKey,
                label: weather.displayText,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Semantics(
                key: clockKey,
                container: true,
                label: '当前时间 $timeText',
                child: _ClockHud(label: timeText),
              ),
            ),
          ),
          Positioned(
            right: 44.w,
            top: 12.h,
            width: 240.w,
            child: Align(
              alignment: Alignment.topRight,
              child: _HudColumn(
                key: statusKey,
                title: 'MSG',
                alignment: CrossAxisAlignment.end,
                value: _StatusObjectHud(
                  objectKey: statusObjectKey,
                  label: pendingLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _debugDisplayTimeForPhase(DateTime now, WorldTimePhase phase) {
  final hour = switch (phase) {
    WorldTimePhase.morning => 6,
    WorldTimePhase.day => 12,
    WorldTimePhase.dusk => 18,
    WorldTimePhase.night => 23,
  };

  return DateTime(now.year, now.month, now.day, hour);
}

class _HudColumn extends StatelessWidget {
  const _HudColumn({
    super.key,
    required this.title,
    required this.value,
    required this.alignment,
  });

  final String title;
  final Widget value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        _OutlinedPixelText(text: title, fontSize: 10),
        SizedBox(height: 5.h),
        value,
      ],
    );
  }
}

class _ClockHud extends StatelessWidget {
  const _ClockHud({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _OutlinedPixelText(text: 'TIME', fontSize: 10),
        SizedBox(height: 2.h),
        _OutlinedPixelText(text: label, fontSize: 36),
      ],
    );
  }
}

/// 紧凑天气 HUD。
class _WeatherObjectHud extends StatelessWidget {
  const _WeatherObjectHud({required this.objectKey, required this.label});

  final Key objectKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        key: objectKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/sprites/starman_f0.png',
            width: 23.r,
            height: 23.r,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 6.w),
          _OutlinedPixelText(text: label, fontSize: 12),
        ],
      ),
    );
  }
}

/// 紧凑消息计数 HUD。
class _StatusObjectHud extends StatelessWidget {
  const _StatusObjectHud({required this.objectKey, required this.label});

  final Key objectKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        key: objectKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutlinedPixelText(text: label, fontSize: 12),
          SizedBox(width: 6.w),
          Image.asset(
            'assets/sprites/coin_f0.png',
            width: 23.r,
            height: 23.r,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// SMB1 风格像素文字：当前 palette 的 HUD 色 + 黑色描边。
class _OutlinedPixelText extends StatelessWidget {
  const _OutlinedPixelText({required this.text, required this.fontSize});

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
