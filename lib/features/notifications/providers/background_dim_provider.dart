import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity 4 强告警专用的"底层灰度+模糊"开关
///
/// 由 Severity4PauseAlert 在 initState 置 true、解除告警后置 false。
///
/// 实际视觉效果由 [LayeredScaffold] 监听后叠加 `_DimOverlay`（去色 +
/// 高斯模糊 + 40% 黑），作用于 L0~L3 + L-1 Atmosphere 的整张画面。
/// L4 Notification 文字（PAUSE / 解除告警）和 L5 DebugPanel **不**被
/// 覆盖，保持清晰彩色以保证可读性。
final backgroundDimProvider = StateProvider<bool>((ref) => false);

