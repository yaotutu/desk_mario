import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/design_size.dart';
import '../providers/clock_provider.dart';

/// HUD 变体枚举（v5：全 Mario 元素，无黑底 bar）
///
/// 用户明确反馈 v4 的"v2 黑底矩形"是割裂感来源，v5 三个变体全部：
/// - 移除 _HudTimeChip 黑底矩形
/// - 时间数字用白字+黑描边（Press Start 2P）模仿 SMB1 score 风格
/// - 信息直接画在 sprite 上/旁，让"摆件群"承载信息
///
/// 改 [_activeVariant] 切换，重 build/install。
enum HudVariant {
  /// A：单 ? 砖块承载时间（极简）
  a,

  /// A+：? 砖块承载时间 + Mario 元素装饰群（推荐）
  aPlus,

  /// B：角色合影摆件群 + 时间浮在头部上方（重桌搭）
  b,
}

/// 当前激活的变体（要切换直接改这里，重 build/install）
const HudVariant _activeVariant = HudVariant.b;

/// 时间字形用的"像素 sprite"——可切换对比效果
enum TimeSprite {
  questionBlock('assets/sprites/block_question_f0.png'),
  koopa('assets/sprites/koopa_f0.png'),
  goomba('assets/sprites/goomba_f0.png'),
  mushroom('assets/sprites/mushroom.png'),
  starman('assets/sprites/starman_f0.png'),
  marioSmall('assets/sprites/mario_small_stand.png'),
  brick('assets/sprites/block_brick.png'),
  brickBlue('assets/sprites/block_brick_underground.png');

  const TimeSprite(this.path);
  final String path;
}

/// 当前激活的 sprite（要切换直接改这里，重 build/install）
const TimeSprite _activeSprite = TimeSprite.brickBlue;

/// 顶部时间 HUD（Layer 3）
///
/// v5 重构（2026-06-25）：
/// - v4 → v5：移除所有黑底矩形 chip；时间数字改为 SMB1 score 风格
///   （白字 + 黑色 2px 描边），直接画在 sprite 上/旁。
/// - 三个变体共用 _PixelTimeText / _SpinningCoin / _QuestionBlock。
///
/// 共同设计原则：
/// - 右上角区域（left: 760.w 起，top: 16.h），避开 Mario 跑动区（屏宽 1/3 ≈ 426）
/// - 无任何 Container/Box 背景装饰 —— 时间靠 sprite 和白字黑描边承担
/// - sprite 全部 FilterQuality.none + gaplessPlayback: true
class TimeHud extends ConsumerWidget {
  const TimeHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider);
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final timeText = '$hh:$mm';

    switch (_activeVariant) {
      case HudVariant.a:
        return _HudVariantA(timeText: timeText);
      case HudVariant.aPlus:
        return _HudVariantAPlus(timeText: timeText);
      case HudVariant.b:
        return _HudVariantB(timeText: timeText);
    }
  }
}

// ============================================================================
// 共享子 widget
// ============================================================================

/// SMB1 风格像素时间文字：白字 + 黑色 2px 描边
///
/// 用 Stack 叠 4 个方向的描边层（dx/dy = ±1）模拟 outline，
/// 避免 TextPainter outline 路径在低分辨率下被裁切。
class _PixelTimeText extends StatelessWidget {
  const _PixelTimeText({
    required this.text,
    this.fontSize = 14,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.pixel,
      fontSize: fontSize.sp,
      letterSpacing: 1,
      height: 1.0,
    );
    return Stack(
      children: [
        // 8 方向黑色描边（外圈）
        for (final dx in const [-1.5, 0.0, 1.5])
          for (final dy in const [-1.5, 0.0, 1.5])
            if (dx != 0.0 || dy != 0.0)
              Transform.translate(
                offset: Offset(dx, dy),
                child: Text(text, style: style.copyWith(color: const Color(0xFF000000))),
              ),
        // 顶层白字
        Text(text, style: style.copyWith(color: const Color(0xFFFFFFFF))),
      ],
    );
  }
}

/// 旋转金币（6 帧切换，600ms / 周期）
class _SpinningCoin extends StatefulWidget {
  const _SpinningCoin({required this.size});
  final double size;

  @override
  State<_SpinningCoin> createState() => _SpinningCoinState();
}

class _SpinningCoinState extends State<_SpinningCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final frame = (_controller.value * 6).floor() % 6;
        return Image.asset(
          'assets/sprites/coin_f$frame.png',
          width: widget.size,
          height: widget.size,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        );
      },
    );
  }
}

/// ? 砖块（6 帧循环，1.2s / 周期）
class _QuestionBlock extends StatefulWidget {
  const _QuestionBlock({required this.size});
  final double size;

  @override
  State<_QuestionBlock> createState() => _QuestionBlockState();
}

class _QuestionBlockState extends State<_QuestionBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final frame = (_controller.value * 6).floor() % 6;
        return Image.asset(
          'assets/sprites/block_question_f$frame.png',
          width: widget.size,
          height: widget.size,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
        );
      },
    );
  }
}

// ============================================================================
// Variant A：单 ? 砖块承载时间
// ============================================================================
//
// 视觉：
// ```
//                 [?]
//               10:30
// ```
// ? 砖块 48×48 静止动画（其实一直在闪烁），时间数字在砖块正下方居中。
class _HudVariantA extends StatelessWidget {
  const _HudVariantA({required this.timeText});
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24.w,
      top: 24.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _QuestionBlock(size: 64),
          const SizedBox(height: 6),
          _PixelTimeText(text: timeText, fontSize: 18),
        ],
      ),
    );
  }
}

