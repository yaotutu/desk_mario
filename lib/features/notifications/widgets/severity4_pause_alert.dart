import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/design_size.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/background_dim_provider.dart';
import '../providers/notification_queue_provider.dart';

/// Severity 4：强告警
///
/// 激活时：
/// 1. 通过 [backgroundDimProvider] 触发 [LayeredScaffold] 的 `_DimOverlay`
///    叠加层（去色 + 高斯模糊 + 40% 黑），让 L0~L3 + L-1 视觉上"凝固"
/// 2. 屏幕正中闪烁显示巨型 PAUSE 字样 + [解除告警] 按钮
///    （L4 文字和按钮本身**不**被 dim 覆盖，保持清晰彩色）
///
/// 点击 [解除告警] 后：
/// - 关闭 dim
/// - 出队下一条消息
class Severity4PauseAlert extends ConsumerStatefulWidget {
  const Severity4PauseAlert({super.key});

  @override
  ConsumerState<Severity4PauseAlert> createState() => _Severity4PauseAlertState();
}

class _Severity4PauseAlertState extends ConsumerState<Severity4PauseAlert>
    with TickerProviderStateMixin {
  late final AnimationController _blinkCtrl; // PAUSE 闪烁
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();

    // 打开底层灰度模糊
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundDimProvider.notifier).state = true;
    });

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _blink = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    // 关闭底层灰度模糊
    ref.read(backgroundDimProvider.notifier).state = false;
    // 出队下一条
    ref.read(notificationQueueProvider.notifier).completeCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Positioned.fill(
      child: Container(
        // 半透明遮罩：降到 0.35，让下层 ColorFiltered(灰度)+BackdropFilter(模糊) 效果透出来
        // （之前的 0.55 太深，把灰度效果压平了，背景看起来只是"变暗"而非"去色+模糊"）
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 巨型 PAUSE 闪烁
              AnimatedBuilder(
                animation: _blink,
                builder: (context, _) {
                  return Opacity(
                    opacity: _blink.value,
                    child: Stack(
                      children: [
                        // 阴影描边
                        Text(
                          'PAUSE',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 96.sp,
                            height: 1.2,
                            foreground: Paint()
                              ..color = Colors.black
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8,
                          ),
                        ),
                        // 主文字
                        Text(
                          'PAUSE',
                          style: TextStyle(
                            fontFamily: AppFonts.pixel,
                            fontSize: 96.sp,
                            height: 1.2,
                            color: p.pauseText,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 48.h),
              // 解除告警按钮
              TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  backgroundColor: p.alarmButton,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                    side: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: Text(
                  '解除告警',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
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
