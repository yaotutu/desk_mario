// 一次性 golden test：跑起来 + 截图，便于离线查看视觉效果
// 运行方式：flutter test test/screenshot_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/app.dart';
import 'package:desk_mario/core/constants/design_size.dart';

void main() {
  testWidgets('HomePage 完整场景渲染快照', (tester) async {
    tester.view.physicalSize =
        const Size(DesignSize.width, DesignSize.height) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(DesignSize.width, DesignSize.height),
        minTextAdapt: true,
        builder: (context, child) =>
            const ProviderScope(child: DeskMarioApp()),
      ),
    );

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