# Demo Control Real Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make DeskMario more demonstrable by adding real extracted world-object assets and Debug Panel weather controls that update the HUD without code edits.

**Architecture:** Keep the 6-layer stack unchanged. Add a documented asset extraction script for real sprites from the existing SMB stage sheet, then extend existing Riverpod weather state and Debug Panel controls.

**Tech Stack:** Flutter, Riverpod, ScreenUtil, Python/Pillow for PNG crop tooling already used in `tools/process_panel1.py`, existing NES raster assets.

---

## Files

- Create: `tools/extract_stage_sprites.py`
  - Crops documented real sprites from `assets/backgrounds/smb_world_minus1.png`.
- Create/update assets:
  - `assets/sprites/pipe_tall.png`
  - `assets/sprites/castle.png`
  - `assets/sprites/flagpole.png`
  - `assets/sprites/cloud_small.png`
- Modify: `docs/sprites.md`
  - Add source rectangles and usage for newly extracted assets.
- Modify: `lib/features/weather/providers/weather_provider.dart`
  - Add `copyWith` and next-condition helpers if useful.
- Modify: `lib/features/debug/widgets/debug_panel.dart`
  - Add weather controls that set `weatherProvider`.
- Modify: `test/interaction_test.dart`
  - Add test that Debug Panel can switch weather and HUD text updates.
- Modify: `test/screenshot_test.dart`
  - Keep deterministic weather override.

## Task 1: Extract Real Stage Sprites

**Files:**
- Create: `tools/extract_stage_sprites.py`
- Generate: `assets/sprites/pipe_tall.png`, `assets/sprites/castle.png`, `assets/sprites/flagpole.png`, `assets/sprites/cloud_small.png`
- Modify: `docs/sprites.md`

- [ ] **Step 1: Create extraction script**

Create `tools/extract_stage_sprites.py` with crop rectangles from `assets/backgrounds/smb_world_minus1.png`:

