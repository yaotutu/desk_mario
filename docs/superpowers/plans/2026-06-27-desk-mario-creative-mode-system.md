# DeskMario Creative Mode System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first production slice of DeskMario's Scene, Theater, and Diorama creative modes with a bottom-right mode switcher, mode-aware HUD, real-asset Diorama props, and notification-driven temporary Theater focus.

**Architecture:** Add a focused `creative_mode` feature that owns mode state and the L5 user control. Keep the existing six-layer scaffold intact: L3 HUD reads the effective mode to reveal Diorama props, L4 notifications read the effective mode to add Theater staging, and L5 renders the mode switcher beside the debug gear. Notification severity S3/S4 drives temporary Theater mode through Riverpod state, so the user's manual mode is restored after the notification completes.

**Tech Stack:** Flutter, Riverpod `StateNotifierProvider`, `flutter_screenutil`, existing real NES raster assets from `assets/sprites/`, Flutter widget/provider tests, TB300FU Android screenshot verification.

---

## File Structure

- Create `lib/features/creative_mode/providers/creative_mode_provider.dart`
  - Owns `CreativeMode`, `CreativeModeState`, `CreativeModeNotifier`, and `creativeModeProvider`.
  - Listens to `notificationQueueProvider` so S3/S4 temporarily set effective mode to Theater and restore after completion.
- Create `lib/features/creative_mode/widgets/mode_switcher.dart`
  - L5 bottom-right mode control.
  - Collapsed short tap cycles Scene -> Theater -> Diorama -> Scene.
  - Long press expands three compact real-sprite choices.
  - Uses real assets: `cloud_small.png`, `block_question_f0.png`, `castle.png`.
- Modify `lib/shared/widgets/layered_scaffold.dart`
  - Add `ModeSwitcher` to L5 before `DebugPanel`, so debug remains topmost.
- Modify `lib/features/hud/widgets/time_hud.dart`
  - Watch effective creative mode.
  - Keep Scene close to current HUD.
  - Add Diorama-only prop group using `pipe_tall.png`, `flagpole.png`, and `coin_f0.png`.
- Modify `lib/features/notifications/widgets/notification_overlay.dart`
  - Watch effective creative mode.
  - In Theater mode, add a small real-sprite stage accent around active notifications.
  - In manual Theater mode with no active notification, show an idle stage hint using question block and coin assets.
- Add `test/creative_mode_provider_test.dart`
  - Provider-level mode cycle and temporary override behavior.
- Add `test/mode_switcher_test.dart`
  - Widget-level switching, expansion, and scaffold presence.
- Modify `test/widget_test.dart`
  - Assert the mode switcher exists and Diorama props can render without adding a full-width HUD mask.
- Modify `test/screenshot_test.dart`
  - Precache new assets used by mode switcher and Diorama props.

---

### Task 1: Creative Mode Provider

**Files:**
- Create: `test/creative_mode_provider_test.dart`
- Create: `lib/features/creative_mode/providers/creative_mode_provider.dart`

- [ ] **Step 1: Write the failing provider tests**

Create `test/creative_mode_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:desk_mario/features/creative_mode/providers/creative_mode_provider.dart';
import 'package:desk_mario/features/notifications/models/notification_severity.dart';
import 'package:desk_mario/features/notifications/providers/notification_queue_provider.dart';

void main() {
  test('manual mode cycles scene to theater to diorama to scene', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.scene);

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.theater);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.theater);

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.diorama);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.diorama);

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.scene);
  });

  test('severity 1 and severity 2 do not force Theater mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(creativeModeProvider.notifier).setManualMode(CreativeMode.diorama);
    container.read(notificationQueueProvider.notifier).enqueueSeverity(NotificationSeverity.severity1);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.diorama);

    container.read(notificationQueueProvider.notifier).completeCurrent();
    container.read(notificationQueueProvider.notifier).enqueueSeverity(NotificationSeverity.severity2);
    expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.diorama);
  });

  test('severity 3 temporarily switches to Theater then restores manual mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(creativeModeProvider.notifier).setManualMode(CreativeMode.diorama);
    container.read(notificationQueueProvider.notifier).enqueueSeverity(NotificationSeverity.severity3);

    final active = container.read(creativeModeProvider);
    expect(active.manualMode, CreativeMode.diorama);
    expect(active.temporaryMode, CreativeMode.theater);
    expect(active.effectiveMode, CreativeMode.theater);
    expect(active.temporaryLocked, isFalse);

    container.read(notificationQueueProvider.notifier).completeCurrent();

    final restored = container.read(creativeModeProvider);
    expect(restored.temporaryMode, isNull);
    expect(restored.effectiveMode, CreativeMode.diorama);
  });

  test('severity 4 temporarily switches to locked Theater until acknowledged', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(creativeModeProvider.notifier).setManualMode(CreativeMode.scene);
    container.read(notificationQueueProvider.notifier).enqueueSeverity(NotificationSeverity.severity4);

    final active = container.read(creativeModeProvider);
    expect(active.effectiveMode, CreativeMode.theater);
    expect(active.temporaryLocked, isTrue);

    container.read(notificationQueueProvider.notifier).completeCurrent();

    final restored = container.read(creativeModeProvider);
    expect(restored.temporaryMode, isNull);
    expect(restored.effectiveMode, CreativeMode.scene);
  });
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
flutter test test/creative_mode_provider_test.dart
```

