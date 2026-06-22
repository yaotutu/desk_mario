import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app.dart';
import 'core/constants/design_size.dart';

/// 入口：强制横屏 + 全屏 + ScreenUtil 初始化 + Riverpod
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 强制横屏（仅允许 landscapeLeft + landscapeRight，禁用竖屏）
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 2. 全屏：隐藏状态栏 + 底部导航条（immersiveSticky 滑出后会自动收回）
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  runApp(
    ProviderScope(
      child: DeskMarioBootstrap(child: const DeskMarioApp()),
    ),
  );
}

/// ScreenUtil 包装（在本文件内做一层封装，便于全局统一 designSize）
///
/// 实际使用：runApp 外层包 ScreenUtilInit。
/// 这里把它放进 DeskMarioBootstrap 中间件做隔离。
class DeskMarioBootstrap extends StatelessWidget {
  const DeskMarioBootstrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(DesignSize.width, DesignSize.height),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => child!,
      child: child,
    );
  }
}
