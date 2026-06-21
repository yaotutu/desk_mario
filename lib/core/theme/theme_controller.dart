import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式 Provider（白天/黑夜）
///
/// 由 Debug Panel 的开关手动控制。默认跟随系统，但 Phase 1 阶段
/// Debug 面板可强制切到 light 或 dark 用于调试两套配色。
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // 默认跟系统（移动设备用户一般已经设好了偏好）
  return ThemeMode.system;
});

/// 强制白天模式（供 Debug 面板"切换为白天"按钮调用）
final isDarkModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeMode.system) {
    // Phase 1 阶段没法直接读系统，先默认 light，避免空指针
    return false;
  }
  return mode == ThemeMode.dark;
});
