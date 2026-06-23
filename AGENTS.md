# AGENTS.md

opencode / Claude Code 在本项目的开发指引。本文件优先级高于全局配置，仅作用于当前仓库。

---

## 开发验证（安卓真机，强制）

**核心规则：所有开发最终都要测试，测试时必须用真机的运行截图进行查看。** 任何 UI / 动画 / 交互改动，都要在 YT3002 真机上跑一遍并截图确认，不能只靠 `flutter analyze` + `flutter test` 就算完事。

工具入口统一走 `.claude/skills/android-dev/scripts/adb.sh`（封装 adb，10 个高频子命令）：

```bash
SCRIPT=.claude/skills/android-dev/scripts/adb.sh

$SCRIPT screenshot /tmp/x.png    # 截图（默认 /tmp/adb_screen_<ts>.png）
$SCRIPT restart                  # force-stop + start，等 Flutter 首帧
$SCRIPT tap <x> <y>              # 点击（横屏后逻辑坐标 1280×800）
$SCRIPT swipe x1 y1 x2 y2 [ms]   # 滑动
$SCRIPT logcat                   # Flutter 日志（自动清 buffer）
$SCRIPT info                     # 设备 + 前台应用概览
```

**设备信息**：YT3002，serial `1W11833968`，物理 800×1280（竖屏），DeskMario 强制横屏后 Flutter 内部旋转 90°，逻辑坐标 1280×800（"屏幕右上角"≈物理 (1200, 760)）。

**典型流程**：
1. 改 `lib/` 代码
2. `$SCRIPT restart`（完全重启 app）
3. `sleep 3`（等 Flutter 渲染）
4. `$SCRIPT screenshot /tmp/after.png` → `Read /tmp/after.png` 视觉验证
5. 有问题就重复 1-4；通过才算本次改动完成

**踩坑提醒**：panel 1 是 60s 周期循环滚动，单张截图可能落在 panel 1 完全滚出屏幕的瞬间（背景只剩 skyBottom 纯色）——不要据此误判 panel 1 缺失，多截几次确认。

---

## 项目概览

**DeskMario** — 基于 Flutter 的桌面氛围看板（横屏摆件应用，16:9 强制横屏 + 全屏 immersive）。
以 Super Mario Bros NES 真实 sprite 为素材，做"主角永远在向前跑"的横版卷轴摆件。
当前阶段（v2 重构后）：6 层视差栈（Atmosphere / Background / Weather / Character / HUD / Notification / System），全部 widget 已接入 `LayeredScaffold`。

## 常用命令

```bash
# 运行应用（横屏摆件，推荐 macOS desktop 调试）
flutter run -d macos

# Lint + 静态分析
flutter analyze

# 运行测试（注意：视差 + Mario 是无限动画，禁止用 pumpAndSettle，用 pump(Duration)）
flutter test                              # 全部
flutter test test/widget_test.dart        # 单独
flutter test test/interaction_test.dart   # 4 级通知 + 主题切换
flutter test test/screenshot_test.dart --update-goldens  # 重新生成 golden

# 资源处理（替换 panel 1 顶部 32px 紫横条为棋盘格天空）
python3 tools/process_panel1.py <in.png> <out.png>
# 默认处理 assets/backgrounds/smb_background_overworld.png

# 依赖安装 / 升级
flutter pub get
```

## 目录结构（lib）

按 **feature-based + 分层** 划分，遵循"领域独立、UI 共用"原则。

