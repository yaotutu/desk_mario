import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/models/notification_severity.dart';
import '../../notifications/providers/notification_queue_provider.dart';

/// DeskMario 创意模式。
///
/// 这不是页面路由，而是同一个横版世界的三种观察镜头：
/// Scene 保持氛围，Theater 强调通知演出，Diorama 把数据变成真实道具。
enum CreativeMode { scene, theater, diorama }

/// 临时模式覆盖的来源。
///
/// 当前只有通知系统会临时接管模式。后续如果加入闹钟、焦点计时等
/// 系统级事件，可以在这里新增来源而不覆盖用户的手动偏好。
enum CreativeModeTemporaryReason { notification }

extension CreativeModePresentation on CreativeMode {
  String get label => switch (this) {
    CreativeMode.scene => 'SCENE',
    CreativeMode.theater => 'THEATER',
    CreativeMode.diorama => 'DIORAMA',
  };

  CreativeMode get next => switch (this) {
    CreativeMode.scene => CreativeMode.theater,
    CreativeMode.theater => CreativeMode.diorama,
    CreativeMode.diorama => CreativeMode.scene,
  };
}

/// 创意模式状态。
///
/// [manualMode] 是用户长期偏好，[temporaryMode] 是系统短暂接管。最终
/// 渲染层只读 [effectiveMode]，这样 S3/S4 通知可以切到 Theater，又不会
/// 丢掉用户原本选中的 Scene 或 Diorama。
class CreativeModeState {
  const CreativeModeState({
    this.manualMode = CreativeMode.scene,
    this.temporaryMode,
    this.temporaryReason,
    this.temporaryLocked = false,
  });

  final CreativeMode manualMode;
  final CreativeMode? temporaryMode;
  final CreativeModeTemporaryReason? temporaryReason;
  final bool temporaryLocked;

  CreativeMode get effectiveMode => temporaryMode ?? manualMode;

  bool get isTemporary => temporaryMode != null;

  CreativeModeState copyWith({
    CreativeMode? manualMode,
    Object? temporaryMode = _sentinel,
    Object? temporaryReason = _sentinel,
    bool? temporaryLocked,
  }) {
    return CreativeModeState(
      manualMode: manualMode ?? this.manualMode,
      temporaryMode: identical(temporaryMode, _sentinel)
          ? this.temporaryMode
          : temporaryMode as CreativeMode?,
      temporaryReason: identical(temporaryReason, _sentinel)
          ? this.temporaryReason
          : temporaryReason as CreativeModeTemporaryReason?,
      temporaryLocked: temporaryLocked ?? this.temporaryLocked,
    );
  }
}

const Object _sentinel = Object();

class CreativeModeNotifier extends StateNotifier<CreativeModeState> {
  CreativeModeNotifier() : super(const CreativeModeState());

  void setManualMode(CreativeMode mode) {
    state = state.copyWith(manualMode: mode);
  }

  void cycleManualMode() {
    state = state.copyWith(manualMode: state.manualMode.next);
  }

  void enterTemporary(
    CreativeMode mode, {
    required CreativeModeTemporaryReason reason,
    bool locked = false,
  }) {
    state = state.copyWith(
      temporaryMode: mode,
      temporaryReason: reason,
      temporaryLocked: locked,
    );
  }

  void clearTemporary([CreativeModeTemporaryReason? reason]) {
    if (reason != null && state.temporaryReason != reason) return;

    state = state.copyWith(
      temporaryMode: null,
      temporaryReason: null,
      temporaryLocked: false,
    );
  }
}

final creativeModeProvider =
    StateNotifierProvider<CreativeModeNotifier, CreativeModeState>((ref) {
      final notifier = CreativeModeNotifier();

      ref.listen<NotificationQueueState>(notificationQueueProvider, (_, next) {
        final severity = next.current?.severity;

        switch (severity) {
          case NotificationSeverity.severity3:
            notifier.enterTemporary(
              CreativeMode.theater,
              reason: CreativeModeTemporaryReason.notification,
            );
          case NotificationSeverity.severity4:
            notifier.enterTemporary(
              CreativeMode.theater,
              reason: CreativeModeTemporaryReason.notification,
              locked: true,
            );
          case NotificationSeverity.severity1:
          case NotificationSeverity.severity2:
          case null:
            notifier.clearTemporary(CreativeModeTemporaryReason.notification);
        }
      });

      return notifier;
    });
