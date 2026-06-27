import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/notification_queue_provider.dart';

/// Severity 2：低侵入
///
/// 屏幕上方边缘使用 AnimatedContainer 向下弹出一个带边框的木牌，
/// 展示一行 Mock 文本，悬停 10 秒后收回边缘之外并自动出队下一条。
class Severity2SignBanner extends ConsumerStatefulWidget {
  const Severity2SignBanner({super.key, required this.text});

  final String text;

  @override
  ConsumerState<Severity2SignBanner> createState() =>
      _Severity2SignBannerState();
}

class _Severity2SignBannerState extends ConsumerState<Severity2SignBanner> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // 进入后下一帧弹出
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _expanded = true);
    });

    // 10 秒后收回；收回动画结束后再 complete
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _expanded = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        ref.read(notificationQueueProvider.notifier).completeCurrent();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final bannerHeight = 72.h;
    final hiddenTop = -bannerHeight - 8.h; // 藏到屏幕外
    final shownTop = 60.h; // 屏幕内位置

    return Positioned(
      top: _expanded ? shownTop : hiddenTop,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: p.signBg,
            border: Border.all(color: p.signBorder, width: 4),
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign, color: p.signText, size: 28.sp),
              SizedBox(width: 16.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600.w),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: p.signText,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 用 AnimatedContainer + 顶部位置条件切换实现弹出/收回动画，
// 等效于 AnimatedPositioned 但代码更简洁，且支持 easeOutBack 弹性曲线。
