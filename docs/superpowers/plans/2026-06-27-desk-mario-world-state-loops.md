# DeskMario World State Loops Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first complete world-state loop track: weather, S4 alert, time phase, and data diorama all derive from one shared Mario-world state snapshot.

**Architecture:** Add a `worldStateLoopProvider` that interprets existing providers into one render snapshot. Route Atmosphere, Diorama HUD, S4 lock behavior, and visual tests through that snapshot while keeping real sprite assets as the only world-object source.

**Tech Stack:** Flutter, Riverpod, `flutter_screenutil`, existing raster assets, Flutter widget/unit tests, TB300FU Android screenshot verification.

---

## File Structure

- Create: `lib/features/world_state/providers/world_state_loop_provider.dart`
  - Owns `WorldTimePhase`, `WorldAlertPhase`, `DioramaDensity`,
    `AtmosphereRecipe`, and `WorldStateLoopSnapshot`.
  - Derives state from `weatherProvider`, `clockProvider`,
    `notificationQueueProvider`, `backgroundDimProvider`, and
    `creativeModeProvider`.
- Create: `test/world_state_loop_provider_test.dart`
  - Covers time phase, weather atmosphere mapping, alert mapping, and Diorama
    density.
- Modify: `lib/shared/widgets/atmospheric_layer.dart`
  - Reads `worldStateLoopProvider` and renders tint/vignette recipes.
- Modify: `lib/features/hud/widgets/time_hud.dart`
  - Reads `worldStateLoopProvider` for Diorama weather/time props.
- Modify: `lib/features/creative_mode/widgets/mode_switcher.dart`
  - Prevents locked S4 temporary mode from visually escaping Theater.
- Modify: `test/widget_test.dart`
  - Adds assertions for atmosphere keys and Diorama time/weather props.
- Modify: `test/mode_switcher_test.dart`
  - Adds locked temporary mode behavior.
- Modify: `test/interaction_test.dart`
  - Adds S4 restore/lock checks through the UI.
- Modify: `test/screenshot_test.dart`
  - Pins golden to an explicit time/weather/world state.

## Task 1: World-State Snapshot Foundation

**Files:**
- Create: `lib/features/world_state/providers/world_state_loop_provider.dart`
- Create: `test/world_state_loop_provider_test.dart`

- [ ] **Step 1: Write failing provider tests**

```dart
test('derives time phases from clockProvider', () {
  final morning = _containerAt(DateTime(2026, 1, 1, 6));
  expect(morning.read(worldStateLoopProvider).timePhase, WorldTimePhase.morning);

  final day = _containerAt(DateTime(2026, 1, 1, 12));
  expect(day.read(worldStateLoopProvider).timePhase, WorldTimePhase.day);

  final dusk = _containerAt(DateTime(2026, 1, 1, 18));
  expect(dusk.read(worldStateLoopProvider).timePhase, WorldTimePhase.dusk);

  final night = _containerAt(DateTime(2026, 1, 1, 23));
  expect(night.read(worldStateLoopProvider).timePhase, WorldTimePhase.night);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/world_state_loop_provider_test.dart
```

Expected: FAIL because `worldStateLoopProvider` does not exist.

- [ ] **Step 3: Implement the provider**

```dart
final worldStateLoopProvider = Provider<WorldStateLoopSnapshot>((ref) {
  final weather = ref.watch(weatherProvider);
  final now = ref.watch(clockProvider);
  final notification = ref.watch(notificationQueueProvider);
  final creativeMode = ref.watch(creativeModeProvider);
  final isDimmed = ref.watch(backgroundDimProvider);

  final alertPhase =
      notification.current?.severity == NotificationSeverity.severity4 ||
              isDimmed
          ? WorldAlertPhase.holding
          : WorldAlertPhase.idle;

  final timePhase = WorldTimePhaseX.fromDateTime(now);
  final density = switch (creativeMode.effectiveMode) {
    CreativeMode.scene => DioramaDensity.minimal,
    CreativeMode.theater => DioramaDensity.normal,
    CreativeMode.diorama => DioramaDensity.inspectable,
  };

  return WorldStateLoopSnapshot(
    weather: weather,
    timePhase: timePhase,
    creativeMode: creativeMode.effectiveMode,
    alertPhase: alertPhase,
    dioramaDensity: density,
    atmosphere: AtmosphereRecipe.forState(
      condition: weather.condition,
      timePhase: timePhase,
      alertPhase: alertPhase,
    ),
  );
});
```

- [ ] **Step 4: Run provider tests**

Run:

```bash
flutter test test/world_state_loop_provider_test.dart
```

Expected: PASS.

## Task 2: Weather + Time Atmosphere Loop

**Files:**
- Modify: `lib/shared/widgets/atmospheric_layer.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/screenshot_test.dart`

- [ ] **Step 1: Write widget assertions for atmosphere**

```dart
expect(find.byKey(AtmosphericLayer.temperatureOverlayKey), findsOneWidget);
expect(find.byKey(AtmosphericLayer.vignetteOverlayKey), findsOneWidget);
```

