import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前时间 Provider（Layer 3 HUD 使用）
///
/// 每分钟 tick 一次，并对齐到下一个整分钟边界（避免打开后要等很久才刷新）。
/// 返回 DateTime，UI 层负责格式化为 HH:MM。
final clockProvider = StateNotifierProvider<ClockNotifier, DateTime>((ref) {
  return ClockNotifier();
});

class ClockNotifier extends StateNotifier<DateTime> {
  ClockNotifier() : super(DateTime.now()) {
    _scheduleNextMinute();
  }

  Timer? _timer;

  /// 计算到下一个整分钟的剩余秒数，定时刷新
  void _scheduleNextMinute() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
      0,
      0,
    );
    final delay = nextMinute.difference(now);
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    state = DateTime.now();
    _scheduleNextMinute(); // 继续安排下一次
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