```python
#!/usr/bin/env python3
"""Extract real SMB stage sprites used by DeskMario world-object UI.

All rectangles are source coordinates in assets/backgrounds/smb_world_minus1.png.
The output images are transparent-trimmed only when the source sheet already
contains transparent pixels; no drawing or repainting is performed.
"""

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/backgrounds/smb_world_minus1.png")
OUT_DIR = Path("assets/sprites")

SPRITES = {
    "cloud_small.png": (56, 43, 42, 18),
    "pipe_tall.png": (398, 80, 96, 128),
    "flagpole.png": (2427, 30, 24, 178),
    "castle.png": (2520, 30, 86, 178),
}


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, (x, y, w, h) in SPRITES.items():
        crop = image.crop((x, y, x + w, y + h))
        out = OUT_DIR / name
        crop.save(out)
        print(f"{out}: source=({x},{y},{w},{h}) size={crop.size[0]}x{crop.size[1]}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run extraction**

Run:

```bash
python3 tools/extract_stage_sprites.py
```

Expected: all four PNGs are written and command prints their source rectangles.

- [ ] **Step 3: Inspect generated assets**

Use image inspection on each generated PNG. Expected:

- `cloud_small.png`: real small cloud from stage sheet.
- `pipe_tall.png`: real pipe/pillar crop from stage sheet.
- `flagpole.png`: real flagpole crop.
- `castle.png`: real castle crop.

- [ ] **Step 4: Update sprite docs**

Add rows to `docs/sprites.md` under 资源清单:

```markdown
| `assets/sprites/cloud_small.png` | 后续天气/场景云朵素材 | 42×18 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(56,43,42,18)` 裁出 |
| `assets/sprites/pipe_tall.png` | 后续数据 dock / 场景物件 | 96×128 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(398,80,96,128)` 裁出 |
| `assets/sprites/flagpole.png` | 后续进度/专注标记 | 24×178 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(2427,30,24,178)` 裁出 |
| `assets/sprites/castle.png` | 后续长期状态/终点物件 | 86×178 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(2520,30,86,178)` 裁出 |
```

## Task 2: Debug Weather Controls

**Files:**
- Modify: `lib/features/debug/widgets/debug_panel.dart`
- Modify: `lib/features/weather/providers/weather_provider.dart`
- Test: `test/interaction_test.dart`

- [ ] **Step 1: Write failing interaction test**

In `test/interaction_test.dart`, add import:

```dart
import 'package:desk_mario/features/weather/providers/weather_provider.dart';
```

Add a test under Debug Panel group:

```dart
testWidgets('Debug Panel 可切换天气状态，HUD 文案随之更新', (tester) async {
  await _pumpApp(tester);

  await tester.tap(find.byIcon(Icons.settings));
  await tester.pump(const Duration(milliseconds: 400));

  expect(find.text('Weather'), findsOneWidget);
  expect(find.text(WeatherCondition.rain.label), findsOneWidget);

  await tester.tap(find.text(WeatherCondition.snow.label));
  await tester.pump(const Duration(milliseconds: 400));

  expect(find.textContaining('SNOW'), findsOneWidget);
});
```

Expected now: FAIL because Debug Panel has no weather controls.

- [ ] **Step 2: Add weather setter helper**

In `weather_provider.dart`, add:

```dart
extension WeatherSnapshotCopy on WeatherSnapshot {
  WeatherSnapshot copyWith({
    WeatherCondition? condition,
    int? temperatureC,
  }) {
    return WeatherSnapshot(
      condition: condition ?? this.condition,
      temperatureC: temperatureC ?? this.temperatureC,
    );
  }
}
```

- [ ] **Step 3: Add Debug Panel imports and setter**

In `debug_panel.dart`, import:

```dart
import '../../weather/providers/weather_provider.dart';
```

Add method:

```dart
void _setWeather(WeatherCondition condition) {
  final current = ref.read(weatherProvider);
  ref.read(weatherProvider.notifier).state =
      current.copyWith(condition: condition);
}
```

- [ ] **Step 4: Render weather controls**

In `_buildExpanded`, add a weather section between notification buttons and theme switch:

```dart
SizedBox(height: 12.h),
_buildWeatherControls(),
```

Add:

```dart
Widget _buildWeatherControls() {
  final current = ref.watch(weatherProvider).condition;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        'Weather',
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
      SizedBox(height: 8.h),
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final condition in WeatherCondition.values)
            _buildBtn(
              condition.label,
              () => _setWeather(condition),
              active: current == condition,
            ),
        ],
      ),
    ],
  );
}
```

Update `_buildBtn` signature to:

```dart
Widget _buildBtn(String label, VoidCallback onTap, {bool active = false})
```

and set button color/border based on `active`.

- [ ] **Step 5: Run interaction test**

Run:

```bash
flutter test test/interaction_test.dart
```

Expected: PASS.

## Task 3: Verification

**Files:**
- No additional source edits unless verification exposes a bug.

- [ ] **Step 1: Format and analyze**

Run:

```bash
dart format tools/extract_stage_sprites.py lib/features/debug/widgets/debug_panel.dart lib/features/weather/providers/weather_provider.dart test/interaction_test.dart docs/sprites.md
flutter analyze
```

Expected: no analyzer issues. `dart format` may skip/complain for `.py` or `.md`; if so, run `dart format` only on Dart files and keep Python/Markdown manually tidy.

- [ ] **Step 2: Full tests**

Run:

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Android visual verification**

Run:

```bash
flutter build apk --debug
SCRIPT=.agents/skills/android-dev/scripts/adb.sh
$SCRIPT install build/app/outputs/flutter-apk/app-debug.apk -r -t
$SCRIPT restart
sleep 8
$SCRIPT screenshot /tmp/desk_mario_demo_control.png
$SCRIPT tap 1236 756
sleep 1
$SCRIPT screenshot /tmp/desk_mario_demo_control_debug.png
```

Inspect both screenshots. Expected:

- Main screen still reads as Mario world dashboard.
- Debug panel shows weather controls.
- L5 debug controls stay above all layers.
- No fake weather particles appear.
