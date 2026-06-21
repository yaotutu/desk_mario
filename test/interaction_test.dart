// DeskMario 交互逻辑测试
//
// 验证 Debug Panel 触发的 4 级消息动画 + 主题切换的逻辑正确性。
// 不依赖真实渲染（用 dart 画布），通过 find/tap 断言元素出现/消失。
//
// 注意：视差背景和 Mario 浮动是无限动画，不能用 pumpAndSettle，
// 必须用 pump(Duration) 推进固定帧。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/app.dart';
import 'package:desk_mario/core/constants/design_size.dart';
import 'package:desk_mario/shared/widgets/typewriter_text.dart';

Widget _wrapApp() {
  return ScreenUtilInit(
    designSize: const Size(DesignSize.width, DesignSize.height),
    minTextAdapt: true,
    builder: (context, child) => const ProviderScope(child: DeskMarioApp()),
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize =
      const Size(DesignSize.width, DesignSize.height) * 2.0;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(_wrapApp());
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('DeskMario 初始渲染', () {
    testWidgets('显示时间 HUD 和调试齿轮', (tester) async {
      await _pumpApp(tester);

      // 时间 HUD（HH:MM，含冒号）
      expect(find.textContaining(':'), findsWidgets);
      // 调试齿轮（collapsed 状态）
      expect(find.byIcon(Icons.settings), findsOneWidget);
      // 未展开时没有 Test 按钮
      expect(find.text('Test L1'), findsNothing);
    });
  });

  group('Debug Panel 展开/收起', () {
    testWidgets('点击齿轮展开，显示 4 个 Test 按钮 + 主题开关', (tester) async {
      await _pumpApp(tester);

      // 展开前：无 Test 按钮
      expect(find.text('Test L1'), findsNothing);

      // 点击齿轮
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      // 展开后：4 个 Test 按钮都在
      expect(find.text('Test L1'), findsOneWidget);
      expect(find.text('Test L2'), findsOneWidget);
      expect(find.text('Test L3'), findsOneWidget);
      expect(find.text('Test L4'), findsOneWidget);
      // 主题开关（Switch）
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('消息队列串行', () {
    testWidgets('连续点击多个 Test，消息排队不重叠（同时只有一个 current）',
        (tester) async {
      await _pumpApp(tester);

      // 展开 debug
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      // 快速连续点击 L1, L2, L3
      await tester.tap(find.text('Test L1'));
      await tester.tap(find.text('Test L2'));
      await tester.tap(find.text('Test L3'));
      await tester.pump(const Duration(milliseconds: 300));

      // L1 的图标应出现（notifications bell）
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // L2 木牌此时还没出现（在队列里等）
      expect(find.byIcon(Icons.campaign), findsNothing);
    });
  });

  group('Level 1 弱提醒', () {
    testWidgets('点 Test L1 出现呼吸图标，5 秒后消失', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L1'));
      await tester.pump(const Duration(milliseconds: 500));

      // L1 图标出现
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      // 快进 6 秒（超过 5 秒生命周期）
      await tester.pump(const Duration(seconds: 6));

      // 图标消失
      expect(find.byIcon(Icons.notifications), findsNothing);
    });
  });

  group('Level 2 木牌', () {
    testWidgets('点 Test L2 木牌弹出，含 Mock 文本', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L2'));
      await tester.pump(const Duration(milliseconds: 600));

      // L2 木牌出现（campaign 图标 + 默认中文文本）
      expect(find.byIcon(Icons.campaign), findsOneWidget);
      expect(find.text('前方有新发现，请注意查看！'), findsOneWidget);

      // 让 L2 完整演完（10 秒停留 + 400ms 收回动画），避免 pending timer
      await tester.pump(const Duration(seconds: 11));
    });
  });

  group('Level 3 对话框 + 打字机', () {
    testWidgets('点 Test L3 底部对话框升起，含角色名和打字机正文', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L3'));
      await tester.pump(const Duration(milliseconds: 500));

      // 角色头像 + 名字出现
      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.text('向导'), findsOneWidget);

      // 打字机正在逐字显示（TypewriterText 用 RichText，500ms 后应已显示部分文字）
      expect(find.byType(TypewriterText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final span = richText.text.toPlainText();
      expect(span.length, lessThan('欢迎来到蘑菇王国！我是你的向导，有什么需要尽管告诉我。'.length));
      expect(span.isNotEmpty, true);

      // 让 L3 完整演完（打字 ~1.6s + 停留 5s + 淡出 0.3s）
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('打字完成后对话框进入停留期（play_arrow 出现且对话框仍在）',
        (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L3'));
      await tester.pump(const Duration(milliseconds: 500));

      // 打字中：对话框存在，play_arrow 尚未出现（_typed=false 不渲染）
      expect(find.byIcon(Icons.face), findsOneWidget);

      // 等打字完成（默认文本约 32 字 × 50ms ≈ 1.6 秒）
      await tester.pump(const Duration(seconds: 2));
      // 打字完成后：对话框仍在（进入 5 秒停留期），play_arrow 已渲染
      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // 让 L3 完整演完
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('Level 4 强告警', () {
    testWidgets('点 Test L4 出现 PAUSE 和解除告警按钮', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L4'));
      // L4 在 postFrame 里开 dim，需要一帧
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // PAUSE 巨型文字（主文字+阴影描边 = 2 个 Text）
      expect(find.text('PAUSE'), findsWidgets);
      // 解除告警按钮
      expect(find.text('解除告警'), findsOneWidget);
    });

    testWidgets('点解除告警后 PAUSE 消失', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Test L4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 点击解除告警
      await tester.tap(find.text('解除告警'));
      await tester.pump(const Duration(milliseconds: 500));

      // PAUSE 消失
      expect(find.text('PAUSE'), findsNothing);
    });
  });

  group('主题切换', () {
    testWidgets('点击 Switch 切换到黑夜主题', (tester) async {
      await _pumpApp(tester);

      // 初始亮度（默认 system → light）
      final initialBrightness = tester.firstWidget<MaterialApp>(
        find.byType(MaterialApp),
      ).theme!.brightness;
      expect(initialBrightness, Brightness.light);

      // 展开 debug
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 400));

      // 切换 Switch
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 400));

      // 主题变黑夜
      final darkTheme = tester.firstWidget<MaterialApp>(
        find.byType(MaterialApp),
      ).darkTheme!;
      final currentMode = tester.firstWidget<MaterialApp>(
        find.byType(MaterialApp),
      ).themeMode;
      expect(currentMode, ThemeMode.dark);
      expect(darkTheme.brightness, Brightness.dark);
    });
  });
}
