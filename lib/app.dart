import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'pages/home_page.dart';

/// MaterialApp 根 widget
///
/// 接入 [themeModeProvider]，主题由 Debug 面板手动切换。
class DeskMarioApp extends ConsumerWidget {
  const DeskMarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DeskMario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
