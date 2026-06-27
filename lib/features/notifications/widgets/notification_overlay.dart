import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../creative_mode/providers/creative_mode_provider.dart';
import '../models/notification_severity.dart';
import '../providers/notification_queue_provider.dart';
import 'severity1_fade_icon.dart';
import 'severity2_sign_banner.dart';
import 'severity3_typewriter_dialog.dart';
import 'severity4_pause_alert.dart';

/// Layer 4 消息提醒遮罩层
///
/// 监听 [notificationQueueProvider]，按当前消息的严重度派发对应 widget。
/// 串行：同一时刻只渲染 [current] 一条消息的 widget。
///
/// **注意**：每个 severity widget 内部自己负责出队（调
/// `notificationQueueProvider.completeCurrent()`），调用方不需要传
/// `onComplete` 回调。
class NotificationOverlay extends ConsumerWidget {
  const NotificationOverlay({super.key});

  static const theaterIdleHintKey = ValueKey<String>(
    'notification-theater-idle-hint',
  );
  static const theaterStageAccentKey = ValueKey<String>(
    'notification-theater-stage-accent',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationQueueProvider);
    final creativeMode = ref.watch(creativeModeProvider).effectiveMode;
    final current = state.current;

    if (current == null) {
      if (creativeMode == CreativeMode.theater) {
        return const Stack(
          fit: StackFit.expand,
          children: [_TheaterIdleHint()],
        );
      }

      return const SizedBox.shrink();
    }

    // 用 Stack 包裹：每个 severity widget 内部用 Positioned 定位，
    // 所以需要一个直接 Stack 父级（Positioned 不能放在 SizedBox 里）。
    // key 用消息 id，确保每条消息切换时 widget 重新创建、动画重新播放。
    return Stack(
      key: ValueKey('notif-${current.id ?? current.severity.index}'),
      fit: StackFit.expand,
      children: [
        if (creativeMode == CreativeMode.theater) const _TheaterStageAccent(),
        _buildBySeverity(current.severity, current.displayText),
      ],
    );
  }

  Widget _buildBySeverity(NotificationSeverity severity, String text) {
    switch (severity) {
      case NotificationSeverity.severity1:
        return const Severity1FadeIcon();
      case NotificationSeverity.severity2:
        return Severity2SignBanner(text: text);
      case NotificationSeverity.severity3:
        return Severity3TypewriterDialog(text: text);
      case NotificationSeverity.severity4:
        return const Severity4PauseAlert();
    }
  }
}

/// Theater 模式的待命舞台提示。
///
/// 没有通知时只露出一小组真实砖块和金币，像关卡里等候被顶开的事件
/// 道具。它不使用面板或文字说明，避免把 Theater 做成另一张普通页面。
class _TheaterIdleHint extends StatelessWidget {
  const _TheaterIdleHint();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: NotificationOverlay.theaterIdleHintKey,
      right: 148.w,
      bottom: 94.h,
      child: IgnorePointer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _TheaterSprite(
              asset: 'assets/sprites/block_question_f0.png',
              width: 34,
              height: 34,
            ),
            SizedBox(width: 8.w),
            Transform.translate(
              offset: Offset(0, -18.h),
              child: const _TheaterSprite(
                asset: 'assets/sprites/coin_f0.png',
                width: 22,
                height: 30,
              ),
            ),
            SizedBox(width: 8.w),
            const _TheaterSprite(
              asset: 'assets/sprites/block_brick.png',
              width: 34,
              height: 34,
            ),
          ],
        ),
      ),
    );
  }
}

/// 活跃通知的 Theater 舞台点缀。
///
/// 这个层只负责把"消息正在演出"这件事 Mario 化；真正的 severity
/// 动画仍由原来的 S1-S4 widget 控制。点缀放在通知 widget 下方，不会压住
/// PAUSE、对话框或解除告警按钮。
class _TheaterStageAccent extends StatelessWidget {
  const _TheaterStageAccent();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: NotificationOverlay.theaterStageAccentKey,
      top: 118.h,
      right: 128.w,
      child: IgnorePointer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TheaterSprite(
              asset: 'assets/sprites/block_question_f0.png',
              width: 30,
              height: 30,
            ),
            SizedBox(width: 7.w),
            Transform.translate(
              offset: Offset(0, -16.h),
              child: const _TheaterSprite(
                asset: 'assets/sprites/coin_f0.png',
                width: 20,
                height: 28,
              ),
            ),
            SizedBox(width: 7.w),
            const _TheaterSprite(
              asset: 'assets/sprites/block_question_f1.png',
              width: 30,
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _TheaterSprite extends StatelessWidget {
  const _TheaterSprite({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width.w,
      height: height.h,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      fit: BoxFit.contain,
    );
  }
}
