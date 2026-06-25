import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式 Provider（白天/黑夜）
///
/// 由 Debug Panel 的开关手动控制。默认 `ThemeMode.system`（跟随系统）。
/// 调试面板的 "黑夜/白天" 按钮会把这里改写成显式 mode。
///
/// 想知道当前是否黑夜，**直接用 `Theme.of(context).brightness`**，
/// 它会自动响应系统 + 手动切换，不用单独 `isDarkModeProvider`。
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // 默认跟系统（移动设备用户一般已经设好了偏好）
  return ThemeMode.system;
});
