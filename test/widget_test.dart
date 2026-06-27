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
import 'package:desk_mario/features/weather/providers/weather_provider.dart';
import 'package:desk_mario/shared/widgets/atmospheric_layer.dart';

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

  testWidgets('Diorama mode renders real prop-backed HUD objects', (
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

    expect(find.byKey(TimeHud.dioramaPropsKey), findsOneWidget);
    expect(find.byKey(TimeHud.dioramaWeatherPipeKey), findsOneWidget);
    expect(find.byKey(TimeHud.dioramaMessageFlagKey), findsOneWidget);
    expect(find.byKey(TimeHud.dioramaTimeCastleKey), findsOneWidget);
    expect(find.text('NIGHT'), findsWidgets);
    expect(find.text('SNOW -2C'), findsWidgets);

    expect(
      find.descendant(
        of: find.byType(TimeHud),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });
}
