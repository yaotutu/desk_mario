# AGENTS.md

opencode / Claude Code 在本项目的开发指引。本文件**常驻加载**，只放每次任务都必需的信息。

详细参考性内容（按需查阅）见 [docs/](docs/)：

| 文档 | 何时查阅 |
|------|---------|
| [docs/state-management.md](docs/state-management.md) | 写新 Riverpod provider / 屏幕适配 / 主题色 |
| [docs/notifications.md](docs/notifications.md) | 调整 4 级消息行为 / 修通知 bug |
| [docs/sprites.md](docs/sprites.md) | 替换 sprite / 调整图片规格 |
| [docs/design-principles.md](docs/design-principles.md) | 设计原则 / 完整陷阱清单 |
| [docs/roadmap.md](docs/roadmap.md) | 后续 Step 3~7 规划 + 优先级 |

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

**设备信息**：YT3002，serial `1W11833968`，物理 800×1280（竖屏），DeskMario 强制横屏后 Flutter 内部旋转 90°，逻辑坐标 1280×800。

**典型流程**：
1. 改 `lib/` 代码
2. `$SCRIPT restart`（完全重启 app）
3. `sleep 3`（等 Flutter 渲染）
4. `$SCRIPT screenshot /tmp/after.png` → `Read /tmp/after.png` 视觉验证
5. 有问题就重复 1-4；通过才算本次改动完成

**踩坑提醒**：panel 1 是 60s 周期循环滚动，单张截图可能落在 panel 1 完全滚出屏幕的瞬间——多截几次确认。

---

## 项目概览

**DeskMario** — 基于 Flutter 的桌面氛围看板（横屏摆件应用，16:9 强制横屏 + 全屏 immersive）。以 Super Mario Bros NES 真实 sprite 为素材，做"主角永远在向前跑"的横版卷轴摆件。

当前阶段（v2 重构后）：6 层视差栈全部接入 `LayeredScaffold`。

## 常用命令

```bash
flutter run -d macos            # 运行（推荐 macOS desktop 调试）
flutter analyze                 # Lint + 静态分析
flutter test                    # 全部测试（注意：禁止 pumpAndSettle，用 pump(Duration)）
flutter test test/widget_test.dart        # 单测某文件
flutter test test/interaction_test.dart   # 4 级通知 + 主题切换
flutter test test/screenshot_test.dart --update-goldens  # 重新生成 golden

python3 tools/process_panel1.py <in.png> <out.png>  # 替换 panel 1 顶部 32px 紫横条为棋盘格天空

flutter pub get                 # 依赖安装 / 升级
```

## 目录结构（lib）

```
lib/
├── main.dart                       # 入口：强制横屏 + 全屏 + ScreenUtilInit + ProviderScope
├── app.dart                        # MaterialApp 根
├── core/                           # 全局基础设施
│   ├── constants/design_size.dart  # 设计基准 1280×720，AppFonts 像素字体
│   └── theme/                      # 主题调色板（语义化命名）
├── pages/home_page.dart            # 主页（直接挂 LayeredScaffold）
├── shared/widgets/                 # 跨 feature 复用的 widget
│   ├── layered_scaffold.dart       # 6 层 Stack 装配点
│   ├── scrolling_world.dart        # 滚动世界顶层 + ScrollingMetrics
│   ├── atmospheric_layer.dart      # L-1 全屏氛围
│   └── typewriter_text.dart        # 通用打字机
└── features/                       # 业务功能模块
    ├── parallax/widgets/           # L0 视差背景 + 地面
    ├── weather/widgets/            # L1 天气效果（占位）
    ├── character/widgets/          # L2 Mario 主角
    ├── hud/                        # L3 时间 HUD
    ├── notifications/              # L4 4 级消息系统
    └── debug/widgets/              # L5 Debug 面板
```

## 架构核心：6 层视差栈（v2 / 方案 A）