```
lib/
├── main.dart                       # 入口：强制横屏 + 全屏 + ScreenUtilInit + ProviderScope
├── app.dart                        # MaterialApp 根，接 themeModeProvider
├── core/                           # 全局基础设施（无业务）
│   ├── constants/design_size.dart  # 设计基准 1280×720，AppFonts 像素字体常量
│   └── theme/                      # 主题调色板（语义化命名：skyTop/marioBody/hudText 等）
├── pages/home_page.dart            # 主页（直接挂 LayeredScaffold）
├── shared/widgets/                 # 跨 feature 复用的 widget
│   ├── layered_scaffold.dart       # 主页装配点（6 层 Stack 装配）
│   ├── scrolling_world.dart        # 滚动世界顶层 + ScrollingMetrics InheritedWidget
│   ├── atmospheric_layer.dart      # L-1 全屏氛围（色温 + 暗角）
│   └── typewriter_text.dart        # 通用打字机文字控件（Layer 3 对话框复用）
└── features/                       # 业务功能模块
    ├── parallax/widgets/           # L0 视差背景 + 地面
    ├── weather/widgets/            # L1 天气效果（当前占位）
    ├── character/widgets/          # L2 Mario 主角
    ├── hud/                        # L3 时间 HUD
    ├── notifications/              # L4 4 级消息系统
    └── debug/widgets/              # L5 Debug 面板（齿轮触发）
```

## 架构核心：6 层视差栈（v2 / 方案 A）

`LayeredScaffold` 用 `Stack` 把 6 层从底到顶叠加（**语义层级** → **渲染 Z-order**）：

| 层      | 组件                  | 职责                                              | 语义层 / Z-order |
|---------|----------------------|--------------------------------------------------|----------------|
| L-1     | `AtmosphericLayer`   | 全屏氛围：色温（昼夜）+ 边缘暗角                  | 语义最底，渲染在 L4 之后（v1 bug fix）|
| L0      | `ScrollingWorld`     | 视差背景 + 地面砖块（共享滚动/尺寸）               | 最底渲染       |
| L1      | `WeatherLayer`       | 天气效果：雨/雪/雾/闪电（widget 内部分前后景深度） | 早期为占位     |
| L2      | `PositionedMario`    | 主角 Mario（独立原地跑步 + 上下浮动）              |                 |
| L3      | `TimeHud`            | 世界内 UI：顶部时间 HH:MM                          |                 |
| L4      | `NotificationOverlay`| 业务消息：4 级弱提醒（L1~L4）                       |                 |
| L5      | `DebugPanel`         | 系统 UI：右下角齿轮调试面板（可点击触发 4 级通知） | 最顶渲染       |

**L-1 Atmosphere 的 Z-order 反直觉说明**：
Flutter `Stack` 渲染顺序是 children[0]（最底）→ children[N-1]（最顶）。
但 `AtmosphericLayer` 是"全屏滤镜"，必须渲染在 L0~L4 **之上**才能让色温覆盖到所有
sprite，否则会被不透明的 sprite 完全遮住。所以 children 实际顺序是：
```
L0 → L1 → L2 → L3 → L4 → [L-1 Atmosphere] → L5 DebugPanel
```
通过 `IgnorePointer` 确保 Atmosphere 不影响 L5 DebugPanel 的点击交互。

**关键设计：`ScrollingWorld` 顶层统一基础尺寸**

`ScrollingWorld` 是 L0 的容器，它做三件事：
1. 持有**唯一** `AnimationController`（60s/周期，`repeat()`）
2. 用 `LayoutBuilder` 统一算 `panelWidth/panelHeight/tileWidth/groundHeight`
3. 通过 `ScrollingMetrics`（InheritedWidget）把 `progress/尺寸` 暴露给两个子层

为什么要统一：原先 `ParallaxBackground` 和 `GroundLayer` 各算各的，缩放时屏宽变化导致 `floor(屏宽/tileWidth)` 不整除 → 末格 tile 没铺到 + 像素不对齐 → 抖动 + 右侧露出 sky。统一后两层完全同步。

**整数比绑定（重要！）：**
- `tileWidth = panelWidth / GroundLayer.tilesPerPanel`（整数比 1:32）
- `GroundLayer.tilesPerPanel = 32`、`GroundRatio = 0.12`、`ParallaxBackground.imageAspect = 768/176` 三者通过 `((1 - 0.12) × 4.364) / 0.12 = 32` 精确整数比绑死。**改其中任何一个必须同步改另外两个。**

