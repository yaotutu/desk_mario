// 一次性 golden test：跑起来 + 截图，便于离线查看视觉效果
// 运行方式：flutter test test/screenshot_test.dart --update-goldens

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:desk_mario/app.dart';
import 'package:desk_mario/core/constants/design_size.dart';
import 'package:desk_mario/features/hud/providers/clock_provider.dart';
import 'package:desk_mario/features/weather/providers/weather_provider.dart';

final _goldenClockTime = DateTime(2026, 1, 1, 20, 35);
const _goldenImageAssets = [
  'assets/sprites/mario_big_run_f0.png',
  'assets/sprites/mario_big_run_f1.png',
  'assets/sprites/mario_big_run_f2.png',
  'assets/sprites/starman_f0.png',
  'assets/sprites/coin_f0.png',
  'assets/sprites/cloud_small.png',
  'assets/sprites/block_question_f0.png',
  'assets/sprites/block_question_f1.png',
  'assets/sprites/block_brick.png',
  'assets/sprites/flagpole.png',
  'assets/sprites/castle.png',
];

Future<void> _loadAppFonts() async {
  final loader = FontLoader(AppFonts.pixel)
    ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf'));
  await loader.load();
}

Future<void> _precacheGoldenImages(WidgetTester tester) async {
  final context = tester.element(find.byType(DeskMarioApp));

  await tester.runAsync(() async {
    for (final asset in _goldenImageAssets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
}

void main() {
  testWidgets('HomePage 完整场景渲染快照', (tester) async {
    await _loadAppFonts();

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
              (ref) =>
                  ClockNotifier(initialTime: _goldenClockTime, autoTick: false),
            ),
            weatherProvider.overrideWith(
              (ref) => const WeatherSnapshot(
                condition: WeatherCondition.rain,
                temperatureC: 18,
              ),
            ),
          ],
          child: const DeskMarioApp(),
        ),
      ),
    );

    await tester.pump();
    await _precacheGoldenImages(tester);

    // 关键：用 runAsync 让真实 IO（asset 解码、字体加载）完成
    await tester.runAsync(() async {
      // 等待所有图片资源解码完成
      await Future<void>.delayed(const Duration(milliseconds: 800));
    });

    // pump 几帧让 build 完成 + 动画初始化
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    // 与 golden 文件对比（首次运行加 --update-goldens 生成）
    await expectLater(
      find.byType(DeskMarioApp),
      matchesGoldenFile('goldens/home_page.png'),
    );
  });
}
