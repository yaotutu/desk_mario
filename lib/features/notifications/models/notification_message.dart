import 'package:flutter/foundation.dart';

import 'notification_severity.dart';

/// 单条消息（不可变值对象）
@immutable
class NotificationMessage {
  const NotificationMessage({required this.severity, this.text, this.id});

  /// 构造一条默认（Mock）消息
  ///
  /// id 用 `microsecondsSinceEpoch ^ (atomic 计数器)` 拼出准唯一值：
  /// - 避免全局可变 `_seq++` 在测试间共享导致 id 撞车
  /// - 避免 Dart `DateTime.now()` 在快进时精度不足
  factory NotificationMessage.defaults(NotificationSeverity severity) {
    return NotificationMessage(
      severity: severity,
      text: NotificationSeverity.defaultText[severity],
      id: DateTime.now().microsecondsSinceEpoch ^ _seq++,
    );
  }

  /// 显式指定 id 的构造（用于测试 / 已知 id 的场景）
  factory NotificationMessage.withId({
    required NotificationSeverity severity,
    required int id,
    String? text,
  }) {
    return NotificationMessage(severity: severity, text: text, id: id);
  }

  final NotificationSeverity severity;
  final String? text;

  /// 唯一 ID，用于 widget key 和动画重建
  final int? id;

  /// 显示文本（含 fallback）
  String get displayText => text?.isNotEmpty == true
      ? text!
      : NotificationSeverity.defaultText[severity]!;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationMessage &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          id == other.id;

  @override
  int get hashCode => severity.hashCode ^ (id ?? 0).hashCode;
}

/// 进程内单调递增计数器（用于 [NotificationMessage.defaults] id 生成）。
///
/// 用 `int` 顶层变量在 Dart 单线程模型下是安全的（不存在 race），
/// 但测试间会共享——同进程内多次 `NotificationMessage.defaults`
/// 调用 id 不会重复。改用 Provider 注入可让测试可重置，但当前规模下不必要。
int _seq = 0;
