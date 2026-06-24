import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/character/widgets/mario_widget.dart';
import '../../features/debug/widgets/debug_panel.dart';
import '../../features/hud/widgets/time_hud.dart';
import '../../features/notifications/providers/background_dim_provider.dart';
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
/// L0 (最底) → L1 → L2 → L3 → L-1 Atmosphere → [_DimOverlay*] → L4 Notification → L5 DebugPanel (最顶)
/// ```
/// 也就是说 [AtmosphericLayer] 的**语义层号**是 L-1（最底），但**渲染
/// Z-order**在 L4 之后；通过 [IgnorePointer] 确保它不影响 L5 DebugPanel
/// 的点击交互。
///
/// **L4 强告警的灰度+模糊（[_DimOverlay]）**：
/// 当 [backgroundDimProvider] 为 true 时（由 L4 PauseAlert 触发），在
/// L-1 Atmosphere 之上、L4 Notification 之下叠加一个 [_DimOverlay]，用
/// [ColorFiltered]（灰度矩阵）+ [BackdropFilter]（高斯模糊）+ 半透明黑
/// 让 L0~L3 + L-1 视觉上"凝固"，但 L4 PAUSE 文字和 L5 调试面板保持
/// 清晰彩色以保证可读性。
///
/// 关键约定：
/// - 每一层内部自行定位：L1~L5 的 widget 内部都用 Positioned 决定自己
///   在屏幕上的位置，LayeredScaffold 不干预，只负责决定叠放顺序。
/// - 可扩展点：未来加"角色血条"放 L3，"Boss 战敌人"放 L2，
///   "屏幕飘雪"放 L1（widget 内分远景/近景），"设置弹窗"放 L5。
class LayeredScaffold extends ConsumerWidget {
  const LayeredScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldDim = ref.watch(backgroundDimProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // L0 Background（视差背景 + 地面）
          const ScrollingWorld(),

          // L1 Weather（天气效果占位）
          const WeatherLayer(),

          // L2 Character（主角）
          const PositionedMario(),

          // L3 HUD（世界内信息层）
          const TimeHud(),

          // L-1 Atmosphere（语义最底，但渲染在 L4 之上才能覆盖所有层；
          // 自带 IgnorePointer，不影响 L5 DebugPanel 点击）
          const AtmosphericLayer(),

          // L4 DimOverlay（仅 L4 强告警期间存在；
          // 用灰度+模糊+暗化让 L0~L3 + L-1 凝固；
          // 不影响 L4 Notification 文字和 L5 DebugPanel）
          if (shouldDim) const _DimOverlay(),

          // L4 Notification（业务消息层；L4 触发时文字保持清晰彩色）
          const NotificationOverlay(),

          // L5 System（系统 UI：调试面板，必须在最顶）
          const DebugPanel(),
        ],
      ),
    );
  }
}

/// L4 强告警专用的灰度+模糊+暗化叠加层
///
/// 放在 L-1 Atmosphere 之上、L4 Notification 之下：
/// - 包 L0~L3 + L-1 的画面：把它们去色、模糊、再叠半透明黑
/// - 不包 L4 Notification：PAUSE 文字和解除告警按钮保持清晰彩色
/// - 不包 L5 DebugPanel：调试面板永远在最顶
///
/// 实现要点：
/// - [BackdropFilter] 模糊的是"它下方的画面"（不是它的子项），
///   所以必须**叠加**在所有被模糊的层之上，而不是包住它们。
/// - [ColorFiltered] 用 luminance 矩阵 (0.2126, 0.7152, 0.0722) 做去色。
///   矩阵最后一行 `[0, 0, 0, 1, 0]` 保留 alpha。
/// - 嵌套顺序（外→内）：[ColorFiltered] → [BackdropFilter] → [ColoredBox]
///   渲染时：下层彩色画面 → BackdropFilter 模糊 → ColoredBox 叠 40% 黑 →
///   ColorFiltered 对整体去色。
/// - [IgnorePointer] 确保 dim 期间不拦截任何点击（包括未来 L2 Mario
///   "点击跳跃"等交互）。
class _DimOverlay extends StatelessWidget {
  const _DimOverlay();

  @override
  Widget build(BuildContext context) {
    // BackdropFilter 不是 const 构造，所以整个子树不能 const。
    return IgnorePointer(
      child: ColorFiltered(
        // ITU-R BT.709 luminance（人类视觉对绿色最敏感）
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, // R
          0.2126, 0.7152, 0.0722, 0, 0, // G
          0.2126, 0.7152, 0.0722, 0, 0, // B
          0, 0, 0, 1, 0, // A（保留原 alpha）
        ]),
        child: SizedBox.expand(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            // 40% 黑色叠层：模糊后压暗，强化"凝固"感
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x66000000)),
            ),
          ),
        ),
      ),
    );
  }
}
