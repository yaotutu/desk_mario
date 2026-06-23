import 'package:flutter/material.dart';

/// 天气效果层（L1 Weather，独立成层为后期天气系统预留位置）
///
/// 未来扩展点：
/// - 接 weatherProvider（雨/雪/雾/闪电/沙尘等状态），
///   根据状态在 Stack 内派发对应 weather widget。
/// - 单个 weather widget 内部可自行区分视觉深度：
///   比如雨可以同时有"远景雨"（在 Background 之上、Character 之下）
///   和"近景雨滴"（在 Character 之上、HUD 之下）。
///
/// 当前实现：纯透明占位，不影响视觉，等待接入 weatherProvider。
class WeatherLayer extends StatelessWidget {
  const WeatherLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // 故意 IgnorePointer：天气不应拦截用户点击（Debug 面板在更高层 L5 System）。
    return const IgnorePointer(
      child: SizedBox.expand(),
    );
  }
}