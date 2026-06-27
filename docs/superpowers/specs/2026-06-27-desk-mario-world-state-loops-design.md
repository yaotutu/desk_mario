# DeskMario World State Loops Design

Date: 2026-06-27

## Goal

DeskMario should become a living Mario-world desk ornament where every external
state has a visible loop inside the level:

1. Weather loop: clear, rain, snow, fog, and storm each change the world mood.
2. Strong alert loop: severity 4 notifications fully enter, hold, and release
   a Mario-world alert state.
3. Time loop: morning, day, dusk, and night affect the atmosphere continuously.
4. Data diorama loop: persistent data becomes inspectable Mario props instead
   of normal dashboard widgets.

These loops must build on the existing Scene / Theater / Diorama creative modes.
They are not new pages and should not turn the app back into a dashboard.

## Approach Decision

Three approaches were considered:

1. Decoration-only: add different visual widgets directly inside Weather, HUD,
   and Notification. This is fast but will drift into disconnected effects.
2. Per-feature loops: let Weather, Alert, Time, and Diorama each own its own
   interpretation. This keeps files local but creates conflicting priorities
   when rain, night, and S4 alert happen together.
3. Shared world-state snapshot: derive one render-friendly state from existing
   providers and let each layer read the same priorities.

Use approach 3.

The project is now creative-state heavy: the same screen can be rainy, night,
in Diorama Mode, and interrupted by an S4 alert at the same time. A shared
snapshot keeps those states from fighting each other and makes real-device
verification easier because every screenshot has one explainable state.

## Non-Negotiable Visual Rule

All world objects and particle-like weather visuals must be real raster assets.
Do not draw fake rain, snow, fog, stars, icons, or Mario-world props with
`CustomPaint`, geometry, emojis, or hand-made SVG.

Allowed without extra assets:

- Color temperature, opacity, blur, grayscale, and screen-wide atmosphere.
- Reusing existing extracted SMB raster assets already in `assets/`.
- Text rendered with the existing pixel font for labels that have no valid prop
  representation yet.

Blocked until real assets are sourced:

- Falling rain drops.
- Snowflakes.
- Fog sheets.
- Lightning bolts as drawn geometry.
- Any new Mario-style object that is not extracted from a real source.

This means the first implementation can close the weather loop through mood,
cloud density, labels, existing props, and atmosphere, but not fake particles.

## Core Architecture

Add a small world-state interpretation layer above the existing feature
providers. It should not replace `weatherProvider`, `clockProvider`,
`notificationQueueProvider`, or `creativeModeProvider`; it should derive a
single render-friendly snapshot from them.

Candidate provider:

- `worldStateLoopProvider`

Inputs:

- `weatherProvider`
- `clockProvider`
- `notificationQueueProvider`
- `backgroundDimProvider`
- `creativeModeProvider`
- app theme brightness

Output:

- Effective weather condition and intensity.
- Effective time phase: `morning`, `day`, `dusk`, `night`.
- Effective creative mode.
- Alert phase: `idle`, `entering`, `holding`, `releasing`.
- Diorama density: `minimal`, `normal`, `inspectable`.
- Atmosphere recipe: tint color, vignette strength, dim amount, readability
  priority.

The provider exists so each layer does not independently reinterpret the same
state. L1 Weather, L-1 Atmosphere, L3 HUD, L4 Notification, and L5 controls can
all read the same snapshot and stay visually coherent.

## Loop Definition

Every loop must answer five questions:

1. Entry: what state change starts the loop?
2. World reaction: what changes in the level?
3. Mode behavior: how does Scene / Theater / Diorama present it differently?
4. Exit: when does the state return or settle?
5. Verification: what screenshot proves it is working?

This is the guardrail against adding disconnected decorations.

## Weather Loop

### Shared Behavior

Weather should affect the whole world first, then add specific details only
when real assets exist.

Common outputs:

- Atmosphere tint.
- Vignette and readability strength.
- Weather text in the compact HUD.
- Diorama weather prop state.
- Optional real weather overlay asset when available.

Scene Mode:

- Prioritize broad world mood.
- Keep HUD sparse.
- Weather is the hero when no notification is active.

