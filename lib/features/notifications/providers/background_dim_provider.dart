import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L4 强告警专用的"底层灰度模糊"开关
///
/// 仅作用于 Layer 1 & 2（背景 + 角色），由 Level4PauseAlert 控制。
/// Layer 3 时间 HUD 和 PAUSE 文字不受影响。
final backgroundDimProvider = StateProvider<bool>((ref) => false);
