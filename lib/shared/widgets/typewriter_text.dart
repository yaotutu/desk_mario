import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 通用打字机文字控件（Layer 3 对话框复用）
///
/// 固定速度逐字显示文本，不可点击跳过。
/// 完成后回调 [onComplete]。
///
/// 默认 50ms/字，可通过 [perChar] 自定义。
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.perChar = const Duration(milliseconds: 50),
    this.style,
    this.onComplete,
  });

  final String text;

  /// 每个字的停留时长
  final Duration perChar;

  /// 文字样式（不传则用 Theme 的 bodyLarge 加粗）
  final TextStyle? style;

  /// 完整显示后的回调
  final VoidCallback? onComplete;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.text.isEmpty) {
      // 空文本直接回调完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    } else {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.perChar, (timer) {
      if (_shown < widget.text.length) {
        setState(() => _shown++);
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 22.sp,
          height: 1.6,
          color: Colors.white,
        );

    // 当前显示的文本（substring 安全）
    final visible = widget.text.substring(
      0,
      _shown.clamp(0, widget.text.length),
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: visible, style: style),
          // 光标（一个闪烁的下划线，仅打字过程中显示）
          if (_shown < widget.text.length)
            TextSpan(
              text: '_',
              style: (style ?? const TextStyle()).copyWith(color: Colors.amber),
            ),
        ],
      ),
    );
  }
}
