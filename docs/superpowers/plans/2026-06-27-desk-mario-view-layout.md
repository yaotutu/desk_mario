# DeskMario View Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first complete view-layer layout: an SMB world dashboard with time, weather summary, notification/data summary, and a real-asset-safe weather layer boundary.

**Architecture:** Keep `LayeredScaffold` intact. Expand the existing L3 `TimeHud` into a transparent NES-style top HUD so current tests and imports remain stable, and add a small L1 weather provider boundary without drawing fake weather particles.

**Implementation note:** Visual review rejected both the earlier world-object/brick-time composition and the later full-width black bar because they fought the moving cloud background. The shipped HUD uses compact outlined pixel text and real sprite icons without painting a full-width mask.

**Tech Stack:** Flutter, Riverpod, ScreenUtil, existing NES raster assets, existing PixelFont.

---

## Files

- Create: `lib/features/weather/providers/weather_provider.dart`  
  Holds view-only weather state.
- Modify: `lib/features/weather/widgets/weather_layer.dart`  
  Watches weather state; renders no fake particles without real assets.
- Modify: `lib/features/hud/widgets/time_hud.dart`  
  Keeps `TimeHud.clockKey`, adds left weather, center time, and right data clusters as transparent NES HUD text.
- Modify: `test/widget_test.dart`  
  Adds stable assertions for new HUD clusters and weather layer.
- Modify: `test/interaction_test.dart`  
  Keeps existing notification/debug tests compatible with the expanded HUD.
- Modify: `test/screenshot_test.dart`  
  Optionally override weather state for deterministic golden.
- Update: `test/goldens/home_page.png` only if intentional layout changes require it.

## Task 1: Weather Provider Boundary

**Files:**
- Create: `lib/features/weather/providers/weather_provider.dart`
- Modify: `lib/features/weather/widgets/weather_layer.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add failing smoke assertions**

Add these expectations after the existing time HUD assertion in `test/widget_test.dart`:

```dart
expect(find.byKey(TimeHud.weatherKey), findsOneWidget);
expect(find.byKey(TimeHud.statusKey), findsOneWidget);
expect(find.byKey(const ValueKey<String>('weather-layer')), findsOneWidget);
```

Expected now: FAIL because the keys do not exist yet.

- [ ] **Step 2: Run the focused test**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: FAIL with missing `TimeHud.weatherKey`, `TimeHud.statusKey`, or `weather-layer`.

- [ ] **Step 3: Create weather provider**

Create `lib/features/weather/providers/weather_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// View-only weather condition for the L1 Weather layer and L3 HUD.
///
/// Full-screen weather visuals may only render when backed by real raster
/// assets. Until those assets exist, non-clear states are shown in the HUD
/// while the L1 layer stays visually transparent.
enum WeatherCondition {
  clear(label: 'CLEAR'),
  rain(label: 'RAIN'),
  snow(label: 'SNOW'),
  fog(label: 'FOG'),
  storm(label: 'STORM');

  const WeatherCondition({required this.label});

  final String label;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.condition,
    required this.temperatureC,
  });

  final WeatherCondition condition;
  final int temperatureC;

  String get displayText => '${condition.label} ${temperatureC}C';
}

final weatherProvider = StateProvider<WeatherSnapshot>(
  (ref) => const WeatherSnapshot(
    condition: WeatherCondition.rain,
    temperatureC: 18,
  ),
);
```

- [ ] **Step 4: Update WeatherLayer boundary**

Update `lib/features/weather/widgets/weather_layer.dart` so it becomes a `ConsumerWidget`, watches `weatherProvider`, and keeps an always-present key:

```dart
class WeatherLayer extends ConsumerWidget {
  const WeatherLayer({super.key});

