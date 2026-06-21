import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/design_size.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/clock_provider.dart';

/// 顶部时间 HUD（Layer 3）
///
/// 显示 HH:MM（24小时制），粗体像素字体（Press Start 2P）。
/// Positioned 在屏幕顶部居中。
class TimeHud extends ConsumerWidget {
  const TimeHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final p = AppPalette.of(context);

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return Positioned(
      top: 16.h,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
            children: [
              // 阴影
              Text(
                '$hh:$mm',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 28.sp,
                  height: 1.4,
                  foreground: Paint()
                    ..color = p.hudShadow.withValues(alpha: 0.6)
                    ..style = PaintingStyle.fill
                    ..strokeWidth = 2
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
                ),
              ),
              // 主文字
              Text(
                '$hh:$mm',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 28.sp,
                  height: 1.4,
                  color: p.hudText,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
