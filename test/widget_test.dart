// DeskMario 基础冒烟测试
//
// Phase 1 阶段：验证主页面能渲染、核心图层存在。
// 后续每个 feature 可独立补充单元/组件测试。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/app.dart';
import 'package:desk_mario/core/constants/design_size.dart';
import 'package:desk_mario/features/creative_mode/providers/creative_mode_provider.dart';
import 'package:desk_mario/features/creative_mode/widgets/mode_switcher.dart';
import 'package:desk_mario/features/hud/providers/clock_provider.dart';
import 'package:desk_mario/features/hud/widgets/time_hud.dart';
import 'package:desk_mario/features/notifications/models/notification_severity.dart';
import 'package:desk_mario/features/notifications/providers/notification_queue_provider.dart';
import 'package:desk_mario/features/weather/providers/weather_provider.dart';
import 'package:desk_mario/shared/widgets/atmospheric_layer.dart';

const _dioramaWorldPropsKey = ValueKey<String>('diorama-world-props');
const _dioramaWeatherBlocksKey = ValueKey<String>(
  'diorama-world-weather-blocks',
);
const _dioramaMessageFlagKey = ValueKey<String>('diorama-world-message-flag');
const _dioramaTimeCastleKey = ValueKey<String>('diorama-world-time-castle');
const _oldHudDioramaPropsKey = ValueKey<String>('world-hud-diorama-props');
const _weatherCueExpectations = <WeatherCondition, List<String>>{
  WeatherCondition.clear: [
    'weather-cue-clear',
    'assets/sprites/pipe_tall.png',
    'assets/sprites/starman_f0.png',
  ],
  WeatherCondition.rain: [
    'weather-cue-rain',
    'assets/sprites/pipe_tall.png',
    'assets/sprites/cloud_small.png',
  ],
  WeatherCondition.snow: [
    'weather-cue-snow',
    'assets/sprites/pipe_tall.png',
    'assets/sprites/cloud_small.png',
    'assets/sprites/starman_f0.png',
  ],
  WeatherCondition.fog: [
    'weather-cue-fog',
    'assets/sprites/pipe_tall.png',
    'assets/sprites/cloud_small.png',
  ],
  WeatherCondition.storm: [
    'weather-cue-storm',
    'assets/sprites/pipe_tall.png',
    'assets/sprites/block_question_f0.png',
    'assets/sprites/coin_f0.png',
  ],
};
final _timeCueExpectations = <DateTime, List<String>>{
  DateTime(2026, 1, 1, 6): [
    'time-cue-morning',
    'assets/sprites/starman_f0.png',
    'assets/sprites/coin_f0.png',
  ],
  DateTime(2026, 1, 1, 12): [
    'time-cue-day',
    'assets/sprites/starman_f0.png',
    'assets/sprites/coin_f0.png',
  ],
  DateTime(2026, 1, 1, 18): [
    'time-cue-dusk',
    'assets/sprites/coin_f0.png',
    'assets/sprites/block_brick.png',
  ],
  DateTime(2026, 1, 1, 23): ['time-cue-night', 'assets/sprites/starman_f0.png'],
};

Image _assetImageInDiorama(WidgetTester tester, String assetName) {
  return tester
      .widgetList<Image>(
        find.descendant(
          of: find.byKey(_dioramaWorldPropsKey),
          matching: find.byType(Image),
        ),
      )
      .firstWhere((image) {
        final provider = image.image;
        return provider is AssetImage && provider.assetName == assetName;
      });
}

void _expectAspectRatio(Image image, double ratio) {
  expect(image.width, isNotNull);
  expect(image.height, isNotNull);
  expect(image.width! / image.height!, closeTo(ratio, 0.02));
}