**视差比例 = 32/5 = 6.4 倍远景慢**：一个 controller 周期内 background 走 1 个 panel，ground 走 5 个 tile，地面滚动 12s/tile。

**Mario 动画独立**：Mario 自己的 `AnimationController`（帧切换 360ms + 上下浮动 180ms），不参与 ScrollingWorld 的 controller，独立运行。

**Mario 水平定位**：Mario 中心点固定在屏宽 1/3 处（经典横版游戏视觉焦点），公式 `left = size.width / 3 - displayWidth / 2`。

## 状态管理（Riverpod）

全部用 `flutter_riverpod ^2.5.1`，主要有：

- `themeModeProvider`（StateProvider\<ThemeMode\>）：主题模式，默认 `ThemeMode.system`
- `isDarkModeProvider`（Provider\<bool\>）：从 themeMode 派生，供 Debug 面板 Switch + AtmosphericLayer 色温
- `clockProvider`（StateNotifierProvider）：当前时间，对齐整分钟 tick
- `notificationQueueProvider`（StateNotifierProvider）：**串行消息队列**（FIFO），同时只显示一条 `current`，演完调 `completeCurrent()` 出队下一条
- `backgroundDimProvider`（StateProvider\<bool\>）：L4 强告警专用灰度模糊开关

## 屏幕适配（flutter_screenutil）

- 设计基准 **1280×720** 横屏（`lib/core/constants/design_size.dart`）
- 所有 UI 元素用 `.w / .h / .sp / .r` 扩展换算
- 入口在 `main.dart` 用 `DeskMarioBootstrap` 包裹 `ScreenUtilInit(designSize: DesignSize.size)`
- 测试时用 `tester.view.physicalSize = Size(DesignSize.width, DesignSize.height) * 2.0` + `devicePixelRatio = 2.0` 模拟横屏

## 主题与颜色

**所有图层颜色都从 `AppPalette.of(context)` 取，禁止在 widget 内硬编码 Color。**

调色板（`lib/core/theme/app_theme.dart`）按**语义**命名（`skyTop / mountainNear / marioBody / hudText / dialogBg` 等），不是颜色名。两套 `_LightPalette` / `_DarkPalette` 实现 `Palette` 抽象接口，通过 `Brightness` 切换。中文用系统字体（`fontFamily: null` + `FontWeight.bold`），英文/数字用 `AppFonts.pixel`（Press Start 2P）。

## 消息通知系统（Layer 4）

**4 级弱提醒 + 串行队列**（同时只显示一条，演完才出队下一条）：

| Level | 组件 | 行为 |
|-------|------|------|
| L1 | `Level1FadeIcon` | 右上角图标 5s 呼吸闪烁（首尾各 10% 淡入淡出）|
| L2 | `Level2SignBanner` | 顶部木牌 AnimatedContainer 弹出，停留 10s 后收回 |
| L3 | `Level3TypewriterDialog` | 底部对话框升起 + `TypewriterText` 50ms/字，打完停留 5s 淡出 |
| L4 | `Level4PauseAlert` | 全屏 PAUSE 闪烁 + 解除告警按钮，**触发 backgroundDimProvider 让 L0 变灰度+模糊** |

Mock 文本在 `NotificationLevel.defaultText`（中文）。`NotificationOverlay` 监听 `notificationQueueProvider.current`，按 level 派发对应 widget（key 用消息 `id` 确保动画重新播放）。每个 widget 演完调 `ref.read(notificationQueueProvider.notifier).completeCurrent()`。

**L4 灰度模糊的实现**：`Level4PauseAlert.initState` 在 postFrameCallback 里把 `backgroundDimProvider` 置 `true`。后续 Step 6 会在 `LayeredScaffold` 监听该 provider，用 `ColorFiltered`（灰度）+ `BackdropFilter`（模糊）包裹 L0 子树。**当前代码该 provider 已被使用但 BackdropFilter 还没接到 `LayeredScaffold`**，需注意。

