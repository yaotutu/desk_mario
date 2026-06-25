import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationQueueProvider);
    final current = state.current;

    if (current == null) {
      return const SizedBox.shrink();
    }

    // 用 Stack 包裹：每个 severity widget 内部用 Positioned 定位，
    // 所以需要一个直接 Stack 父级（Positioned 不能放在 SizedBox 里）。
    // key 用消息 id，确保每条消息切换时 widget 重新创建、动画重新播放。
    return Stack(
      key: ValueKey('notif-${current.id ?? current.severity.index}'),
      fit: StackFit.expand,
      children: [
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
