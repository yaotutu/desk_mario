# DeskMario Creative Mode System Design

Date: 2026-06-27

## Goal

DeskMario should feel like a living Super Mario Bros. desk diorama, not a
normal dashboard with Mario styling. The next creative layer keeps all three
directions approved by the user:

1. Scene-reactive world: weather/time changes the whole level mood.
2. Notification theater: messages appear as Mario-world events.
3. Data prop diorama: persistent data becomes real Mario objects.

The user should be able to switch between these focuses through a bottom-right
mode control. The app can also temporarily switch focus when a notification
needs attention.

## Product Principle

The three modes are not separate pages. They are three lenses over the same
world:

- Same `LayeredScaffold`.
- Same Mario running anchor.
- Same scrolling world.
- Different emphasis, density, and animation rules.

This avoids three competing screens and keeps the desk ornament coherent.

## Mode Overview

### Scene Mode

Scene Mode is the default atmospheric lens. Its job is to make the app feel
alive even when nothing urgent is happening.

Visible emphasis:

- Weather affects the broad scene: sky tint, atmosphere, permitted real raster
  rain/snow/fog assets, and small Mario reactions.
- Time of day can affect palette and ambient lighting.
- HUD remains compact and transparent so clouds and sky stay visible.
- Data objects are minimal; only essential time/weather/message count remains.

Allowed effects:

- Existing atmosphere tinting and compositing.
- Real raster weather overlays or sprites when sourced.
- Lightning flash as a lighting effect, not as a new drawn Mario-world sprite.

Not allowed:

- Fake drawn particles.
- Full-width HUD masks.
- Large static data docks that dominate the scene.

### Theater Mode

Theater Mode is the notification lens. It appears when the user manually
selects it or when a notification temporarily asks for attention.

Visible emphasis:

- Notifications become staged events: coin sparkle, question block pop, sign
  reveal, dialog performance, or pause/freeze.
- The world can dim, slow, blur, or freeze depending on severity.
- Mario can visually react when useful: pause, look toward the event, or keep
  running for low severity.
- Persistent data recedes while the event is active.

Severity mapping:

- S1 ambient cue: small sprite pulse, coin glint, or subtle object bounce.
- S2 world sign: wood sign, block banner, or small stage prop.
- S3 dialog event: character/dialog box with typewriter text.
- S4 pause alert: existing freeze/gray/blur treatment, with alert foreground
  kept clear and readable.

Mode behavior:

- Manual Theater Mode shows recent or queued notification state.
- Automatic Theater Mode is temporary: switch in, play the event, then return
  to the user's previous mode unless the alert remains active.

### Diorama Mode

Diorama Mode is the persistent data lens. It is calmer and more inspectable
than Theater Mode.

Visible emphasis:

- Data is represented as real Mario props placed in the world.
- Objects should look like part of the level, not stickers.
- Layout density can be higher than Scene Mode but should still preserve
  Mario and scrolling-world readability.

Initial data-to-object map:

| Data | Candidate object | Meaning |
| --- | --- | --- |
| Weather | cloud label, sky object, pipe steam if real asset exists | Current condition and temperature |
| Notifications | coins, question block, small sign | Count and pending importance |
| Focus/progress | flagpole | Progress climbing or flag position |
| Long-running/system state | castle | End state, home base, or stable status |
| Battery/network | pipe dock or coin meter | Utility status without app-like widgets |

Only use extracted or existing real raster assets. If no suitable real object
exists, show the data in the transparent HUD until the asset is sourced.

## Bottom-Right Mode Control

The control lives in L5 or a dedicated high interaction layer so it remains
reachable above all visual effects.

Default collapsed state:

- A small pixel-style button in the bottom-right corner.
- It must not cover Mario, major notifications, or the debug gear in developer
  builds.
- Short press cycles: Scene -> Theater -> Diorama -> Scene.

Expanded state:

- Shows three compact choices: Scene, Theater, Diorama.
- Each choice uses a compact icon-like label, not a large app panel.
- The current mode is visibly selected.

Automatic mode switching:

- S1 and S2 notifications do not force a mode change unless the user is already
  in Theater Mode.
- S3 can temporarily switch to Theater Mode for the dialog performance.
- S4 must switch to Theater Mode and remain there until acknowledged.
- After temporary switch ends, restore the user's previous manual mode.

State model:

- Track `manualMode`: the user's selected mode.
- Track optional `temporaryMode`: system-owned override with reason and expiry.
- Effective mode is `temporaryMode ?? manualMode`.

This avoids losing the user's preference when notifications occur.

## Layer Responsibilities

The existing six-layer architecture remains intact.

L0 Scrolling World:

- Owns background and ground only.
- Future prop placement can be added only when the prop is truly part of the
  scrolling world.

L1 Weather:

- Renders only real asset-backed weather effects.
- Reads weather and effective creative mode.
- Scene Mode can render the richest weather treatment.
- Theater/Diorama can reduce weather intensity if it harms readability.

L2 Character:

- Mario keeps the one-third-screen anchor.
- Future mode reactions should be small and state-driven.
- Do not move Mario around just to make space for UI.

L3 HUD/Data:

- Transparent top HUD remains the baseline.
- Scene Mode keeps it sparse.
- Diorama Mode can reveal more prop-backed data objects.
- No full-width background mask.

L4 Notifications:

- Owns severity performances.
- Can request temporary Theater Mode.
- Keeps current queue semantics.

L5 Controls:

- Owns debug panel and user mode switcher.
- Mode switcher must stay usable during non-critical effects.
- S4 alert may keep only the acknowledge path and critical controls available.

## Creative Rules

- Prefer a Mario-world cause for every data display. Example: "message count"
  can be coins or a question block instead of a numeric badge.
- Keep one hero subject per moment. In Scene Mode the hero is the world; in
  Theater Mode the hero is the event; in Diorama Mode the hero is the data
  object group.
- Do not solve readability by covering the scene. Use position, outline,
  timing, temporary focus, and real props first.
- If an element looks pasted on, either make it part of a mode-specific stage
  event or remove it from the first pass.

## First Implementation Slice

The first slice should prove the system without overbuilding it:

1. Add `creativeModeProvider` with `manualMode`, optional `temporaryMode`, and
   computed effective mode.
2. Add a bottom-right mode switch control with collapsed cycle and expanded
   three-option state.
3. Wire effective mode into L3 HUD and L4 notification overlay only.
4. Keep Scene Mode visually close to the current app.
5. Make Theater Mode visibly emphasize existing notification demos.
6. Make Diorama Mode reveal one or two real prop-backed data objects using
   existing extracted assets.
7. Add tests for mode switching and temporary notification override.
8. Verify on TB300FU with screenshots for all three modes.

Defer richer weather and more object mappings until the mode framework is
stable.

## Open Decisions For Later

These should not block the first implementation slice:

- Whether to source additional real weather assets beyond the current sheets.
- Whether to add mode-specific Mario animation states beyond existing run/stand
  sprites.
- Which real notification integration should drive Theater Mode first.
- Which always-on data deserves permanent Diorama Mode space.

## Acceptance Criteria

- The user can switch Scene, Theater, and Diorama modes from the bottom-right
  control.
- No mode hides the core scrolling world with a full-width overlay.
- Theater Mode makes existing notification severities feel more like events.
- Diorama Mode uses only real extracted or existing raster assets.
- Automatic notification mode switching restores the previous user-selected
  mode afterward.
- `flutter analyze`, `flutter test`, and Android screenshot verification pass.
