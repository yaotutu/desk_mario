import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_message.dart';
import '../models/notification_severity.dart';

/// 消息队列状态
class NotificationQueueState {
  const NotificationQueueState({this.queue = const [], this.current});

  /// 待演出队列（FIFO）
  final List<NotificationMessage> queue;

  /// 当前正在演出的消息
  final NotificationMessage? current;

  /// 入队一条
  NotificationQueueState enqueue(NotificationMessage msg) {
    // 若当前没有正在演出的，直接作为 current
    if (current == null && queue.isEmpty) {
      return copyWith(current: msg);
    }
    // 否则排到队列尾部
    return copyWith(queue: [...queue, msg]);
  }

  /// 当前消息演出完成 → 出队下一条
  NotificationQueueState completeCurrent() {
    if (queue.isEmpty) {
      return const NotificationQueueState();
    }
    final next = queue.first;
    return NotificationQueueState(queue: queue.sublist(1), current: next);
  }

  NotificationQueueState copyWith({
    List<NotificationMessage>? queue,
    Object? current = _sentinel,
  }) {
    return NotificationQueueState(
      queue: queue ?? this.queue,
      current: identical(current, _sentinel)
          ? this.current
          : current as NotificationMessage?,
    );
  }
}

const Object _sentinel = Object();

/// 通知队列 Notifier
///
/// 串行处理：同一时刻只显示一条（current）。
/// 每个 widget 演完后调 [completeCurrent]，自动派发下一条。
class NotificationQueueNotifier extends StateNotifier<NotificationQueueState> {
  NotificationQueueNotifier() : super(const NotificationQueueState());

  /// 按严重度入队一条 Mock 消息
  void enqueueSeverity(NotificationSeverity severity) {
    state = state.enqueue(NotificationMessage.defaults(severity));
  }

  /// 入队自定义消息
  void enqueue(NotificationMessage msg) {
    state = state.enqueue(msg);
  }

  /// 当前消息演出完成
  void completeCurrent() {
    state = state.completeCurrent();
  }
}

/// 全局消息队列 Provider
final notificationQueueProvider =
    StateNotifierProvider<NotificationQueueNotifier, NotificationQueueState>(
      (ref) => NotificationQueueNotifier(),
    );