- [ ] **Step 2: Run target widget test to verify it fails**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because the keys and world-state atmosphere recipe are not wired.

- [ ] **Step 3: Route Atmosphere through `worldStateLoopProvider`**

```dart
class AtmosphericLayer extends ConsumerWidget {
  const AtmosphericLayer({super.key});

  static const temperatureOverlayKey =
      ValueKey<String>('atmosphere-temperature-overlay');
  static const vignetteOverlayKey = ValueKey<String>('atmosphere-vignette');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(worldStateLoopProvider).atmosphere;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (recipe.tintOpacity > 0)
            _ColorTemperatureOverlay(
              key: temperatureOverlayKey,
              temperature: recipe.tint,
              opacity: recipe.tintOpacity,
            ),
          _VignetteOverlay(
            key: vignetteOverlayKey,
            midOpacity: recipe.vignetteMidOpacity,
            outerOpacity: recipe.vignetteOuterOpacity,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS.

## Task 3: Strong Alert Closed Loop

**Files:**
- Modify: `lib/features/creative_mode/widgets/mode_switcher.dart`
- Modify: `test/mode_switcher_test.dart`
- Modify: `test/interaction_test.dart`

- [ ] **Step 1: Add locked mode switcher test**

```dart
container
    .read(creativeModeProvider.notifier)
    .enterTemporary(
      CreativeMode.theater,
      reason: CreativeModeTemporaryReason.notification,
      locked: true,
    );

await _pumpModeSwitcher(tester, container);
await tester.tap(find.byKey(ModeSwitcher.collapsedKey));
await tester.pump(const Duration(milliseconds: 160));

expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
expect(container.read(creativeModeProvider).effectiveMode, CreativeMode.theater);
```

- [ ] **Step 2: Run mode switcher test to verify it fails**

Run:

```bash
flutter test test/mode_switcher_test.dart
```

Expected: FAIL because locked mode still accepts manual cycling.

- [ ] **Step 3: Make S4 lock explicit in the control**

```dart
void _cycleMode() {
  final state = ref.read(creativeModeProvider);
  if (state.temporaryLocked) return;
  ref.read(creativeModeProvider.notifier).cycleManualMode();
  if (_expanded) setState(() => _expanded = false);
}

void _openChoices() {
  if (ref.read(creativeModeProvider).temporaryLocked) return;
  setState(() => _expanded = true);
}
```

- [ ] **Step 4: Run mode switcher and interaction tests**

Run:

```bash
flutter test test/mode_switcher_test.dart test/interaction_test.dart
```

Expected: PASS.

## Task 4: Data Diorama Closed Loop

**Files:**
- Modify: `lib/features/hud/widgets/time_hud.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add Diorama prop assertions**

```dart
expect(find.byKey(TimeHud.dioramaTimeCastleKey), findsOneWidget);
expect(find.text('NIGHT'), findsWidgets);
```

- [ ] **Step 2: Run target widget test to verify it fails**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL because the time castle prop does not exist.

- [ ] **Step 3: Add time-phase prop using the real castle asset**

```dart
if (world.dioramaDensity == DioramaDensity.inspectable)
  _DioramaDataProps(
    weatherLabel: world.weather.displayText,
    messageLabel: pendingLabel,
    timeLabel: world.timePhase.label,
    condition: world.weather.condition,
  ),
```

- [ ] **Step 4: Run widget tests**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS.

## Task 5: Full Verification And Device Screenshots

**Files:**
- Modify only if verification exposes a visual bug.

- [ ] **Step 1: Format and analyze**

Run:

```bash
dart format lib test
flutter analyze
```

Expected: no analyzer issues.

- [ ] **Step 2: Run full tests**

Run:

```bash
flutter test
```

Expected: all tests pass. If the golden changes, update it intentionally with:

```bash
flutter test test/screenshot_test.dart --update-goldens
flutter test
```

- [ ] **Step 3: Build Android debug APK**

Run:

```bash
flutter build apk --debug
```

Expected: APK build succeeds.

- [ ] **Step 4: Install, restart, and screenshot TB300FU**

Run:

```bash
SCRIPT=.agents/skills/android-dev/scripts/adb.sh
flutter install -d HGR496PP
$SCRIPT restart
sleep 3
$SCRIPT screenshot /tmp/desk_mario_world_state_scene.png
```

Then use debug controls and mode switcher to capture:

- `/tmp/desk_mario_world_state_scene.png`
- `/tmp/desk_mario_world_state_weather_snow.png`
- `/tmp/desk_mario_world_state_weather_fog.png`
- `/tmp/desk_mario_world_state_weather_storm.png`
- `/tmp/desk_mario_world_state_diorama.png`
- `/tmp/desk_mario_world_state_s4_active.png`
- `/tmp/desk_mario_world_state_s4_restored.png`

Expected: screenshots look intentional, do not block clouds/Mario, and S4 is
readable plus restorable.

- [ ] **Step 5: Commit**

```bash
git add lib test docs/superpowers/plans/2026-06-27-desk-mario-world-state-loops.md
git commit -m "Add DeskMario world state loops"
```