  static const layerKey = ValueKey<String>('weather-layer');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    return IgnorePointer(
      key: layerKey,
      child: _AssetBackedWeatherOverlay(weather: weather),
    );
  }
}
```

Add `_AssetBackedWeatherOverlay` below `WeatherLayer`:

```dart
class _AssetBackedWeatherOverlay extends StatelessWidget {
  const _AssetBackedWeatherOverlay({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    switch (weather.condition) {
      case WeatherCondition.clear:
      case WeatherCondition.rain:
      case WeatherCondition.snow:
      case WeatherCondition.fog:
      case WeatherCondition.storm:
        // Full-screen weather particles are intentionally disabled until
        // this project has real raster weather assets. The current weather
        // state is still visible in L3 HUD through TimeHud.
        return const SizedBox.expand();
    }
  }
}
```

- [ ] **Step 5: Re-run focused test**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: still FAIL until Task 2 adds `TimeHud.weatherKey` and `TimeHud.statusKey`.

## Task 2: World Object HUD

**Files:**
- Modify: `lib/features/hud/widgets/time_hud.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add stable keys and imports**

In `time_hud.dart`, add imports:

```dart
import '../../../core/constants/design_size.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_queue_provider.dart';
import '../../weather/providers/weather_provider.dart';
```

Add keys to `TimeHud`:

```dart
static const weatherKey = ValueKey<String>('world-hud-weather');
static const statusKey = ValueKey<String>('world-hud-status');
```

- [ ] **Step 2: Expand build into a transparent NES top HUD**

Keep `TimeHud.clockKey`, add stable weather/status keys, and return a top-aligned HUD that does not draw a full-width background mask.

```dart
return IgnorePointer(
  child: Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: EdgeInsets.only(left: 44.w, top: 12.h, right: 44.w),
      child: Row(
        children: const [
          // WEATHER + starman + current weather label
          // centered TIME
          // MSG + unread count + coin
        ],
      ),
    ),
  ),
);
```

Compute:

```dart
final weather = ref.watch(weatherProvider);
final queueState = ref.watch(notificationQueueProvider);
final pendingCount = queueState.queue.length + (queueState.current == null ? 0 : 1);
```

- [ ] **Step 3: Add compact HUD object widgets**

Add small private widgets in `time_hud.dart`:

```dart
class _WeatherObjectHud extends StatelessWidget {
  const _WeatherObjectHud({required this.objectKey, required this.label});

  final Key objectKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        key: objectKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/sprites/starman_f0.png',
            width: 23.r,
            height: 23.r,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 6.w),
          _OutlinedPixelText(text: label, fontSize: 12),
        ],
      ),
    );
  }
}

class _StatusObjectHud extends StatelessWidget {
  const _StatusObjectHud({required this.objectKey, required this.label});

  final Key objectKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        key: objectKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutlinedPixelText(text: label, fontSize: 12),
          SizedBox(width: 6.w),
          Image.asset(
            'assets/sprites/coin_f0.png',
            width: 23.r,
            height: 23.r,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_OutlinedPixelText`**

Use palette colors for text and shadow:

```dart
class _OutlinedPixelText extends StatelessWidget {
  const _OutlinedPixelText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final style = TextStyle(
      fontFamily: AppFonts.pixel,
      fontSize: fontSize.sp,
      height: 1,
      letterSpacing: 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final offset in const [
          Offset(-1.5, 0),
          Offset(1.5, 0),
          Offset(0, -1.5),
          Offset(0, 1.5),
        ])
          Transform.translate(
            offset: offset,
            child: Text(text, style: style.copyWith(color: p.hudShadow)),
          ),
        Text(text, style: style.copyWith(color: p.hudText)),
      ],
    );
  }
}
```

- [ ] **Step 5: Re-run focused test**

Run:

```bash
flutter test test/widget_test.dart
```

Expected: PASS.

## Task 3: Interaction and Golden Compatibility

**Files:**
- Modify: `test/interaction_test.dart`
- Modify: `test/screenshot_test.dart`
- Test: `test/interaction_test.dart`, `test/screenshot_test.dart`

- [ ] **Step 1: Add interaction assertions**

In the initial render test in `test/interaction_test.dart`, after the clock assertion, add:

```dart
expect(find.byKey(TimeHud.weatherKey), findsOneWidget);
expect(find.byKey(TimeHud.statusKey), findsOneWidget);
```

- [ ] **Step 2: Keep golden deterministic**

If the HUD reads `weatherProvider`, override it in `test/screenshot_test.dart`:

```dart
weatherProvider.overrideWith(
  (ref) => const WeatherSnapshot(
    condition: WeatherCondition.rain,
    temperatureC: 18,
  ),
),
```

Add the import:

```dart
import 'package:desk_mario/features/weather/providers/weather_provider.dart';
```

- [ ] **Step 3: Run interaction tests**

Run:

```bash
flutter test test/interaction_test.dart
```

Expected: PASS.

- [ ] **Step 4: Run golden test**

Run:

```bash
flutter test test/screenshot_test.dart
```

Expected: If it fails only because the intentional HUD layout changed, update with:

```bash
flutter test test/screenshot_test.dart --update-goldens
```

Then re-run without `--update-goldens` and expect PASS.

## Task 4: Full Verification and Android Screenshot

**Files:**
- No additional source edits unless verification exposes a bug.

- [ ] **Step 1: Static analysis**

Run:

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 2: Full test suite**

Run:

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Android visual verification**

Run:

```bash
SCRIPT=.agents/skills/android-dev/scripts/adb.sh
$SCRIPT restart
sleep 3
$SCRIPT screenshot /tmp/desk_mario_layout.png
```

Inspect `/tmp/desk_mario_layout.png`. Expected:

- Center top-HUD time remains visible.
- Left weather summary and right message summary are visible without masking clouds.
- Mario still reads as the focus at one-third screen width.
- Debug gear remains accessible in the lower right.
- No fake full-screen rain/snow particles are present without real assets.

- [ ] **Step 4: If notification overlap is risky, verify debug flow**

Use:

```bash
SCRIPT=.agents/skills/android-dev/scripts/adb.sh
$SCRIPT tap 1236 756
sleep 1
$SCRIPT screenshot /tmp/desk_mario_debug.png
```

Expected: debug panel opens over the top layer and is not blocked by HUD/weather.

## Execution Mode

The user asked for autonomous execution while away, so use inline execution in this session rather than pausing for an execution-mode choice.
