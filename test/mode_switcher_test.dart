import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/core/constants/design_size.dart';
import 'package:desk_mario/features/creative_mode/providers/creative_mode_provider.dart';
import 'package:desk_mario/features/creative_mode/widgets/mode_switcher.dart';

Widget _wrapModeSwitcher(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: ScreenUtilInit(
      designSize: const Size(DesignSize.width, DesignSize.height),
      minTextAdapt: true,
      builder: (context, child) => const MaterialApp(
        home: Scaffold(body: Stack(children: [ModeSwitcher()])),
      ),
    ),
  );
}

Future<void> _pumpModeSwitcher(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.view.physicalSize =
      const Size(DesignSize.width, DesignSize.height) * 2.0;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(_wrapModeSwitcher(container));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('collapsed mode switcher cycles manual creative modes', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpModeSwitcher(tester, container);

    expect(find.byKey(ModeSwitcher.collapsedKey), findsOneWidget);
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);

    await tester.tap(find.byKey(ModeSwitcher.collapsedKey));
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      container.read(creativeModeProvider).manualMode,
      CreativeMode.theater,
    );

    await tester.tap(find.byKey(ModeSwitcher.collapsedKey));
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      container.read(creativeModeProvider).manualMode,
      CreativeMode.diorama,
    );

    await tester.tap(find.byKey(ModeSwitcher.collapsedKey));
    await tester.pump(const Duration(milliseconds: 160));
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
  });

  testWidgets('long press expands choices and selecting Diorama collapses it', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpModeSwitcher(tester, container);

    await tester.longPress(find.byKey(ModeSwitcher.collapsedKey));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byKey(ModeSwitcher.expandedKey), findsOneWidget);
    expect(find.byKey(ModeSwitcher.sceneButtonKey), findsOneWidget);
    expect(find.byKey(ModeSwitcher.theaterButtonKey), findsOneWidget);
    expect(find.byKey(ModeSwitcher.dioramaButtonKey), findsOneWidget);

    await tester.tap(find.byKey(ModeSwitcher.dioramaButtonKey));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      container.read(creativeModeProvider).manualMode,
      CreativeMode.diorama,
    );
    expect(find.byKey(ModeSwitcher.expandedKey), findsNothing);
    expect(find.byKey(ModeSwitcher.collapsedKey), findsOneWidget);
  });
}
