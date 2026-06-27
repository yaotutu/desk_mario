import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/notification_queue_provider.dart';

/// Severity 1：极弱提醒
///
/// 屏幕右上角淡入一个极小图标，FadeTransition 呼吸闪烁，
/// 持续 5 秒后淡出并自动出队下一条消息。
class Severity1FadeIcon extends ConsumerStatefulWidget {
  const Severity1FadeIcon({super.key});

  @override
  ConsumerState<Severity1FadeIcon> createState() => _Severity1FadeIconState();
}

class _Severity1FadeIconState extends ConsumerState<Severity1FadeIcon>
    with TickerProviderStateMixin {
  late final AnimationController _lifeCtrl; // 生命周期 5s
  late final AnimationController _breathCtrl; // 呼吸闪烁
  late final Animation<double> _breath;

  static const Duration _totalLife = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    _lifeCtrl = AnimationController(vsync: this, duration: _totalLife)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 5 秒到，出队下一条
          ref.read(notificationQueueProvider.notifier).completeCurrent();
        }
      });

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _breath = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    // 500ms 后淡入完成开始呼吸，最后 500ms 淡出
    _lifeCtrl.forward();
  }

  @override
  void dispose() {
    _lifeCtrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    // 生命周期映射到淡入淡出（前 10% 淡入，后 10% 淡出）
    return Positioned(
      top: 24.h,
      right: 32.w,
      child: AnimatedBuilder(
        animation: _lifeCtrl,
        builder: (context, _) {
          final life = _lifeCtrl.value;
          double baseOpacity;
          if (life < 0.1) {
            baseOpacity = life / 0.1; // 淡入
          } else if (life > 0.9) {
            baseOpacity = (1 - life) / 0.1; // 淡出
          } else {
            baseOpacity = 1.0;
          }
          final opacity = baseOpacity * _breath.value;

          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: p.pauseText.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.pauseText.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications,
                color: Colors.black,
                size: 22.sp,
              ),
            ),
          );
        },
      ),
    );
  }
}
