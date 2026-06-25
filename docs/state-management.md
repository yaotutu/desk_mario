# 状态管理 / 屏幕适配 / 主题

按需查阅：写新 Riverpod provider / 调整屏幕适配 / 调整主题色时看本文件。

---

## 状态管理（Riverpod）

全部用 `flutter_riverpod ^2.5.1`，主要有：

- `themeModeProvider`（StateProvider\<ThemeMode\>）：主题模式，默认 `ThemeMode.system`；想知道当前是否黑夜直接 `Theme.of(context).brightness`，不要单独搞一个 `isDarkProvider`
- `clockProvider`（StateNotifierProvider）：当前时间，对齐整分钟 tick
- `notificationQueueProvider`（StateNotifierProvider）：**串行消息队列**（FIFO），同时只显示一条 `current`，演完调 `completeCurrent()` 出队下一条
- `backgroundDimProvider`（StateProvider\<bool\>）：Severity 4 强告警专用灰度模糊开关

`LayeredScaffold` 当前已挂全部 6 层（v2 重构后）：Atmosphere / Background / Weather / Character / HUD / Notification / Debug panel。

---

## 屏幕适配（flutter_screenutil）

- 设计基准 **1280×720** 横屏（`lib/core/constants/design_size.dart`）
- 所有 UI 元素用 `.w / .h / .sp / .r` 扩展换算
- 入口在 `main.dart` 用 `DeskMarioBootstrap` 包裹 `ScreenUtilInit(designSize: DesignSize.size)`
- 测试时用 `tester.view.physicalSize = Size(DesignSize.width, DesignSize.height) * 2.0` + `devicePixelRatio = 2.0` 模拟横屏

---

## 主题与颜色

**所有图层颜色都从 `AppPalette.of(context)` 取，禁止在 widget 内硬编码 Color。**

调色板（`lib/core/theme/app_theme.dart`）按**语义**命名（`skyTop / mountainNear / marioBody / hudText / dialogBg` 等），不是颜色名。两套 `_LightPalette` / `_DarkPalette` 实现 `Palette` 抽象接口，通过 `Brightness` 切换。中文用系统字体（`fontFamily: null` + `FontWeight.bold`），英文/数字用 `AppFonts.pixel`（Press Start 2P）。