List<String> _assetNamesUnder(WidgetTester tester, Finder root) {
  return tester
      .widgetList<Image>(
        find.descendant(of: root, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((provider) => provider.assetName)
      .toList();
}

int _assetCountUnder(WidgetTester tester, Finder root, String assetName) {
  return _assetNamesUnder(
    tester,
    root,
  ).where((candidate) => candidate == assetName).length;
}

void main() {
  testWidgets('DeskMario app renders home page smoke test', (
    WidgetTester tester,
  ) async {
    // 模拟横屏尺寸（设计基准 1280x720）
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) => const ProviderScope(child: DeskMarioApp()),
      ),
    );
    // 不用 pumpAndSettle——视差背景和 Mario 浮动都是无限动画，
    // pumpAndSettle 永远不会返回。改用固定时长推进若干帧。
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // 顶部 NES HUD 应该存在，且不遮挡背景云层。
    expect(find.byKey(TimeHud.clockKey), findsOneWidget);
    expect(find.byKey(TimeHud.weatherKey), findsOneWidget);
    expect(find.byKey(TimeHud.statusKey), findsOneWidget);
    expect(find.byKey(TimeHud.weatherObjectKey), findsOneWidget);
    expect(find.byKey(TimeHud.statusObjectKey), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('weather-layer')), findsOneWidget);
    expect(find.byKey(AtmosphericLayer.temperatureOverlayKey), findsOneWidget);
    expect(find.byKey(AtmosphericLayer.vignetteOverlayKey), findsOneWidget);

    // L5 创意模式按钮应在 Debug 齿轮左侧常驻。
    expect(find.byKey(ModeSwitcher.collapsedKey), findsOneWidget);

    // 调试齿轮图标应存在（collapsed 状态）
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('top HUD keeps the left background cloud readable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) => const ProviderScope(child: DeskMarioApp()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getTopLeft(find.byKey(TimeHud.weatherKey)).dx,
      greaterThan(260),
      reason: 'weather HUD should not sit over the left SMB cloud cluster',
    );
  });

  testWidgets('HUD does not paint a full-width background mask', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) => const ProviderScope(child: DeskMarioApp()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(TimeHud),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('WeatherLayer renders real sprite cues for every weather state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (final entry in _weatherCueExpectations.entries) {
      final cueKey = ValueKey<String>(entry.value.first);
      final expectedAssets = entry.value.skip(1);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(DesignSize.width, DesignSize.height),
          minTextAdapt: true,
          builder: (context, child) => ProviderScope(
            key: ValueKey<String>('weather-${entry.key.name}'),
            overrides: [
              weatherProvider.overrideWith(
                (ref) =>
                    WeatherSnapshot(condition: entry.key, temperatureC: 18),
              ),
            ],
            child: const DeskMarioApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final cueFinder = find.byKey(cueKey);
      expect(cueFinder, findsOneWidget);
      final assetNames = _assetNamesUnder(tester, cueFinder);
      for (final asset in expectedAssets) {
        expect(assetNames, contains(asset));
      }
    }
  });

  testWidgets('TimeSkyCue renders real sprite cues for every time phase', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (final entry in _timeCueExpectations.entries) {
      final cueKey = ValueKey<String>(entry.value.first);
      final expectedAssets = entry.value.skip(1);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(DesignSize.width, DesignSize.height),
          minTextAdapt: true,
          builder: (context, child) => ProviderScope(
            key: ValueKey<String>('time-${entry.key.hour}'),
            overrides: [
              clockProvider.overrideWith(
                (ref) => ClockNotifier(initialTime: entry.key, autoTick: false),
              ),
            ],
            child: const DeskMarioApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final cueFinder = find.byKey(cueKey);
      expect(cueFinder, findsOneWidget);
      final assetNames = _assetNamesUnder(tester, cueFinder);
      for (final asset in expectedAssets) {
        expect(assetNames, contains(asset));
      }
    }
  });

  testWidgets('Diorama mode renders real prop-backed world objects', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) => ProviderScope(
          overrides: [
            clockProvider.overrideWith(
              (ref) => ClockNotifier(
                initialTime: DateTime(2026, 1, 1, 23, 5),
                autoTick: false,
              ),
            ),
            weatherProvider.overrideWith(
              (ref) => const WeatherSnapshot(
                condition: WeatherCondition.snow,
                temperatureC: -2,
              ),
            ),
            creativeModeProvider.overrideWith((ref) {
              return CreativeModeNotifier()
                ..setManualMode(CreativeMode.diorama);
            }),
          ],
          child: const DeskMarioApp(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(_oldHudDioramaPropsKey), findsNothing);
    expect(find.byKey(_dioramaWorldPropsKey), findsOneWidget);
    expect(find.byKey(_dioramaWeatherBlocksKey), findsOneWidget);
    expect(find.byKey(_dioramaMessageFlagKey), findsOneWidget);
    expect(find.byKey(_dioramaTimeCastleKey), findsOneWidget);
    expect(find.byKey(TimeHud.clockKey), findsNothing);
    expect(find.byKey(TimeHud.weatherKey), findsNothing);
    expect(find.byKey(TimeHud.statusKey), findsNothing);
    expect(find.text('23:05'), findsWidgets);
    expect(find.text('NIGHT'), findsWidgets);
    expect(find.text('SNOW -2C'), findsWidgets);

    final weatherBlocks = tester
        .widgetList<Image>(
          find.descendant(
            of: find.byKey(_dioramaWeatherBlocksKey),
            matching: find.byType(Image),
          ),
        )
        .where((image) {
          final provider = image.image;
          return provider is AssetImage &&
              (provider.assetName == 'assets/sprites/block_question_f0.png' ||
                  provider.assetName == 'assets/sprites/block_brick.png' ||
                  provider.assetName == 'assets/sprites/cloud_small.png');
        });
    expect(weatherBlocks.length, greaterThanOrEqualTo(3));
    expect(
      tester
          .widgetList<Image>(
            find.descendant(
              of: find.byKey(_dioramaWorldPropsKey),
              matching: find.byType(Image),
            ),
          )
          .any((image) {
            final provider = image.image;
            return provider is AssetImage &&
                provider.assetName == 'assets/sprites/pipe_tall.png';
          }),
      isFalse,
    );

    final castle = _assetImageInDiorama(tester, 'assets/sprites/castle.png');
    expect(castle.width, greaterThanOrEqualTo(84));
    expect(castle.height, greaterThanOrEqualTo(152));
    _expectAspectRatio(castle, 86 / 178);

    final coin = _assetImageInDiorama(tester, 'assets/sprites/coin_f0.png');
    expect(coin.width, greaterThanOrEqualTo(38));
    expect(coin.height, greaterThanOrEqualTo(52));
    _expectAspectRatio(coin, 10 / 14);

    expect(
      find.descendant(
        of: find.byType(TimeHud),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('Diorama message prop visualizes pending count as coins', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) => ProviderScope(
          overrides: [
            creativeModeProvider.overrideWith((ref) {
              return CreativeModeNotifier()
                ..setManualMode(CreativeMode.diorama);
            }),
            notificationQueueProvider.overrideWith((ref) {
              return NotificationQueueNotifier()
                ..enqueueSeverity(NotificationSeverity.severity1)
                ..enqueueSeverity(NotificationSeverity.severity1)
                ..enqueueSeverity(NotificationSeverity.severity1);
            }),
          ],
          child: const DeskMarioApp(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final messageFlag = find.byKey(_dioramaMessageFlagKey);
    expect(messageFlag, findsOneWidget);
    expect(find.text('x03'), findsWidgets);
    expect(
      _assetCountUnder(tester, messageFlag, 'assets/sprites/coin_f0.png'),
      3,
    );
  });
}
