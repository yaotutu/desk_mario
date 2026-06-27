import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/typewriter_text.dart';
import '../providers/notification_queue_provider.dart';

/// Severity 3：中等侵入
///
/// 屏幕底部平滑升起一个半透明深色对话框，
/// 打字机逐字显示文本，完成后停留 5 秒淡出并自动出队下一条。
class Severity3TypewriterDialog extends ConsumerStatefulWidget {
  const Severity3TypewriterDialog({super.key, required this.text});

  final String text;

  @override
  ConsumerState<Severity3TypewriterDialog> createState() =>
      _Severity3TypewriterDialogState();
}

class _Severity3TypewriterDialogState
    extends ConsumerState<Severity3TypewriterDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _riseCtrl;
  late final Animation<double> _rise;
  late final Animation<double> _opacity;

  bool _typed = false;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();

    _riseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rise = CurvedAnimation(parent: _riseCtrl, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_rise);

    // 升起
    _riseCtrl.forward();
  }

  void _onTyped() {
    setState(() => _typed = true);
    // 停留 5 秒后淡出
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _fadingOut = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        ref.read(notificationQueueProvider.notifier).completeCurrent();
      });
    });
  }

  @override
  void dispose() {
    _riseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final size = MediaQuery.sizeOf(context);

    // 屏幕底部升起，对话框占据底部约 22% 高度
    final dialogHeight = size.height * 0.22;
    final bottomOffset = dialogHeight * (1 - _rise.value);

    return Positioned(
      left: size.width * 0.10,
      right: size.width * 0.10,
      bottom: -bottomOffset,
      child: IgnorePointer(
        ignoring: _fadingOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _fadingOut ? 0.0 : _opacity.value,
          child: Container(
            height: dialogHeight,
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: p.dialogBg,
              border: Border.all(color: p.dialogBorder, width: 3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 角色名条
                Row(
                  children: [
                    Icon(Icons.face, color: p.dialogBorder, size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '向导',
                      style: TextStyle(
                        color: p.dialogBorder,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 打字机正文
                Flexible(
                  child: SingleChildScrollView(
                    child: TypewriterText(
                      text: widget.text,
                      perChar: const Duration(milliseconds: 50),
                      onComplete: _onTyped,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                // 打字完成后右下角闪烁的"继续"提示三角
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _typed ? 1.0 : 0.0,
                    child: Icon(
                      Icons.play_arrow,
                      color: p.dialogBorder,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