Expected: FAIL because `creative_mode_provider.dart` does not exist.

- [ ] **Step 3: Implement provider**

Create `lib/features/creative_mode/providers/creative_mode_provider.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/models/notification_severity.dart';
import '../../notifications/providers/notification_queue_provider.dart';

enum CreativeMode { scene, theater, diorama }

enum CreativeModeTemporaryReason { notification }

extension CreativeModePresentation on CreativeMode {
  String get label => switch (this) {
        CreativeMode.scene => 'SCENE',
        CreativeMode.theater => 'THEATER',
        CreativeMode.diorama => 'DIORAMA',
      };

  CreativeMode get next => switch (this) {
        CreativeMode.scene => CreativeMode.theater,
        CreativeMode.theater => CreativeMode.diorama,
        CreativeMode.diorama => CreativeMode.scene,
      };
}

class CreativeModeState {
  const CreativeModeState({
    this.manualMode = CreativeMode.scene,
    this.temporaryMode,
    this.temporaryReason,
    this.temporaryLocked = false,
  });

  final CreativeMode manualMode;
  final CreativeMode? temporaryMode;
  final CreativeModeTemporaryReason? temporaryReason;
  final bool temporaryLocked;

  CreativeMode get effectiveMode => temporaryMode ?? manualMode;
  bool get isTemporary => temporaryMode != null;

  CreativeModeState copyWith({
    CreativeMode? manualMode,
    Object? temporaryMode = _sentinel,
    Object? temporaryReason = _sentinel,
    bool? temporaryLocked,
  }) {
    return CreativeModeState(
      manualMode: manualMode ?? this.manualMode,
      temporaryMode: identical(temporaryMode, _sentinel)
          ? this.temporaryMode
          : temporaryMode as CreativeMode?,
      temporaryReason: identical(temporaryReason, _sentinel)
          ? this.temporaryReason
          : temporaryReason as CreativeModeTemporaryReason?,
      temporaryLocked: temporaryLocked ?? this.temporaryLocked,
    );
  }
}

const Object _sentinel = Object();

class CreativeModeNotifier extends StateNotifier<CreativeModeState> {
  CreativeModeNotifier() : super(const CreativeModeState());

  void setManualMode(CreativeMode mode) {
    state = state.copyWith(manualMode: mode);
  }

  void cycleManualMode() {
    state = state.copyWith(manualMode: state.manualMode.next);
  }

  void enterTemporary(
    CreativeMode mode, {
    required CreativeModeTemporaryReason reason,
    bool locked = false,
  }) {
    state = state.copyWith(
      temporaryMode: mode,
      temporaryReason: reason,
      temporaryLocked: locked,
    );
  }

  void clearTemporary([CreativeModeTemporaryReason? reason]) {
    if (reason != null && state.temporaryReason != reason) return;
    state = state.copyWith(
      temporaryMode: null,
      temporaryReason: null,
      temporaryLocked: false,
    );
  }
}

final creativeModeProvider =
    StateNotifierProvider<CreativeModeNotifier, CreativeModeState>((ref) {
  final notifier = CreativeModeNotifier();

  ref.listen<NotificationQueueState>(notificationQueueProvider, (_, next) {
    final severity = next.current?.severity;
    switch (severity) {
      case NotificationSeverity.severity3:
        notifier.enterTemporary(
          CreativeMode.theater,
          reason: CreativeModeTemporaryReason.notification,
        );
      case NotificationSeverity.severity4:
        notifier.enterTemporary(
          CreativeMode.theater,
          reason: CreativeModeTemporaryReason.notification,
          locked: true,
        );
      case NotificationSeverity.severity1:
      case NotificationSeverity.severity2:
      case null:
        notifier.clearTemporary(CreativeModeTemporaryReason.notification);
    }
  });

  return notifier;
});
```

- [ ] **Step 4: Run tests to verify GREEN**

Run:

```bash
flutter test test/creative_mode_provider_test.dart
```

Expected: PASS.

---

### Task 2: Bottom-Right Mode Switcher

**Files:**
- Create: `test/mode_switcher_test.dart`
- Create: `lib/features/creative_mode/widgets/mode_switcher.dart`
- Modify: `lib/shared/widgets/layered_scaffold.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/mode_switcher_test.dart` with tests that pump `DeskMarioApp`, assert the collapsed switcher appears, tap it three times to cycle through modes, long-press to expand, and tap the Diorama choice.

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
flutter test test/mode_switcher_test.dart
```

Expected: FAIL because `ModeSwitcher` does not exist.

- [ ] **Step 3: Implement switcher and scaffold wiring**

Create `ModeSwitcher` with stable keys:

```dart
static const collapsedKey = ValueKey<String>('creative-mode-switcher-collapsed');
static const expandedKey = ValueKey<String>('creative-mode-switcher-expanded');
static const sceneButtonKey = ValueKey<String>('creative-mode-scene-button');
static const theaterButtonKey = ValueKey<String>('creative-mode-theater-button');
static const dioramaButtonKey = ValueKey<String>('creative-mode-diorama-button');
```

In `LayeredScaffold`, add `const ModeSwitcher()` before `const DebugPanel()`.

- [ ] **Step 4: Run tests to verify GREEN**

Run:

```bash
flutter test test/mode_switcher_test.dart
```

Expected: PASS.

---

### Task 3: Mode-Aware HUD And Diorama Props

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/features/hud/widgets/time_hud.dart`

