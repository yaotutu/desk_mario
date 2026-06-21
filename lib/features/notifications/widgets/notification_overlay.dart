import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_level.dart';
import '../providers/notification_queue_provider.dart';
import 'level1_fade_icon.dart';
import 'level2_sign_banner.dart';
import 'level3_typewriter_dialog.dart';
import 'level4_pause_alert.dart';

/// Layer 4 消息提醒遮罩层
///
/// 监听 [notificationQueueProvider]，按当前消息的 level 派发对应 widget。
/// 串行：同一时刻只渲染 [current] 一条消息的 widget。
class NotificationOverlay extends ConsumerWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationQueueProvider);
    final current = state.current;

    if (current == null) {
      return const SizedBox.shrink();
    }

    // 用 Stack 包裹：每个 level widget 内部用 Positioned 定位，
    // 所以需要一个直接 Stack 父级（Positioned 不能放在 SizedBox 里）。
    // key 用消息 id，确保每条消息切换时 widget 重新创建、动画重新播放。
    return Stack(
      key: ValueKey('notif-${current.id ?? current.level.index}'),
      fit: StackFit.expand,
      children: [
        _buildByLevel(current.level, current.displayText),
      ],
    );
  }

  Widget _buildByLevel(NotificationLevel level, String text) {
    switch (level) {
      case NotificationLevel.level1:
        return Level1FadeIcon(onComplete: () {});
      case NotificationLevel.level2:
        return Level2SignBanner(text: text, onComplete: () {});
      case NotificationLevel.level3:
        return Level3TypewriterDialog(text: text, onComplete: () {});
      case NotificationLevel.level4:
        return const Level4PauseAlert();
    }
  }
}
