# DeskMario

> 基于 Flutter 的桌面氛围看板 —— 一个"主角永远在向前跑"的横版卷轴摆件应用。

DeskMario 是一个 16:9 强制横屏 + 全屏 immersive 的桌面摆件（kiosk-style）应用，
以 Super Mario Bros NES 真实像素 sprite 为素材，用 6 层视差栈渲染出持续滚动的小世界。
适合挂在桌面、客厅屏或任何常亮屏幕上当装饰。

---

## ✨ 特性

- **6 层视差栈**：氛围滤镜 / 滚动世界 / 天气 / 主角 / HUD / 通知 / 调试面板，语义分层 + 精确 Z-order
- **整数比视差**：一个 60s `AnimationController` 驱动 background 走 1 panel、ground 走 5 tile（32:5）
- **Mario 像素动画**：独立原地跑步（360ms 帧切换）+ 上下浮动（180ms），水平定位于屏宽 1/3 视觉焦点
- **四级通知系统**：L1~L4 由弱到强，L4 强告警触发 `BackdropFilter` 灰度模糊让世界"凝固"
- **氛围色温**：`AtmosphericLayer` 全屏色温（昼夜）+ 边缘暗角，覆盖所有 sprite
- **像素艺术保真**：`FilterQuality.none` 关闭抗锯齿 + `gaplessPlayback` 平移无闪烁
- **Riverpod 状态管理 + ScreenUtil 屏幕适配**（设计基准 1280×720）

---

## 🚀 快速开始

### 环境要求

- Flutter SDK ≥ 3.12（Dart ≥ 3.12）
- 一台 Android 真机（项目以 YT3002 为基准调试）或 macOS desktop

### 运行

```bash
flutter pub get                     # 安装依赖
flutter run -d macos                # macOS desktop 调试（推荐）
# 或
flutter run -d <device-id>          # 真机 / 模拟器
```

### 常用命令

```bash
flutter analyze                                      # Lint + 静态分析
flutter test                                         # 全部测试
flutter test test/widget_test.dart                   # 单测某文件
flutter test test/interaction_test.dart              # 4 级通知 + 主题切换
flutter test test/screenshot_test.dart --update-goldens   # 重新生成 golden

python3 tools/process_panel1.py <in.png> <out.png>   # 替换 panel 1 顶部 32px 紫横条为棋盘格天空
```

> ⚠️ 测试中**禁止** `pumpAndSettle`（无限动画永不返回），用 `pump(Duration)` 代替。

---

## 🏗️ 架构概览

核心是 `lib/shared/widgets/layered_scaffold.dart` 中的 `LayeredScaffold`——一个 `Stack` 把 6 层
按"语义层级 → 渲染 Z-order"从底到顶叠加：

| 层   | 组件                  | 职责                                                |
|------|----------------------|-----------------------------------------------------|
| L-1  | `AtmosphericLayer`   | 全屏氛围：色温（昼夜）+ 边缘暗角（渲染在 L4 之上）  |
| L0   | `ScrollingWorld`     | 视差背景 + 地面砖块（共享滚动/尺寸）                |
| L1   | `WeatherLayer`       | 天气效果：雨/雪/雾/闪电（当前为占位）               |
| L2   | `PositionedMario`    | 主角 Mario（独立原地跑步 + 上下浮动）               |
| L3   | `TimeHud`            | 世界内 UI：顶部时间 HH:MM                           |
| L4   | `NotificationOverlay`| 业务消息：4 级弱提醒                                 |
| L5   | `DebugPanel`         | 系统 UI：右下角齿轮调试面板                         |

实际 children 渲染顺序：`L0 → L1 → L2 → L3 → L4 → [L-1 Atmosphere] → L5`（L-1 是全屏滤镜，必须渲染在 sprite 之上才不被遮住）。

**关键设计约束**：三个常量 `GroundLayer.tilesPerPanel=32`、`GroundRatio=0.12`、`ParallaxBackground.imageAspect=768/176`
通过 `((1-0.12) × 4.364) / 0.12 = 32` 精确绑定，**改一个必须同步改另外两个**。

---

## 📁 项目结构

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

---

## 🛠️ 技术栈

- **Flutter**（≥ 3.12）+ Dart
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) ^2.5.1 —— 状态管理
- [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil) ^5.9.3 —— 屏幕适配
- [`PressStart2P`](https://fonts.google.com/specimen/Press+Start+2P) —— 像素字体
- 自带 sprite 资源（Super Mario Bros NES 风格）

---

## 📚 文档导航

详细参考文档（按需查阅）位于 [`docs/`](docs/)：

| 文档 | 内容 |
|------|------|
| [docs/state-management.md](docs/state-management.md) | Riverpod provider / 屏幕适配 / 主题色 |
| [docs/notifications.md](docs/notifications.md) | 4 级消息行为 / 通知 bug |
| [docs/sprites.md](docs/sprites.md) | sprite 替换 / 图片规格 |
| [docs/design-principles.md](docs/design-principles.md) | 设计原则 / 完整陷阱清单 |
| [docs/roadmap.md](docs/roadmap.md) | 后续 Step 3~7 规划 + 优先级 |

AI 协作开发指引见 [AGENTS.md](AGENTS.md)（常驻加载，含真机验证流程、关键陷阱速查）。

---

## 🗺️ Roadmap

当前 v2 重构完成，6 层视差栈全部接入。后续重点（详见 [docs/roadmap.md](docs/roadmap.md)）：

- **Step 3** —— 完整 HUD（电量 / 通知数 / 番茄钟等）
- **Step 4** —— 键盘快捷键（1-4 触发通知、T 切主题）
- **Step 5** —— 接入真实通知源（飞书 / 系统 / API）
- **Step 6** —— ✅ L4 强告警的 `BackdropFilter` 灰度模糊（已完成）
- **Step 7** —— L1 WeatherLayer 接入真实天气（雨/雪/雾/闪电）

---

## ⚠️ 像素艺术注意事项

- `Image.asset` **必须** `filterQuality: FilterQuality.none`（不能抗锯齿）
- 平移动画设 `gaplessPlayback: true`（避免帧切换闪烁）
- 不新增未在 `pubspec.yaml` 声明的依赖（CI 会因版本不匹配失败）
