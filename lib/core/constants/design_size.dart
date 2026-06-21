import 'package:flutter/material.dart';

/// 设计基准尺寸（横屏 16:9）
///
/// 所有 UI 按 1280x720 设计，再通过 flutter_screenutil 按屏幕比例缩放。
/// 设计元素使用 `.w` / `.h` / `.sp` / `.r` 扩展做逻辑尺寸→像素换算。
class DesignSize {
  const DesignSize._();

  /// 设计基准宽度（横屏长边）
  static const double width = 1280.0;

  /// 设计基准高度（横屏短边）
  static const double height = 720.0;

  /// [ScreenUtilInit] 使用
  static const Size size = Size(width, height);
}

/// 字体 family 常量集中管理，避免散落的字符串拼写错误。
class AppFonts {
  const AppFonts._();

  /// 像素字体（Press Start 2P），用于英文/数字（HUD 时间、PAUSE 等）
  static const String pixel = 'PixelFont';

  /// 中文系统字体 fallback（加粗模拟像素感）
  /// 不指定 family 时 Flutter 自动用系统默认字体，这里仅作占位常量。
  static const String? cjk = null;

  /// 通用 fallback 链：像素字体优先，缺失字符（如中文）回退系统字体。
  static const List<String> fallback = [pixel];
}
