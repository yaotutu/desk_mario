import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/design_size.dart';

/// 应用主题（白天 / 黑夜）
///
/// 所有图层颜色都从这里取，禁止在 widget 内硬编码颜色，
/// 这样切换主题时全部图层（背景/角色/HUD/消息）配色同步变化。
///
/// 颜色按"语义"命名（天空、山脉、草地、Mario、对话框等），
/// 而不是按"蓝色/绿色"，方便后期换色板时不破坏调用方。
class AppTheme {
  const AppTheme._();

  /// 白天主题
  static ThemeData light() => _build(Brightness.light, _LightPalette.instance);

  /// 黑夜主题
  static ThemeData dark() => _build(Brightness.dark, _DarkPalette.instance);

  static ThemeData _build(Brightness brightness, Palette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // 整个应用用像素字体作为默认字体（缺失的中文回退系统字体）
      fontFamily: AppFonts.pixel,
      fontFamilyFallback: AppFonts.fallback,
      scaffoldBackgroundColor: p.skyTop,
      textTheme: _buildTextTheme(brightness),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = Typography().englishLike;
    return base.copyWith(
      // 数字/HUD 大号像素字
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: AppFonts.pixel,
        letterSpacing: 2.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: AppFonts.pixel,
        letterSpacing: 1.5,
      ),
      // 中文对话框用系统加粗字体（不强制像素字体）
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: null,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: null,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// 语义化颜色调色板（白天）
class _LightPalette implements Palette {
  const _LightPalette();
  static const _LightPalette instance = _LightPalette();

  @override
  final Color seed = const Color(0xFF4CAF50);

  @override
  final Color skyTop = const Color(0xFF87CEEB); // 天空顶部（远）
  @override
  final Color skyBottom = const Color(0xFFB0E0E6); // 天空底部（近地平线）

  @override
  final Color mountainFar = const Color(0xFF81C784); // 远山（淡绿，SMB 草地风格）
  @override
  final Color mountainNear = const Color(0xFF4CAF50); // 近山（中绿）

  @override
  final Color grassTop = const Color(0xFF66BB6A); // 草地表面
  @override
  final Color grassBottom = const Color(0xFF388E3C); // 草地深处
  @override
  final Color grassDetail = const Color(0xFF2E7D32); // 小草点缀

  @override
  final Color marioBody = const Color(0xFFE53935); // Mario 红色
  @override
  final Color marioAccent = const Color(0xFF1E88E5); // 蓝色配饰

  @override
  final Color hudText = const Color(0xFFFFFFFF);
  @override
  final Color hudShadow = const Color(0xFF000000);

  @override
  final Color dialogBg = const Color(0xCC000000); // 半透明深色对话框
  @override
  final Color dialogBorder = const Color(0xFFFFC107);

  @override
  final Color signBg = const Color(0xFF8D6E63); // 木牌底色
  @override
  final Color signBorder = const Color(0xFF5D4037); // 木牌深色边框
  @override
  final Color signText = const Color(0xFFFFF8E1); // 木牌文字（暖白）

  @override
  final Color pauseText = const Color(0xFFFFEB3B); // PAUSE 黄色
  @override
  final Color alarmButton = const Color(0xFFE53935);
}

/// 语义化颜色调色板（黑夜）
class _DarkPalette implements Palette {
  const _DarkPalette();
  static const _DarkPalette instance = _DarkPalette();

  @override
  final Color seed = const Color(0xFF1A237E);

  @override
  final Color skyTop = const Color(0xFF0D1B3E); // 深夜蓝
  @override
  final Color skyBottom = const Color(0xFF1A2E5C); // 地平线偏紫蓝

  @override
  final Color mountainFar = const Color(0xFF2E7D32); // 远山（暗绿）
  @override
  final Color mountainNear = const Color(0xFF1B5E20); // 近山（深绿）

  @override
  final Color grassTop = const Color(0xFF2E4D2E);
  @override
  final Color grassBottom = const Color(0xFF1B3A1B);
  @override
  final Color grassDetail = const Color(0xFF143614);

  @override
  final Color marioBody = const Color(0xFFB71C1C);
  @override
  final Color marioAccent = const Color(0xFF0D47A1);

  @override
  final Color hudText = const Color(0xFFFFE082); // 夜间时间用暖黄
  @override
  final Color hudShadow = const Color(0xFF000000);

  @override
  final Color dialogBg = const Color(0xE6000000);
  @override
  final Color dialogBorder = const Color(0xFFFFC107);

  @override
  final Color signBg = const Color(0xFF4E342E);
  @override
  final Color signBorder = const Color(0xFF2E1A0F);
  @override
  final Color signText = const Color(0xFFFFE0B2);

  @override
  final Color pauseText = const Color(0xFFFFEB3B);
  @override
  final Color alarmButton = const Color(0xFFD32F2F);
}

/// 语义化颜色调色板抽象接口（公开类型，供 widget 用强类型访问）
abstract class Palette {
  Color get seed;

  // Layer 1: 背景
  Color get skyTop;
  Color get skyBottom;
  Color get mountainFar;
  Color get mountainNear;
  Color get grassTop;
  Color get grassBottom;
  Color get grassDetail;

  // Layer 2: 主角
  Color get marioBody;
  Color get marioAccent;

  // Layer 3: HUD
  Color get hudText;
  Color get hudShadow;

  // Layer 4: 消息系统
  Color get dialogBg;
  Color get dialogBorder;
  Color get signBg;
  Color get signBorder;
  Color get signText;
  Color get pauseText;
  Color get alarmButton;
}

/// 从 BuildContext 取当前主题的语义化颜色调色板。
///
/// 用法：`final p = AppPalette.of(context);` → `p.grassTop`
class AppPalette {
  const AppPalette._();

  static Palette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? _DarkPalette.instance
        : _LightPalette.instance;
  }
}

/// ScreenUtil 扩展：方便获取屏幕方向信息
extension ScreenUtilExt on ScreenUtil {
  bool get isLandscape => screenWidth > screenHeight;
}