## Sprite 资源

所有 sprite 来自 sprite-resource SMB1 NES Overworld，全部走 `assets/`：

- `assets/backgrounds/smb_background_overworld.png` — Layer 1 远景（处理过的 panel 1）
- `assets/sprites/ground_tile.png` — Layer 2 地面砖块（从 World 1-1 sheet y=208..240/x=0..32 切出，32×32）
- `assets/sprites/mario_big_run_f{0,1,2}.png` + `mario_big_stand.png` — Mario 跑步 3 帧 + 站立（16×32 NES 原版，scale=4 放大到 64×128）
- `assets/fonts/PressStart2P-Regular.ttf` — 像素字体（family: `PixelFont`）

替换 Mario 变身状态只需改 `MarioWidget._runFrames` / `_standFrame` 数组指向新 PNG。

**重要**：所有 `Image.asset` 必须设 `filterQuality: FilterQuality.none`（避免像素被抗锯齿模糊掉），平移动画设 `gaplessPlayback: true`。

## 设计原则 / 约定

1. **详细中文注释**：每个 widget 顶部 dartdoc 写清楚"为什么这样做"（不仅是"做什么"），便于后续维护。
2. **InheritedWidget 而非 Provider 传滚动指标**：因为 `progress` 每帧变化，频繁触发 widget rebuild，InheritedWidget 比 Provider 监听开销小。
3. **`Stack + Positioned` 而非 `Row`** 铺水平 tile：背景 panel 拼接后总宽 ≈ 2×panelWidth，地面 34×tileWidth 都远超 totalWidth，Row 会触发 RenderFlex overflow assertion；Stack 子项超出后被外层 ClipRect 裁掉，不报错。
4. **整数比绑死 `tileWidth = panelWidth / tilesPerPanel`**：避免 float 除法 + `floor()` 导致的像素不对齐抖动。
5. **测试不能用 `pumpAndSettle`**：视差 + Mario 浮动都是无限动画，`pumpAndSettle` 永远不返回。统一用 `pump(Duration)` 推进固定帧数。
6. **Widget 复用**：`TypewriterText` 是通用打字机，未来 Level 3 之外也可以直接复用。
7. **层级单一职责**：6 层架构中每层只看名字就知道放什么，可扩展点遵循"按视觉深度 + 按职责语义"分层（如：角色血条放 L3、Boss 战敌人放 L2、屏幕飘雪放 L1、设置弹窗放 L5）。

## 后续 Roadmap

- **Step 3**：完整 HUD（除时间外，可能加电量/通知数等）
- **Step 4**：键盘快捷键（数字 1-4 触发通知、T 切主题）
- **Step 5**：接入真实通知源（当前 Debug 面板触发 Mock）
- **Step 6**：L4 强告警的 `BackdropFilter` 灰度模糊真正接到 `LayeredScaffold`
- **Step 7**：L1 WeatherLayer 接入 weatherProvider（雨/雪/雾/闪电/沙尘等场景效果）

## 已知陷阱

- `L4 background_dim` provider 写了但实际 BackdropFilter 还没挂到 `LayeredScaffold`，L4 触发后视觉上无灰度模糊（当前只有半透明遮罩），等 Step 6 补完。
- `Level3TypewriterDialog._onTyped` 用 `Future.delayed` 模拟停留 5s，销毁时未取消——如果在动画中 dispose widget 会触发 mounted 检查；现有测试通过 mounted 守卫已规避。
- `AtmosphericLayer` 必须渲染在 L4 之后（L-1 语义层 + L4 之后 Z-order），否则冷蓝色覆盖会被 L0~L4 不透明 sprite 完全遮住。
- 调试面板 Switch 位置在右下角约 (1234, 760)，`$SCRIPT tap` 坐标以此为准（横屏 1280×800 逻辑坐标）。
- 不要新增未在 `pubspec.yaml` 声明的依赖，CI 会因版本不匹配失败。