import 'package:flutter/material.dart';

import '../shared/widgets/layered_scaffold.dart';

/// 主页（Step 1 简化版）
///
/// Step 1 阶段：只显示视差背景。键盘快捷键（数字 1-4 触发通知、T 切主题）
/// 在 Step 4 / Step 6 时再加回来。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LayeredScaffold();
  }
}