Theater Mode:

- Weather remains visible but yields to notification readability.
- S3/S4 notification text must stay clear.

Diorama Mode:

- Weather becomes a data object near the ground.
- The pipe/cloud prop group should explain the current condition without
  becoming a card.

### Condition Mapping

| Condition | First implementation with current assets | Later asset-backed upgrade |
| --- | --- | --- |
| Clear | Normal daytime atmosphere, sparse HUD, existing sky visible | Optional sun/star asset only if real source exists |
| Rain | Cooler tint, heavier vignette, cloud/pipe emphasis, RAIN label | Real rain raster overlay, puddle/pipe drip assets if sourced |
| Snow | Pale cold tint, slower/calmer mood, SNOW label | Real snowflake/snow-sheet raster overlay if sourced |
| Fog | Low-contrast atmosphere, stronger softening, FOG label | Real fog sheet/raster overlay if sourced |
| Storm | Darker tint, short screen flash as lighting, STORM label | Real lightning/bolt asset if sourced |

The first implementation should make all five conditions visibly different
without inventing fake weather particles.

## Strong Alert Loop

Severity 4 should feel like the world has entered a locked pause state, not just
a modal over the game.

Entry:

- `notificationQueueProvider.current.severity == severity4`
- `backgroundDimProvider == true`
- `creativeModeProvider` enters locked Theater mode.

World reaction:

- Existing grayscale + blur + darken overlay remains.
- Atmosphere uses alert readability priority, not normal weather beauty.
- Weather effects reduce or pause if they would harm PAUSE readability.
- Theater stage accents should support the alert but never cover the PAUSE text
  or dismiss button.

Hold:

- User's manual Scene / Theater / Diorama choice is preserved underneath.
- Mode switcher may show the locked state, but should not let the user escape
  the alert visually before dismissal.

Exit:

- Dismiss button clears `backgroundDimProvider`.
- Notification queue completes current item.
- Temporary Theater mode clears only after the S4 current item is gone.
- Previous manual mode is restored.

Verification:

- Trigger L4 on TB300FU.
- Screenshot must show the world blurred/grayscaled, PAUSE readable, dismiss
  button reachable, and bottom controls not confusing the alert state.
- After dismissal, screenshot must show the prior mode restored.

## Time Day/Night Loop

Time should be a continuous atmosphere source, not only a number in the HUD.

Phases:

- Morning: 05:00-08:59, slightly warm and bright.
- Day: 09:00-16:59, closest to original SMB palette.
- Dusk: 17:00-19:59, warmer/dimmer but not brown/orange dominated.
- Night: 20:00-04:59, cooler/darker.

Inputs:

- `clockProvider` supplies actual time.
- Theme brightness can still override broad light/dark app behavior, but the
  world-state loop should make the time phase explicit for tests.

Scene Mode:

- Time phase strongly affects atmosphere.

Theater Mode:

- Time phase is secondary to notification readability.

Diorama Mode:

- Time may affect which data props are emphasized, but should not hide the prop
  group.

Verification:

- Widget tests should override time to at least day and night.
- Real-device screenshots should include one daytime and one nighttime/dark
  state before this loop is accepted.

## Data Diorama Loop

Diorama Mode should turn data into level objects that the user can inspect at a
glance. It should not become a bottom sheet, table, or dashboard panel.

Current real assets available:

- `cloud_small.png`
- `pipe_tall.png`
- `flagpole.png`
- `coin_f*.png`
- `block_question_f*.png`
- `block_brick.png`
- `castle.png`
- `starman_f*.png`
- enemies and Mario sprites

Initial data props:

| Data | Object group | Rule |
| --- | --- | --- |
| Weather | pipe + cloud + pixel label | Always visible in Diorama; condition changes atmosphere and label |
| Notification count | coin + flagpole | Count remains compact; S3/S4 can temporarily move focus to Theater |
| Alert state | question block / pause staging | Strong alerts are Theater-first, not Diorama-first |
| Time phase | atmosphere + top clock | Do not add a fake sun/moon until real assets exist |
| Stable/base state | castle | Candidate for later "home base" status |

Layout rules:

