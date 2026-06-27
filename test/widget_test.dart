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
import 'package:desk_mario/features/hud/widgets/time_hud.dart';

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
}
