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
  static const dioramaPropsKey = ValueKey<String>('world-hud-diorama-props');
  static const dioramaWeatherPipeKey = ValueKey<String>(
    'world-hud-diorama-weather-pipe',
  );
  static const dioramaMessageFlagKey = ValueKey<String>(
    'world-hud-diorama-message-flag',
  );
  static const dioramaTimeCastleKey = ValueKey<String>(
    'world-hud-diorama-time-castle',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final world = ref.watch(worldStateLoopProvider);
    final weather = world.weather;
    final queueState = ref.watch(notificationQueueProvider);
    final pendingCount =
        queueState.queue.length + (queueState.current == null ? 0 : 1);

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final timeText = '$hh:$mm';
    final pendingLabel = 'x${pendingCount.toString().padLeft(2, '0')}';

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(left: 44.w, top: 12.h, right: 44.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260.w,
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
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Semantics(
                        key: clockKey,
                        container: true,
                        label: '当前时间 $timeText',
                        child: _ClockHud(label: timeText),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260.w,
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
            ),
          ),

          if (world.dioramaDensity == DioramaDensity.inspectable)
            _DioramaDataProps(
              weatherLabel: weather.displayText,
              messageLabel: pendingLabel,
              timeLabel: world.timePhase.label,
            ),
        ],
      ),
    );
  }
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

/// Diorama 模式的数据道具组。
///
/// 只使用已经提取的真实 SMB raster 资产：管道承载天气，旗杆+金币承载
/// 消息数。它靠近地面但避开 Mario 的三分之一屏幕锚点，让信息像关卡
/// 道具一样长在世界里，而不是盖住云层的 App 卡片。
class _DioramaDataProps extends StatelessWidget {
  const _DioramaDataProps({
    required this.weatherLabel,
    required this.messageLabel,
    required this.timeLabel,
  });

  final String weatherLabel;
  final String messageLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: TimeHud.dioramaPropsKey,
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 44.w,
          bottom: 78.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PipeWeatherProp(label: weatherLabel),
              SizedBox(width: 24.w),
              _FlagMessageProp(label: messageLabel),
            ],
          ),
        ),
        Positioned(
          right: 210.w,
          bottom: 78.h,
          child: _TimeCastleProp(label: timeLabel),
        ),
      ],
    );
  }
}

class _PipeWeatherProp extends StatelessWidget {
  const _PipeWeatherProp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: TimeHud.dioramaWeatherPipeKey,
      width: 116.w,
      height: 126.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 84.h,
            child: _OutlinedPixelText(text: label, fontSize: 8),
          ),
          Positioned(
            bottom: 62.h,
            child: Image.asset(
              'assets/sprites/cloud_small.png',
              width: 66.w,
              height: 28.h,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/sprites/pipe_tall.png',
              width: 58.w,
              height: 78.h,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagMessageProp extends StatelessWidget {
  const _FlagMessageProp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: TimeHud.dioramaMessageFlagKey,
      width: 96.w,
      height: 146.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            left: 44.w,
            bottom: 0,
            child: Image.asset(
              'assets/sprites/flagpole.png',
              width: 18.w,
              height: 134.h,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 16.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/sprites/coin_f0.png',
                  width: 24.r,
                  height: 30.r,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 5.h),
                _OutlinedPixelText(text: label, fontSize: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCastleProp extends StatelessWidget {
  const _TimeCastleProp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: TimeHud.dioramaTimeCastleKey,
      width: 116.w,
      height: 112.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 84.h,
            child: _OutlinedPixelText(text: label, fontSize: 8),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/sprites/castle.png',
              width: 90.w,
              height: 80.h,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
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
