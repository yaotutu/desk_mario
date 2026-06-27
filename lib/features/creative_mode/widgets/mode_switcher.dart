import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/creative_mode_provider.dart';

/// L5 创意模式切换器。
///
/// 这个控件是给用户日常切换"看世界 / 看通知 / 看数据摆件"用的，不是
/// Debug 面板的一部分。它故意贴在右下角齿轮左侧：短按快速循环模式，
/// 长按展开三枚真实 sprite 选项。这样用户不用离开 Mario 世界，也不会
/// 出现传统 App 式的大块导航遮罩。
class ModeSwitcher extends ConsumerStatefulWidget {
  const ModeSwitcher({super.key});

  static const collapsedKey = ValueKey<String>(
    'creative-mode-switcher-collapsed',
  );
  static const expandedKey = ValueKey<String>(
    'creative-mode-switcher-expanded',
  );
  static const sceneButtonKey = ValueKey<String>('creative-mode-scene-button');
  static const theaterButtonKey = ValueKey<String>(
    'creative-mode-theater-button',
  );
  static const dioramaButtonKey = ValueKey<String>(
    'creative-mode-diorama-button',
  );

  @override
  ConsumerState<ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends ConsumerState<ModeSwitcher> {
  bool _expanded = false;

  void _cycleMode() {
    if (ref.read(creativeModeProvider).temporaryLocked) return;

    ref.read(creativeModeProvider.notifier).cycleManualMode();
    if (_expanded) setState(() => _expanded = false);
  }

  void _selectMode(CreativeMode mode) {
    if (ref.read(creativeModeProvider).temporaryLocked) {
      setState(() => _expanded = false);
      return;
    }

    ref.read(creativeModeProvider.notifier).setManualMode(mode);
    setState(() => _expanded = false);
  }

  void _openChoices() {
    if (ref.read(creativeModeProvider).temporaryLocked) return;

    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creativeModeProvider);

    return Positioned(
      right: 70.w,
      bottom: 12.h,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _expanded
              ? _ExpandedModeChoices(
                  key: ModeSwitcher.expandedKey,
                  state: state,
                  onSelect: _selectMode,
                )
              : _CollapsedModeButton(
                  key: ModeSwitcher.collapsedKey,
                  state: state,
                  onTap: _cycleMode,
                  onLongPress: _openChoices,
                ),
        ),
      ),
    );
  }
}

class _CollapsedModeButton extends StatelessWidget {
  const _CollapsedModeButton({
    super.key,
    required this.state,
    required this.onTap,
    required this.onLongPress,
  });

  final CreativeModeState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final mode = state.effectiveMode;

    return Tooltip(
      message: 'Mode ${mode.label}',
      child: Semantics(
        button: true,
        label: '创意模式 ${mode.label}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 50.w,
            height: 48.w,
            child: Center(
              child: _PixelModeShell(
                selected: true,
                temporary: state.isTemporary,
                child: Image.asset(
                  _ModeSprite.assetFor(mode),
                  width: 29.r,
                  height: 29.r,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedModeChoices extends StatelessWidget {
  const _ExpandedModeChoices({
    super.key,
    required this.state,
    required this.onSelect,
  });

  final CreativeModeState state;
  final ValueChanged<CreativeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChoice(
            key: ModeSwitcher.sceneButtonKey,
            mode: CreativeMode.scene,
            selected: state.manualMode == CreativeMode.scene,
            temporary:
                state.effectiveMode == CreativeMode.scene && state.isTemporary,
            onTap: onSelect,
          ),
          SizedBox(width: 6.w),
          _ModeChoice(
            key: ModeSwitcher.theaterButtonKey,
            mode: CreativeMode.theater,
            selected: state.manualMode == CreativeMode.theater,
            temporary:
                state.effectiveMode == CreativeMode.theater &&
                state.isTemporary,
            onTap: onSelect,
          ),
          SizedBox(width: 6.w),
          _ModeChoice(
            key: ModeSwitcher.dioramaButtonKey,
            mode: CreativeMode.diorama,
            selected: state.manualMode == CreativeMode.diorama,
            temporary:
                state.effectiveMode == CreativeMode.diorama &&
                state.isTemporary,
            onTap: onSelect,
          ),
        ],
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    super.key,
    required this.mode,
    required this.selected,
    required this.temporary,
    required this.onTap,
  });

  final CreativeMode mode;
  final bool selected;
  final bool temporary;
  final ValueChanged<CreativeMode> onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: mode.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: '选择 ${mode.label}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(mode),
          child: SizedBox(
            width: 46.w,
            height: 42.h,
            child: Center(
              child: _PixelModeShell(
                selected: selected,
                temporary: temporary,
                child: Image.asset(
                  _ModeSprite.assetFor(mode),
                  width: 27.r,
                  height: 27.r,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelModeShell extends StatelessWidget {
  const _PixelModeShell({
    required this.selected,
    required this.temporary,
    required this.child,
  });

  final bool selected;
  final bool temporary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      width: 38.r,
      height: 38.r,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: selected ? 0.62 : 0.44),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: temporary
              ? p.pauseText
              : selected
              ? p.hudText
              : Colors.white.withValues(alpha: 0.32),
          width: temporary ? 3 : 2,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: child),
          if (temporary)
            Positioned(
              right: 3.r,
              top: 3.r,
              child: Container(
                width: 6.r,
                height: 6.r,
                decoration: BoxDecoration(
                  color: p.pauseText,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSprite {
  const _ModeSprite._();

  static String assetFor(CreativeMode mode) => switch (mode) {
    CreativeMode.scene => 'assets/sprites/cloud_small.png',
    CreativeMode.theater => 'assets/sprites/block_question_f0.png',
    CreativeMode.diorama => 'assets/sprites/castle.png',
  };
}