`LayeredScaffold` 用 `Stack` 把 6 层从底到顶叠加（**语义层级** → **渲染 Z-order**）：

| 层      | 组件                  | 职责                                              | Z-order |
|---------|----------------------|--------------------------------------------------|--------|
| L-1     | `AtmosphericLayer`   | 全屏氛围：色温（昼夜）+ 边缘暗角                  | L4 之后（特殊）|
| L0      | `ScrollingWorld`     | 视差背景 + 地面砖块（共享滚动/尺寸）               | 最底渲染 |
| L1      | `WeatherLayer`       | 天气效果：雨/雪/雾/闪电（widget 内分前后景）       | 早期为占位 |
| L2      | `PositionedMario`    | 主角 Mario（独立原地跑步 + 上下浮动）              |        |
| L3      | `TimeHud`            | 世界内 UI：顶部时间 HH:MM                          |        |
| L4      | `NotificationOverlay`| 业务消息：4 级弱提醒（L1~L4）                       |        |
| L5      | `DebugPanel`         | 系统 UI：右下角齿轮调试面板                        | 最顶渲染 |

**L-1 Atmosphere Z-order 反直觉**：Flutter `Stack` 渲染 children[0]（最底）→ children[N-1]（最顶）。Atmosphere 是"全屏滤镜"，必须渲染在 L0~L4 **之上**才能让色温覆盖所有 sprite，否则被不透明 sprite 完全遮住。实际 children 顺序：
```
L0 → L1 → L2 → L3 → L4 → [L-1 Atmosphere] → L5 DebugPanel
```
通过 `IgnorePointer` 确保不影响 L5 DebugPanel 点击。详见 [docs/design-principles.md §1](docs/design-principles.md#1-atmosphericlayer-z-order-反直觉)。

**关键设计（每次改都要知道）**：
- `ScrollingWorld` 持有**唯一** `AnimationController`（60s/周期），通过 `ScrollingMetrics` InheritedWidget 把尺寸暴露给 panel/ground 子层
- 整数比绑死 `tileWidth = panelWidth / 32`：三个常量 `GroundLayer.tilesPerPanel=32`、`GroundRatio=0.12`、`ParallaxBackground.imageAspect=768/176` 通过 `((1-0.12) × 4.364) / 0.12 = 32` 精确绑定，**改一个必须同步改另外两个**
- 视差比例 32:5，一个 controller 周期内 background 走 1 个 panel、ground 走 5 个 tile
- Mario 动画独立（自己的 AnimationController，帧切换 360ms + 上下浮动 180ms）
- Mario 水平定位：中心点 = 屏宽 / 3（经典横版游戏视觉焦点）

---

## 关键陷阱速查（简版）

完整版（带原因和解决方向）见 [docs/design-principles.md](docs/design-principles.md)。

- **`AtmosphericLayer` 必须渲染在 L4 之后**（否则被 sprite 完全遮住）
- **测试禁止 `pumpAndSettle`**（无限动画永远不返回，用 `pump(Duration)`）
- **`Image.asset` 必须 `filterQuality: FilterQuality.none`**（像素艺术不能抗锯齿），平移动画设 `gaplessPlayback: true`
- **调试面板 Switch 坐标**：横屏 1280×800 逻辑坐标下，齿轮 (1236, 756)，Switch (1234, 760)
- **不要新增未在 `pubspec.yaml` 声明的依赖**（CI 会因版本不匹配失败）

---

## 后续 Roadmap（简版）

详细 + 优先级见 [docs/roadmap.md](docs/roadmap.md)。

- **Step 3**：完整 HUD（电量/通知数等）
- **Step 4**：键盘快捷键（1-4 触发通知、T 切主题）
- **Step 5**：接入真实通知源
- **Step 6**：L4 强告警的 `BackdropFilter` 灰度模糊接到 `LayeredScaffold`
- **Step 7**：L1 WeatherLayer 接入 weatherProvider（雨/雪/雾/闪电）