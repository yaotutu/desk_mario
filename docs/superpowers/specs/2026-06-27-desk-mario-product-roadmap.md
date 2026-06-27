# DeskMario Product Roadmap

Date: 2026-06-27

## North Star

DeskMario is a horizontal desktop ornament app, not a normal dashboard skin. The first reaction should be: "This is a living Mario diorama on my desk." The second reaction should be: "It also quietly tells me useful things."

The product has three pillars:

1. Playfulness: NES Super Mario Bros. elements should feel alive and composed, not pasted on.
2. Ambient data: time, weather, battery, notifications, focus/session state, and later real integrations should appear as world objects.
3. Notifications: messages should be staged as small performances with severity, not as generic app toasts.

This roadmap is view-first. Real data integrations are later. Every phase must remain shippable and visually verifiable on the TB300FU Android device.

## Non-Negotiable Rules

- Do not draw Mario-world assets. All sprites must come from real raster sources already in the project or explicitly added as real source assets.
- If an effect is not a Mario-world object, still prefer real raster overlays/assets. Pure Flutter lighting/compositing is allowed for atmosphere, flashes, blur, grayscale, and opacity.
- Preserve the 6-layer stack:
  - L0 world
  - L1 weather
  - L2 character
  - L3 HUD/data objects
  - L4 notifications
  - L-1 atmosphere rendered above L4 per existing design
  - L5 debug/system
- Every UI/animation/interaction change must end with Android screenshot verification.
- Tests must use fixed `pump(Duration)` calls, never `pumpAndSettle`.

## When To Ask The User

Ask only when the answer changes product direction or legal/source choices:

- Whether to add external asset sources beyond the existing local sprite-resource sheets.
- Which real notification source to support first when moving beyond mock data.
- Whether DeskMario should stay strictly NES SMB1 or allow related real Mario-era assets.
- Which always-on data is personally important enough to occupy first-screen space.

Do not ask for ordinary implementation choices such as file split, test shape, provider names, or debug controls.

## Phase 1: View System Becomes Demonstrable

Goal: make the existing view layer feel like a complete prototype that can demo the product direction without real data.

Deliverables:

- A richer real-asset library extracted from `assets/backgrounds/smb_world_minus1.png`.
- Debug controls for cycling weather states and notification demos.
- Stable mock providers for weather, message count, and later battery/focus values.
- A coherent L3 world HUD with data grouped into object zones, not generic cards.
- Golden and Android screenshots for each important state.

Acceptance:

- A viewer can understand what the app wants to become from one live run.
- Debug Panel can demonstrate weather, theme, and notification states without code edits.
- No fake Mario-world assets appear.

## Phase 2: Real-Asset World Objects

Goal: build a small set of reusable world-object widgets from real sprites.

Candidate objects from the existing stage sheet:

- Pipe dock: vertical pipe/cap used as a data station.
- Castle/object endpoint: long-term status or "home" marker.
- Flagpole marker: progress/focus/timer indicator.
- Coin/brick/question block row: counts and small values.
- Cloud-backed label: lightweight sky label when the sheet already contains cloud sprites.

Implementation:

- Add `tools/extract_stage_sprites.py` with documented crop coordinates.
- Output cropped PNGs into `assets/sprites/`.
- Update `docs/sprites.md` with source coordinates for every new asset.
- Add reusable widgets under `lib/shared/widgets/` or feature-owned folders only when there is a clear owner.

Acceptance:

- Each asset has a documented source rectangle.
- Each widget can be understood by reading its public constructor.
- Golden tests catch accidental layout drift.

## Phase 3: Weather As A Scene State

Goal: weather changes the feeling of the whole world.

Scope:

- Clear: normal world.
- Rain: render only from real raster rain/drop overlay assets or an explicitly approved real source. If none exists, show HUD state only.
- Snow: same asset rule as rain.
- Fog: real raster overlay or compositing from a real source asset.
- Storm: real rain/fog assets plus allowed lightning flash overlay.

Implementation:

- Weather provider becomes a small state model with `condition`, `temperatureC`, and `intensity`.
- Debug Panel exposes weather selection.
- L1 Weather renders only asset-backed visuals.
- L-1 Atmosphere may tint/flash through existing compositing, not new sprites.

Acceptance:

- User can switch weather without restarting.
- Weather never intercepts L5 debug clicks.
- Weather sits behind Mario/HUD/notifications.

## Phase 4: Notification Performances

Goal: notifications feel like Mario-world events.

Scope:

- Severity 1: small ambient sprite cue.
- Severity 2: sign/block/banner that does not dominate.
- Severity 3: character/dialog performance.
- Severity 4: pause/alert world freeze, already partially implemented.

Implementation:

- Make each severity state visually distinct and collision-tested with HUD.
- Add debug test cases for queueing and overlap.
- Keep L4 queue semantics intact.

Acceptance:

- Queued notifications never overlap incoherently.
- Severity 4 keeps lower world frozen/blurred while alert stays readable.

## Phase 5: Data Integration Shell

Goal: connect real data without rewriting the view layer.

Scope:

- Weather API or local mocked adapter.
- Battery and network status.
- Real notification source chosen by the user.
- Focus/timer/session state if useful.

Implementation:

- Providers expose semantic view models, not raw API payloads.
- Views keep working with mock providers in tests.
- Data failures degrade to SMB-world placeholder states.

Acceptance:

- App still looks intentional when data is missing.
- Real sources can be swapped without changing L3/L4 widgets.

## Immediate Next Slice

Start with "Demo Control + Real Asset Library":

1. Add documented sprite extraction for pipe/castle/flag assets from the existing stage sheet.
2. Update `docs/sprites.md` with exact source rectangles.
3. Add weather selection controls to Debug Panel.
4. Add tests proving weather can switch through the debug UI and the HUD updates.
5. Run analyze/tests and Android screenshot verification.

This slice strengthens the product without requiring external data or external assets.