// ============================================================================
// Variant A+：? 砖块承载时间 + Mario 元素装饰群
// ============================================================================
//
// 视觉：
// ```
//   [M]        [?]       [C][C]
//             10:30
//              [S]
// ```
// ? 砖块中央承载时间；
// 左侧 Mushroom（1-UP）；
// 右上 2 颗 Coin（旋转）；
// 下方 Small Mario Stand（看着 ? 砖块）。

class _HudVariantAPlus extends StatelessWidget {
  const _HudVariantAPlus({required this.timeText});
  final String timeText;

  @override
  Widget build(BuildContext context) {
    // Stack 边界用 clipBehavior: Clip.none 允许装饰精灵突出边界
    return Positioned(
      right: 40.w,
      top: 16.h,
      child: SizedBox(
        width: 200,
        height: 130,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 中央：? 砖块 + 时间
            const Positioned(
              left: 76,
              top: 4,
              child: _QuestionBlock(size: 48),
            ),
            Positioned(
              left: 84,
              top: 56,
              child: _PixelTimeText(text: timeText, fontSize: 14),
            ),
            // 左上：Mushroom
            const Positioned(
              left: 16,
              top: 0,
              child: Image(
                image: AssetImage('assets/sprites/mushroom.png'),
                width: 32,
                height: 32,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
            // 右上：Coin 1
            const Positioned(
              right: 0,
              top: 0,
              child: _SpinningCoin(size: 28),
            ),
            // 右上：Coin 2
            const Positioned(
              right: 32,
              top: 0,
              child: _SpinningCoin(size: 28),
            ),
            // 下方：Small Mario Stand
            const Positioned(
              left: 84,
              top: 76,
              child: Image(
                image: AssetImage('assets/sprites/mario_small_stand.png'),
                width: 32,
                height: 42,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Variant B：? 砖块群（思路 B / SMB1 经典）
// ============================================================================
//
// 视觉：
// ```
//   [?]    [?]    [?]
//        10:30
// ```
// - 3 个 ? 砖块横排（48×48，间距 12，6 帧闪烁动画）
// - 时间数字居中横跨 ? 砖块群下方（白字黑描边 Press Start 2P）
// - 总宽 168px、总高 ~70px
//
// 信息位预留（未来扩展）：
// - 第 1 个 ? 砖块下：时间（已实现）
// - 第 2 个 ? 砖块下：天气（等天气 sprite 资源到位）
// - 第 3 个 ? 砖块下：通知计数（复用现有 sprite 即可，比如 Mushroom=奖励通知）

class _HudVariantB extends StatelessWidget {
  const _HudVariantB({required this.timeText});
  final String timeText;

  // 5×7 像素字体（SMB1 NES score 数字字形，标准 8x8 简化版）
  // '#' = 实心像素，'.' = 空
  static const Map<String, List<String>> _glyphs = {
    '0': [
      '.###.',
      '#...#',
      '#...#',
      '#...#',
      '#...#',
      '#...#',
      '.###.',
    ],
    '1': [
      '..#..',
      '.##..',
      '..#..',
      '..#..',
      '..#..',
      '..#..',
      '.###.',
    ],
    '2': [
      '.###.',
      '#...#',
      '....#',
      '...#.',
      '..#..',
      '.#...',
      '#####',
    ],
    '3': [
      '.###.',
      '#...#',
      '....#',
      '..##.',
      '....#',
      '#...#',
      '.###.',
    ],
    '4': [
      '#...#',
      '#...#',
      '#...#',
      '#####',
      '....#',
      '....#',
      '....#',
    ],
    '5': [
      '#####',
      '#....',
      '#....',
      '####.',
      '....#',
      '#...#',
      '.###.',
    ],
    '6': [
      '.###.',
      '#....',
      '#....',
      '####.',
      '#...#',
      '#...#',
      '.###.',
    ],
    '7': [
      '#####',
      '....#',
      '...#.',
      '..#..',
      '.#...',
      '.#...',
      '.#...',
    ],
    '8': [
      '.###.',
      '#...#',
      '#...#',
      '.###.',
      '#...#',
      '#...#',
      '.###.',
    ],
    '9': [
      '.###.',
      '#...#',
      '#...#',
      '.####',
      '....#',
      '....#',
      '.###.',
    ],
    ':': [
      '.....',
      '..#..',
      '..#..',
      '.....',
      '.....',
      '..#..',
      '..#..',
    ],
  };

  static const int _gw = 5; // glyph width (cols)
  static const int _gh = 7; // glyph height (rows)
  static const int _gap = 1; // 字间距（像素数）
  static const double _px = 20; // 每个像素渲染尺寸

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final totalCols = timeText.length * _gw + (timeText.length - 1) * _gap;
    final totalW = totalCols * _px;
    final totalH = _gh * _px;

    // 把 timeText 转成 sprite 像素位置列表
    final pixels = <Widget>[];
    for (int i = 0; i < timeText.length; i++) {
      final ch = timeText[i];
      final glyph = _glyphs[ch];
      if (glyph == null) continue;
      for (int r = 0; r < _gh; r++) {
        final row = glyph[r];
        for (int c = 0; c < _gw; c++) {
          if (c < row.length && row[c] == '#') {
            pixels.add(Positioned(
              left: (i * (_gw + _gap) + c) * _px,
              top: r * _px,
              child: Image.asset(
                _activeSprite.path,
                width: _px,
                height: _px,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
                fit: BoxFit.fill,
              ),
            ));
          }
        }
      }
    }

    return Positioned(
      // 水平居中
      left: (size.width - totalW) / 2,
      // 顶部 120（避开云朵轨道 y=50-130 的下半段）
      top: 120,
      child: SizedBox(
        width: totalW,
        height: totalH,
        child: Stack(clipBehavior: Clip.none, children: pixels),
      ),
    );
  }
}