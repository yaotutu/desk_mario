import 'package:flutter/material.dart';

import '../../features/character/widgets/mario_widget.dart';
import '../../features/debug/widgets/debug_panel.dart';
import '../../features/hud/widgets/time_hud.dart';
import '../../features/notifications/widgets/notification_overlay.dart';
import '../../features/weather/widgets/weather_layer.dart';
import '../widgets/scrolling_world.dart';
import 'atmospheric_layer.dart';

/// 主页装配点（6 层视差栈，按从底到顶的视觉叠加顺序）
///
/// 层级定义（v2 / 方案 A）：
///
/// | 层     | 组件                  | 职责                                        |
/// |--------|----------------------|-------------------------------------------|
/// | L-1    | [AtmosphericLayer]   | 全屏氛围：色温（昼夜）+ 边缘暗角            |
/// | L0     | [ScrollingWorld]     | 视差背景 + 地面砖块（共享滚动/尺寸）         |
/// | L1     | [WeatherLayer]       | 天气效果：雨/雪/雾/闪电（widget 内部分前后） |
/// | L2     | [PositionedMario]    | 主角 Mario（独立原地跑步 + 上下浮动）        |
/// | L3     | [TimeHud]            | 世界内 UI：顶部时间 HH:MM                   |
/// | L4     | [NotificationOverlay]| 业务消息：4 级弱提醒（L1~L4）               |
/// | L5     | [DebugPanel]         | 系统 UI：右下角齿轮调试面板                 |
///
/// **Z-order 实现细节（重要）**：
/// Flutter 的 [Stack] 渲染顺序是 children[0]（最底）→ children[N-1]（最顶）。
/// 但 [AtmosphericLayer] 是"全屏滤镜"，必须渲染在 L0~L4 **之上**才能
/// 让色温和暗角覆盖到所有 sprite，否则会被 L0~L4 的不透明 sprite 完全
/// 遮住（这是 v1 实现的 bug）。
///
/// 所以 children 的实际顺序是：
/// ```
/// L0 (最底) → L1 → L2 → L3 → L4 → L-1 Atmosphere → L5 DebugPanel (最顶)
/// ```
/// 也就是说 [AtmosphericLayer] 的**语义层号**是 L-1（最底），但**渲染
/// Z-order**在 L4 之后；通过 [IgnorePointer] 确保它不影响 L5 DebugPanel
/// 的点击交互。
///
/// 关键约定：
/// - 每一层内部自行定位：L1~L5 的 widget 内部都用 Positioned 决定自己
///   在屏幕上的位置，LayeredScaffold 不干预，只负责决定叠放顺序。
/// - 可扩展点：未来加"角色血条"放 L3，"Boss 战敌人"放 L2，
///   "屏幕飘雪"放 L1（widget 内分远景/近景），"设置弹窗"放 L5。
class LayeredScaffold extends StatelessWidget {
  const LayeredScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // L0 Background（视差背景 + 地面）
          ScrollingWorld(),

          // L1 Weather（天气效果占位）
          WeatherLayer(),

          // L2 Character（主角）
          PositionedMario(),

          // L3 HUD（世界内信息层）
          TimeHud(),

          // L4 Notification（业务消息层）
          NotificationOverlay(),

          // L-1 Atmosphere（语义最底，但渲染在 L4 之上才能覆盖所有层；
          // 自带 IgnorePointer，不影响 L5 DebugPanel 点击）
          AtmosphericLayer(),

          // L5 System（系统 UI：调试面板，必须在最顶）
          DebugPanel(),
        ],
      ),
    );
  }
}