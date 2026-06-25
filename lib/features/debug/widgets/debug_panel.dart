import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_controller.dart';
import '../../notifications/models/notification_severity.dart';
import '../../notifications/providers/notification_queue_provider.dart';

/// Debug Panel（右下角隐蔽调试入口）
///
/// 默认是一个半透明极小的齿轮图标。点击展开 4 个 Test 按钮 + 主题开关。
/// 再次点击齿轮或点击外部可收起。
///
/// 用于在没有后端的情况下触发 4 个严重度的消息动画演出。
class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _test(NotificationSeverity severity) {
    ref.read(notificationQueueProvider.notifier).enqueueSeverity(severity);
  }

  void _toggleTheme(bool isDark) {
    ref.read(themeModeProvider.notifier).state =
        isDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    // 直接读 MaterialApp 的 ThemeData brightness，自动响应系统 + 手动切换
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 12.w,
      bottom: 12.h,
      child: _expanded ? _buildExpanded(isDark) : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    // 隐蔽但可点击：透明的大点击区域 + 半透明小齿轮图标
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48.w, // 放大点击热区
        height: 48.w,
        child: Center(
          child: Opacity(
            opacity: 0.45, // 略微提亮，确保可见但仍隐蔽
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings, color: Colors.white, size: 18.sp),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(bool isDark) {
    // Material 祖先：Switch/TextButton 需要 Material widget 上层，
    // 但 DebugPanel 在 LayeredScaffold 之外（HomePage 的 Stack 里），
    // 所以这里自带一个透明 Material 避免运行时崩溃。
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _toggle, // 点外部空白收起
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 头部：标题 + 收起按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DEBUG',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _toggle,
                    child: Icon(Icons.close,
                        color: Colors.white70, size: 16.sp),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 4 个 Test 按钮
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildBtn(
                      'Test L1', () => _test(NotificationSeverity.severity1)),
                  _buildBtn(
                      'Test L2', () => _test(NotificationSeverity.severity2)),
                  _buildBtn(
                      'Test L3', () => _test(NotificationSeverity.severity3)),
                  _buildBtn(
                      'Test L4', () => _test(NotificationSeverity.severity4)),
                ],
              ),
              SizedBox(height: 12.h),
              // 主题开关
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.white70, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    isDark ? '黑夜' : '白天',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 44.w,
                    height: 24.h,
                    child: Switch(
                      value: isDark,
                      onChanged: _toggleTheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