- Diorama props sit inside the world, close to ground, avoiding Mario's
  one-third-screen anchor.
- Props should not hide important clouds or the scrolling layer.
- Text is allowed only as a small pixel label attached to a real prop.
- No cards inside the world.

Verification:

- Screenshot in Diorama Mode for at least rain/day and one other weather state.
- Props must not collide with Mario, mode switcher, debug panel, or notification
  overlays.

## Mode Interaction Rules

Scene:

- Default living ornament.
- Weather and time loops are strongest here.
- Data remains compact.

Theater:

- Notification loop is strongest here.
- Weather/time are present but lower priority.
- S3 can temporarily enter Theater.
- S4 must lock Theater until dismissed.

Diorama:

- Data loop is strongest here.
- Weather/time still change the world.
- Notifications can temporarily interrupt with Theater and then restore Diorama.

Manual mode and temporary mode remain separate, as implemented in
`creativeModeProvider`.

## Implementation Decomposition

This scope is too large for a single code pass. It should be implemented as
several complete, verified slices.

### Slice 1: Loop Snapshot Foundation

- Add `worldStateLoopProvider`.
- Derive time phase, alert state, weather condition, and effective mode.
- Add unit tests for provider derivation.
- No major visual churn yet.

### Slice 2: Weather + Atmosphere Closed Loop

- Make clear/rain/snow/fog/storm visibly distinct through atmosphere and
  existing real assets only.
- Wire Scene / Theater / Diorama differences.
- Keep `WeatherLayer` asset-backed and particle-free.
- Update debug controls only if needed for testing all conditions.

### Slice 3: Strong Alert Closed Loop

- Make S4 lock/hold/release behavior explicit in world state.
- Improve Theater alert staging without blocking PAUSE readability.
- Verify previous manual mode restoration after dismissal.

### Slice 4: Time Day/Night Closed Loop

- Make time phase explicit and testable.
- Route atmosphere through time phase plus weather plus alert priority.
- Add tests for day/night rendering inputs.

### Slice 5: Data Diorama Closed Loop

- Expand the current pipe/cloud/flag/coin group into a more coherent data
  station.
- Add one more real-asset-backed object only if it improves meaning.
- Keep Scene sparse and Theater event-focused.

### Slice 6: Real Weather Asset Upgrade

- Source or extract real raster overlays for rain, snow, fog, and lightning.
- Add them to `assets/` with provenance documented.
- Only then render falling particles or sheets in `WeatherLayer`.

## Recommended First Implementation Target

Implement slices 1 through 5 as the next development track. This satisfies the
user's request to include weather, strong alert, day/night, and data diorama
loops in the system now.

Slice 6 is intentionally separated because it depends on finding real weather
raster assets. Until those assets exist, the app must still make every weather
condition feel different through atmosphere, existing props, and labels instead
of fake particles.

## Testing And Verification

Every slice must pass:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- install/restart on TB300FU
- real-device screenshots inspected with the image viewer

Screenshot gates:

- At least Scene / Theater / Diorama after any mode-affecting change.
- All five weather conditions after weather loop changes.
- S4 active and S4 dismissed after alert loop changes.
- Day and night after time loop changes.
- Diorama close inspection after data prop changes.

A slice is not complete just because tests pass. It is complete only after the
real-device screenshot looks intentional and does not cover the clouds, Mario,
notifications, or bottom controls in an ugly way.

## Acceptance Criteria

- All four loop families are represented in one coherent world-state design.
- The first implementation slices can make clear visual progress without fake
  assets.
- Weather conditions are visually distinguishable even before particle assets.
- S4 alert has a full enter / hold / release loop and restores prior mode.
- Day/night is testable and visible as atmosphere, not only theme brightness.
- Diorama data appears as Mario-world props, not dashboard panels.
- No new visual element violates the real-asset rule.

## Open Decisions For Later

- Exact source for real weather raster assets.
- Whether Mario should gain weather-specific reaction sprites beyond existing
  stand/jump/skid/run frames.
- Whether the castle should represent "stable/home" data in the first data
  diorama expansion.
- Which real notification integration should be wired after the view layer is
  stable.
