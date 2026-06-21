import 'package:flutter/foundation.dart';

import 'notification_level.dart';

/// 单条消息（不可变值对象）
@immutable
class NotificationMessage {
  const NotificationMessage({
    required this.level,
    this.text,
    this.id,
  });

  factory NotificationMessage.defaults(NotificationLevel level) {
    return NotificationMessage(
      level: level,
      text: NotificationLevel.defaultText[level],
      id: _seq++,
    );
  }

  final NotificationLevel level;
  final String? text;

  /// 唯一 ID，用于 widget key 和动画重建
  final int? id;

  /// 显示文本（含 fallback）
  String get displayText =>
      text?.isNotEmpty == true ? text! : NotificationLevel.defaultText[level]!;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationMessage &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          id == other.id;

  @override
  int get hashCode => level.hashCode ^ (id ?? 0).hashCode;
}

int _seq = 0;