- [ ] **Step 1: Write failing HUD tests**

Add assertions that:

- The mode switcher is present in the smoke test.
- Overriding `creativeModeProvider` to Diorama mode renders keys for `pipe_tall.png` weather prop and `flagpole.png` message prop.
- `TimeHud` still has no descendant `DecoratedBox`.

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because Diorama prop keys do not exist.

- [ ] **Step 3: Implement HUD variants**

In `TimeHud`, watch `creativeModeProvider` and return an `IgnorePointer` wrapping a `Stack`. Keep the current top HUD for all modes. Add Diorama-only bottom-left props:

- Weather prop: `pipe_tall.png` with small `cloud_small.png` and weather text.
- Message prop: `flagpole.png` with `coin_f0.png` and `xNN`.

All `Image.asset` calls must set `filterQuality: FilterQuality.none` and `gaplessPlayback: true`.

- [ ] **Step 4: Run tests to verify GREEN**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS.

---

### Task 4: Theater Notification Staging

**Files:**
- Modify: `test/interaction_test.dart`
- Modify: `lib/features/notifications/widgets/notification_overlay.dart`

- [ ] **Step 1: Write failing notification tests**

Add tests that:

- Manually switching to Theater mode with no active notification shows an idle Theater hint.
- Triggering Test L3 while manual mode is Diorama makes the effective mode Theater during the dialog and restores Diorama after the message completes.

- [ ] **Step 2: Run tests to verify RED**

Run:

```bash
flutter test test/interaction_test.dart
```

Expected: FAIL because Theater hint/stage keys do not exist.

- [ ] **Step 3: Implement Theater stage accents**

In `NotificationOverlay`:

- Watch `creativeModeProvider`.
- If `effectiveMode == CreativeMode.theater` and `current == null`, render an idle real-sprite stage hint.
- If `effectiveMode == CreativeMode.theater` and `current != null`, render a subtle real-sprite stage accent behind or near the severity widget.
- Do not add a full-screen opaque panel.

- [ ] **Step 4: Run tests to verify GREEN**

Run:

```bash
flutter test test/interaction_test.dart
```

Expected: PASS.

---

### Task 5: Golden Assets, Full Verification, And Commit

**Files:**
- Modify: `test/screenshot_test.dart`
- Modify docs only if implementation names drift from this plan.

- [ ] **Step 1: Precache new visual assets**

Add these assets to `_goldenImageAssets`:

```dart
'assets/sprites/cloud_small.png',
'assets/sprites/block_question_f0.png',
'assets/sprites/pipe_tall.png',
'assets/sprites/flagpole.png',
'assets/sprites/castle.png',
```

- [ ] **Step 2: Format and run automated verification**

Run:

```bash
dart format lib test docs/superpowers/plans/2026-06-27-desk-mario-creative-mode-system.md
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all pass.

- [ ] **Step 3: TB300FU visual verification**

Run:

```bash
SCRIPT=.agents/skills/android-dev/scripts/adb.sh
$SCRIPT install build/app/outputs/flutter-apk/app-debug.apk -r -t
$SCRIPT restart
sleep 3
$SCRIPT screenshot /tmp/desk_mario_scene_mode.png
$SCRIPT tap 1165 760
sleep 1
$SCRIPT screenshot /tmp/desk_mario_theater_mode.png
$SCRIPT tap 1165 760
sleep 1
$SCRIPT screenshot /tmp/desk_mario_diorama_mode.png
```

Open and visually inspect the three screenshots. Confirm:

- Scene mode preserves the sky/cloud readability.
- Theater mode has visible notification/stage personality without blocking the world.
- Diorama mode shows real pipe/flag/coin-style data props.
- Debug gear remains reachable.

- [ ] **Step 4: Commit**

Run:

```bash
git status --short
git add docs/superpowers/plans/2026-06-27-desk-mario-creative-mode-system.md lib test
git commit -m "Add DeskMario creative mode system"
```

Expected: commit succeeds on `codex/desk-mario-view-layout`.

---

## Self-Review

- Spec coverage: This plan implements the first slice from the design spec: provider, bottom-right mode control, L3/L4 wiring, Scene preservation, Theater emphasis, Diorama real props, tests, and Android screenshots.
- Placeholder scan: No task relies on fake weather particles or drawn Mario objects. All first-pass mode visuals use existing real raster assets.
- Type consistency: `CreativeMode`, `CreativeModeState`, `creativeModeProvider`, and mode switcher keys are named consistently across provider, widgets, and tests.
