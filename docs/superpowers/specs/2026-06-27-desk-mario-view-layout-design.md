# DeskMario View Layout Design

Date: 2026-06-27

## Goal

Build the first complete view-layer layout for DeskMario: a playful desktop ornament that uses real NES Super Mario Bros. elements as the visible world, while reserving clear places for weather, ambient data, and notification performances.

This phase is view-only. Data can be mocked or static. The goal is the page composition and visual system, not real weather or real notification ingestion.

## Hard Constraints

- Use only real project assets for sprites. Do not draw replacement Mario-world assets such as pipes, flags, castles, or clouds unless a real sprite asset exists.
- Preserve the current 6-layer architecture in `LayeredScaffold`.
- Keep `Image.asset` pixel-art usage at `filterQuality: FilterQuality.none`, with `gaplessPlayback: true` for animated or moving sprites.
- Do not add dependencies. Use Flutter, Riverpod, and ScreenUtil already present in the project.
- Do not use `pumpAndSettle` in tests because the app has infinite animations.
- Final validation must include Android device screenshots on TB300FU through `.agents/skills/android-dev/scripts/adb.sh`.

## Recommended Direction

Use the "World Dashboard" layout: information should feel like it belongs inside the SMB world instead of sitting on top of it as a normal app dashboard.

The visual companion mockup for this design session is available at `http://localhost:64083` while the companion server is running. It compares three directions:

- A. World Dashboard: recommended. Data appears as bricks, blocks, coins, and small sprite clusters.
- B. Arcade Scoreboard: strong SMB reference but too much like a standard HUD overlay.
- C. Weather Cinematic: good drama for weather and alerts, but too weak for everyday data.

Implementation should use A as the base and borrow C's weather/alert drama.

## Screen Composition

### L0 World

Keep `ScrollingWorld` as the bottom layer:

- Existing real SMB overworld background remains full-screen.
- Existing ground tiles remain aligned to the background through `ScrollingMetrics`.
- No layout widgets should be placed inside L0 unless they are part of the scrolling world.

### L1 Weather

Replace the transparent placeholder with a view-only weather layer boundary. Weather visuals must also obey the real-asset rule:

- `clear`: no overlay.
- `rain`: only render if a real rain/drop sprite or authentic raster overlay is added.
- `snow`: only render if a real snowflake/snow particle sprite or authentic raster overlay is added.
- `fog`: only render if backed by a real raster fog/cloud/overlay asset.
- `storm`: can combine real rain assets with a Flutter opacity flash, because the flash is a lighting effect rather than a new sprite asset.

Weather should ignore pointer events and stay below Mario/HUD/notifications. If no suitable real weather asset exists in the repo, this phase should still add the provider/widget boundary and show the weather state through the L3 HUD, while leaving the full-screen weather overlay in `clear`.

### L2 Character

Keep `PositionedMario`:

- Mario center remains at one-third screen width.
- Feet remain aligned to the ground top.
- Do not change Mario sprite animation unless layout requires spacing fixes.

### L3 HUD

Replace the single-purpose time-only HUD with a compact transparent NES-style top HUD that has three permanent zones:

1. Center: the current time in the existing pixel font, large enough to work as a desk clock but contained inside the bar.
2. Left: weather summary group using available sprites only. For now this can show `RAIN 18C` and one existing accent sprite like `starman` rather than drawing custom weather icons.
3. Right: notification/data summary group using existing sprites such as coin, question block, mushroom, Goomba, or Koopa. This can show mock unread count and status values.

The HUD must read as game overlay text, not a generic app panel:

- No large app panels or nested cards.
- No full-width background masks; clouds and sky must remain visible.
- Text may use the existing pixel font with a black outline for readability.
- Text should stay compact enough that moving clouds remain the visual subject when they pass behind it.

### L4 Notifications

Keep the current four severity system and its queue. Adjust only if needed for layout collisions:

- Severity 1 remains a small right-side/upper notice.
- Severity 2 remains a sign/banner style top notice.
- Severity 3 remains a bottom dialog and should avoid covering Mario's feet more than necessary.
- Severity 4 remains full-screen pause alert with existing dim/blur behavior.

### L5 Debug

Keep the debug panel as the top layer. It remains the current control surface for triggering notifications and theme changes.

## Initial Implementation Scope

The first implementation pass should be small enough to finish and verify in one working session:

- Add a `WorldHud` or equivalent L3 widget that composes:
  - current top-HUD time,
  - weather summary cluster,
  - message/data summary cluster.
- Keep `TimeHud.clockKey` or provide an equivalent stable key for tests.
- Add a `WeatherLayer` provider/widget boundary. Implement full-screen rain/snow only if a real raster weather asset is present or extracted from a real source; otherwise leave the overlay clear and represent weather in the HUD.
- Add a small set of focused widget tests for HUD anchors and weather rendering.
- Update screenshots/goldens only if the final layout intentionally changes them.

## Future Asset Backlog

These should not be faked in this phase:

- Pipe sprite for a future left/right data dock.
- Flagpole sprite for progress metrics.
- Castle sprite for long-running status.
- Lakitu/cloud-specific weather icons.
- Real SMB font or number sprite sheet if a better real asset is sourced.

## Verification Plan

Run:

- `flutter analyze`
- `flutter test`
- Android device restart and screenshot:
  - `.agents/skills/android-dev/scripts/adb.sh restart`
  - `sleep 3`
  - `.agents/skills/android-dev/scripts/adb.sh screenshot /tmp/desk_mario_layout.png`
  - inspect `/tmp/desk_mario_layout.png`

Acceptance criteria:

- The first screen reads as an SMB desktop ornament, not a generic dashboard.
- Time, weather summary, and notification summary are visible without fighting Mario.
- Weather effects sit behind Mario/HUD and do not intercept touches.
- Notification severity demos still work through the debug panel.
- No fake Mario-world assets are drawn.
- Analyze/tests pass, or any failures are documented with the exact blocker.
