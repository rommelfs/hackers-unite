# Hackers Unite project handoff

Updated: 2026-09-02

## Purpose

This file transfers the technical context of the existing Codex session to a fresh session or another account. The new session should read this file, `AGENTS.md`, `README.md`, and the phase reports before implementing further work.

Hackers Unite is a native, standalone Commodore 64 platform game inspired by the feel of colorful European C64 platformers without reproducing protected names, characters, graphics, levels or recognizable maps. Its own visual vocabulary is derived from the user-supplied hack.lu 2026 banner and circular logo. The documented exception for music is Jesper Jensen's `Madness (part 1)`, used with permission reported by the project owner and credited in `docs/CREDITS.md`.

Project directory:

```text
/Users/rommelfs/Hacking/Code/Hackers Unite
```

The older sibling project `Hacky Bros.` is a separate prototype and must not be confused with this project.

## User expectations learned during development

The user values actual playability over a technically animated proof of concept. A screen that only reports input is not gameplay. In particular:

- the player must always be visible and clearly readable;
- landing must align exactly with platforms, never in mid-air or inside them;
- platforms must remain physically and visually stable while jumping;
- left/right traversal must be logically continuous;
- scrolling must be smooth and must not expose stale columns or top-right artifacts;
- level geometry must be traversable and items must be reachable;
- every phase should be tested in VICE and visually inspected, not merely assembled;
- visual quality must not be sacrificed silently for a mechanical improvement.

When reporting completion, lead with what is playable and what was verified. Do not describe a static diagnostic screen as a game milestone.

## Current implementation: conference-route power-up/finale increment

Phase 15 rebuilds the auditorium around a continuous lower recovery aisle and two
optional upper running-jump waves. Both branches have explicit reachable row-7
entries and rejoins; their row-6 tiers are approached from above-ground landings,
never by an impossible ground jump. TRIGGER moves to X 792 on the final landing.
The layout table now contains 174 records. See `docs/PHASE_15_REPORT.md`.

Phase 14 rebuilds the foyer as the first platformer-first teaching level without
changing the confirmed movement model. Its safe opening introduces ENTRY, then a
patrol, then the first isolated cable; later PAYLOAD and TRIGGER rewards occupy
wide elevated rows separated by recovery ground. The auditorium restores denser
chair banks and its own platform rhythm rather than inheriting the foyer layout.
The reversible layout table now contains 174 records and retains the 16-record
frozen-frame application cap. See `docs/PHASE_14_REPORT.md`.

The three-layout vertical slice now reads as foyer to auditorium chair rows to
stage rig. Three bounded pickup slots select four data-driven effects—rapid fire,
power shot, speed boost and extra life; temporary effects expire after five PAL seconds and
clear on damage. A five-state frozen talk finale walks to the lectern, activates
the projector, presents a fictional RCE-success beat, triggers applause, and waits
at `TALK COMPLETE` for ranked replay. See `docs/CONFERENCE_ROUTE_REPORT.md`.

Phase 12 has begun. Cold boot presents a `HACK.LU 2026` mission briefing naming
the stage goal and three fictional PoC components; Fire enters gameplay through a
staged Screen A/B rebuild. The player and object sprites are hidden on the briefing,
AUTOTEST bypasses it, and the live item field identifies `FOYER`, `HACKLU`, or
`STAGE`. See `docs/PHASE_12_REPORT.md`.

The expanded hotel and conference route manifest is not implemented. Runtime
gameplay beneath the narrative shell remains the Phase-11 three-layout foundation.

The latest Phase-12 readability pass gives every landable elevated metatile a
continuous bright lip and full-height supports, makes walls closed and cross-braced,
and removes non-colliding fallen-chair decoration from the foot line. The asset
manifest and validator enforce explicit solid/hazard/decoration groups. Damage
recovery now freezes gameplay, resets the camera, rebuilds Screen A and Screen B at
the section start in eight-row slices, and only then places and republishes the
player spawn. Do not collapse those slices back into a full live-frame render.

Phases 1-11 are implemented.

### Runtime foundation

- BASIC-autostartable PRG at `$0801`.
- ca65/ld65 project with explicit linker configuration.
- PAL-oriented 50 Hz VIC-II raster IRQ.
- Saturating one-frame scheduler and dropped-frame counter.
- Port-2 joystick sampling with held and newly pressed states.
- Debug border profiling; release profiling writes are removed at assembly time.

### Graphics and world

- Project-owned 2 KiB multicolor character set.
- Thirty-five 2x2-character metatiles with separate character, color, and behavior tables.
- 64x12-metatile world expanded to 128x24 characters.
- Screen A at `$4000`, Screen B at `$4400`, charset at `$4800`.
- Per-buffer camera-column tracking with reversal-safe one/two-column hidden-window shifts, then `$D018` flip.
- `$D016` fine scrolling in 38-column mode.
- Raster split at lines 48 and 240 for a scrolling playfield and fixed status area; line 48 coherently publishes screen, fine scroll and sprite shadows and queues the logical frame.
- Static Color-RAM zones with zero steady-state Color-RAM writes during scrolling.

### Player and camera

- Hardware sprite 0 is permanently reserved for the player.
- Four multicolor frames: idle, walk A, walk B, jump.
- Signed 4.4 velocity and 16-bit 12.4 world positions.
- Horizontal and vertical motion/collision are resolved separately.
- Fixed collision box independent from sprite animation.
- Two-point leading-edge probes against metatile `SOLID` flags.
- Exact wall, ceiling, and landing correction to tile boundaries.
- Acceleration, friction, gravity, speed-sensitive jump impulse, fall-speed limit, level clamps, and respawn guard.
- Camera comfort window is screen X 112-199.
- Standing jumps rise about 31 pixels; at `|vx| >= 1.0` pixel/frame the run-up jump rises about 52 pixels and reaches the 48-pixel platform tier.
- Camera correction is capped at two pixels but moves only the exact comfort-window excess, eliminating the old two-pixel/stop sawtooth.
- Up/up-left/up-right jump. Down selects a low collision stance and down-left/down-right crawl at 0.5 pixel/frame; standing requires two clear shoulder probes.
- Two low-profile stance frames preserve the authoritative feet position.

### Gameplay objects and game loop

- Seven stable SoA object IDs: four possible ground enemies plus access-key, data bonus and 1-Up IDs that retain their original persistence bits.
- Camera-margin activation sleeps objects outside `camera-32 ... camera+351`.
- Hardware sprites 1-7 render the bounded active set; player sprite 0 remains exclusive. There is still no multiplexer.
- All object interaction uses fixed software AABBs.
- One mutable block is an authoritative patch at metatile `(10,8)` and refreshes its four cells in both cached buffers when changed.
- One-byte persistence masks retain collected/defeated state across sleeping, scrolling and Screen A/B flips.
- Score, lives, damage cooldown, respawn, a nine-second Continue and a separate game-over/new-game state are implemented. Continue preserves score, current level and danger rank while restoring three lives and resetting the current section.
- Pickup-looking map decorations were removed: every visible key/bonus/1-Up motif is now an interactive sprite, avoiding false affordances.
- Level 1 activates two enemies; Level 2 activates four. The final two Level-2 patrols move every frame instead of every second frame.
- Fire launches one cooldown- and lifetime-bounded horizontal shot. Fire+Up throws a high ballistic bomb; Fire+Down throws a descending bomb. All modes collide with the authoritative map and fixed enemy AABBs and deterministically share the highest free hardware sprite slot. Fire+Up suppresses jumping for that input chord.
- Level-2 enemy ID 5 is a vertically bobbing drone. ID 6 is a large multi-hit armored-eye boss with a fixed software box, short hit invulnerability, warning flash, autonomous bounded arena patrol and a low-health rage step. It no longer retargets its body movement from player X every frame.
- Straight shots retain their physical hand-height coordinate and draw in the sprite cell's top rows. Bombs use separate pointer `$49` artwork, signed vertical velocity and gravity every fourth frame.
- Visible row-9 spike metatiles carry a dedicated non-solid `HAZARD` flag. Fixed foot probes damage and respawn the player without turning traps into collision walls. Spike and electrical graphics now fill the complete 16-pixel metatile height with large bright triangular/zigzag shapes.
- Level 3 adds visually distinct electrical floor traps with the same authoritative non-solid hazard contract. Spikes and electrical arcs are no longer ambiguous with ordinary floor trim.
- Level 3 repurposes object IDs 5 and 6 as deterministic action hazards: falling material has a 50-frame map-warning phase with no sprite or collision box before cycling through three lanes, while a large ball rolls left along the floor and accelerates at higher ranks. Neither can be stomped or shot.
- Once the Level-2 pickups free the required sprite slot, the boss fires a bounded alternating-height energy orb. Its reload shortens at rank 8 and again during the boss rage phase.
- Player attacks damage the boss only inside its 28x17-pixel central weak core. The former 72-pixel vertical acceptance was removed; blind floor-height shooting now misses, while aimed shots and bomb arcs can cross the core.
- The mutable block is a genuine secret: its one allowed hit reveals a 1-Up and awards 100 points.

### Objective, transitions, three layouts and sound

- The three pickups are the level objective; Level 2 then reports the boss HP and keeps the exit closed until the boss is defeated.
- A green data portal at world pixels 944-1007 opens logically after all three persistence bits are set. Pressing up inside its zone enters `LEVEL CLEAR` and awards 200 points.
- Fire advances through Level 1, Level 2 and Level 3. Object and mutable-block state reset, player/camera return to the start, and layout patches plus Screen A/B rebuild over frozen loading frames before simulation resumes.
- Level 2 selects its records from the reversible three-layout table and updates both the authoritative map and expanded character world. Its key, data bonus and 1-Up sit at world `(140,91)`, `(470,91)` and `(792,91)` on three 48-pixel platform tiers that require running jumps.
- Level 3 is a red/yellow industrial warning world with distinct factory platforms, overhead warning panels, electrical traps, falling debris and a rolling ball. Its key, data bonus and 1-Up sit at world `(280,91)`, `(520,91)` and `(760,75)` on a new traversal route.
- The three-layout table has 174 seven-byte records. Runtime `LOAD_LAYOUT` applies at most 16 records per frozen frame, followed by `LOAD_A`, `LOAD_B` and `LOAD_READY`; cold boot may apply the complete table before IRQs start.
- The status row identifies `L1`/`L2`/`L3` and the low byte of a persistent 16-bit danger rank as `Rxx`. Every cleared section increments the rank. Completing Level 3 enters a short `SYSTEM OK` state; fire cycles into Level 1 without resetting score, lives or rank.
- Cycles are endless. Rank 2 adds the drone to Level 1, later thresholds increase patrol and rolling-ball steps, every Level-2 visit increases boss durability up to the byte-sized hardware ceiling, and the boss pattern speeds up at defined thresholds.
- Level 2 has a three-metatile crawl-only conduit whose upper row blocks standing while its foot corridor remains clear.
- Jesper Jensen's `Madness (part 1)` PSID soundtrack is used with permission reported by the project owner. Its original init `$1800` and play `$1806` routines run at PAL/VBI rate exactly once per logical frame.
- Prioritized jump, pickup, enemy, damage, block and clear effects temporarily override voice 1 after the tune player runs; the tune retains all three-voice state on following frames.

Controls: joystick port 2; up/up-left/up-right jump, down ducks, down-left/down-right crawl, Fire shoots, Fire+Up throws a high bomb, and Fire+Down throws a descending bomb. Up enters the unlocked portal. Fire advances from `LEVEL WIN`, restarts after `SYSTEM OK`, accepts `CONTINUE`, or starts a fresh campaign after `GAME OVER`.

## Most recent regression and fix

The user reported unreachable platforms and strong horizontal-scroll stutter.

The original jump impulse rose only about 31 pixels, while the first elevated tier requires a 48-pixel rise. Fire now selects a 52-pixel running jump once horizontal speed reaches one pixel/frame; the standing jump stays unchanged. The short automated path must register both a running jump and a landing above the floor.

The scroll stutter had three coupled causes. Gameplay was queued at raster line 240, so a coarse rebuild could cross the next line-48 publish. The camera always corrected by two pixels and then stopped, producing a sawtooth against the player's 1.5-pixel maximum. Sprite registers were also updated separately from the screen/fine-scroll state.

Gameplay is now queued immediately after line 48, leaving one complete PAL frame to prepare the next state. Screen A/B retain independent camera-column tags and use fast one/two-column hidden-buffer shifts with exposed-column repair; reversal can reuse an already matching buffer. Camera correction moves only the actual comfort-window excess. Screen, `$D016`, and shadowed sprite coordinates publish together at line 48. `main_busy` makes a missed deadline a test failure.

The initial Phase-7 layout put the platform spanning X 736-799 on metatile row 8, creating a solid wall directly beside/around the last Level-2 item at X 760. It was visually present but unreachable through the authoritative collision map. That platform now sits on row 6. The asset validator enforces that ground-corridor rows 8 and 9 contain no solid map tiles in either layout.

After Phase 8, the user reported that the second enemy survived an apparent landing. Tile collision runs before object collision, so an exact floor-frame landing could snap player Y to the enemy's Y and reset VY before the stomp test. The runtime now records whether the player entered the frame airborne. Equal-height contact is a stomp only in that airborne landing frame; grounded side contact still damages. The smoke test exercises this case for enemy IDs 0, 4, 5 and 6.

## Phase-11 additions

Phase 11 answers the request for clearer traps and more classic platform action without weakening the fixed-frame architecture. The third world has an unmistakable warning palette and geometry, two distinct static trap graphics, telegraphed falling blocks, a rolling floor hazard and a projectile-firing boss. Action sprites use reserved aligned cells at `$5440-$54FF`; collision remains fixed-box software logic rather than artwork-derived contact.

The original full 148-record layout application missed the PAL line-48 deadline. It was replaced by the staged 16-record loader described above; the current table contains 174 records after the two-route auditorium split. This is a deliberate performance invariant, not merely transition presentation.

The latest playability pass makes static hazards full-height and brighter through shared background-2 ink, removes the falling block entirely during its warning interval, replaces magnetic boss tracking with bounded back-and-forth patrol, narrows boss damage to its visible core, adds two ballistic bomb throws, and inserts a classic nine-second Continue before final Game Over.

The subsequent collision correction replaces the Level-2 boss body's broad absolute Y-distance test with directed 21-pixel player and 42-pixel boss boxes. Standing on the platform at Y=91 leaves a real gap above the boss at Y=118 and cannot damage it; a descending player must actually enter the boss's upper eight pixels to stomp. Regular projectiles now test the complete directed 24x21 small-enemy box instead of an asymmetric 18-pixel distance, including its visible right edge. Boss-core projectile logic remains exclusive to Level 2.

The L03R02 readability revision changes Level 3 from nine isolated floor traps to three two-metatile warning fields at columns 8-9, 22-23 and 37-38. Long safe approach and landing stretches separate them, and every falling-object lane has at least two clear floor columns on either side. Trap glyphs use only black plus the global red/yellow warning inks in Level 3—never the green floor ink—so safe ground and damage tiles remain visually distinct.

## Test status

Last verified on 2026-08-18 with cc65 2.19/Homebrew (ca65 identifies itself as V2.18), VICE `x64sc` 3.10, and PAL timing.

Commands and results:

```sh
make build test
# asset validation: OK
# host checks: OK
# VICE PAL smoke test: OK

make soak
# VICE PAL soak test: OK
# 7,680 frames / 153.6 emulated seconds

make disk
# release D64 regenerated successfully
```

The smoke test additionally verifies the boss orb, autonomous boss patrol, an explicit blind-shot miss and weak-core hit, the collision-free platform gap above the boss, the complete small-enemy projectile box, both bomb input modes, three-layout staging, full-height electrical/spike flags and contrast, the collision-free falling warning, falling-material and rolling-ball cycles, Continue acceptance and timeout, Level-3 completion, rank-3 restart, the eight-hit rank-1 boss, boss-gated exit, SID behavior, and the lives-to-game-over path. The soak test repeatedly reverses near both world ends, jumps every 64 frames, exercises objects, projectile scheduling, collision, camera tracking, fine scrolling, cached shifts, Screen A/B flips and both SID ticks, and fails on any dropped frame or missed line-48 deadline.

Visual confirmation: `build/l03r02-readable-traps.png` for the grouped red/yellow hazard field, safe green/cyan floor, aligned sprites, intact status split and absence of VIC artifacts. `build/phase11-clear-traps.png` preserves the earlier comparison state; other movement, pickup, boss and soundtrack screenshots remain available. Outer-border colors in automated screenshots are intentional Debug profiling.

Current release artifacts:

- `release/hackers-unite.prg` — 39,426 bytes
- `release/hackers-unite.d64` — 174,848 bytes
- `release/hackers-unite.map`
- `release/hackers-unite.lbl`

The authorized SID payload occupies `$1800-$24D2` and reserves work cells through
`$2502`. Runtime BSS begins at `$2600`, projectile code remains fixed at
`$5500-$5754`, the Phase-13 sliced respawn renderer and its mutable-block overlay
helper have their own linker window at `$5800`, primary game code begins at
`$6000`, and read-only data begins at `$8000`.
BASIC ROM is disabled after startup so automated code at `$B000` is visible;
KERNAL and I/O remain mapped.

## Important files

| File | Responsibility |
|---|---|
| `src/startup.s` | boot, BSS clear, subsystem initialization |
| `src/state.s` | zero-page and mutable runtime state |
| `src/irq_phase3.s` | two-event raster IRQ and coherent publication of all eight sprites |
| `src/scheduler_phase3.s` | fixed-order main loop and automated checks |
| `src/input.s` | joystick port 2 decoding |
| `src/tiles.s` | charset install, tile helpers and reversible level-layout application |
| `src/scroll.s` | camera, fine scrolling, cached coarse shifts, buffer flip |
| `src/physics.s` | player input, fixed-point motion, tile collision |
| `src/objects.s` | seven-object SoA, level population, patrols, AABB collision, persistence and sprites 1-7 |
| `src/projectile.s` | shot lifecycle, map/enemy collision and dynamic free-sprite rendering |
| `src/boss_attack.s` | bounded Level-2 boss orb lifecycle, collision and sprite publication |
| `src/game.s` | score, lives, damage, objective, level states and staged transitions |
| `src/sound.s` | 50-Hz imported SID bridge and prioritized voice-1 gameplay effects |
| `src/sprites.s` | sprite RAM setup, animation pointer and VIC coordinates |
| `src/vic_phase3.s` | VIC bank/mode/palette/status configuration |
| `src/assets.s` | links generated binary assets into the PRG |
| `tools/build_c64_assets.py` | deterministic charset, map, metatile, and sprite generation |
| `tools/validate_assets.py` | dimensions, palette, index, flag, and color-cost validation |
| `tests/host_checks.sh` | binary/layout/symbol assertions |
| `tests/vice_smoke.sh` | deterministic short PAL emulator test |
| `tests/vice_soak.sh` | 7,680-frame PAL stress test |

Further documentation:

- `docs/MEMORY_MAP.md`
- `docs/GRAPHICS_FORMAT.md`
- `docs/RASTER_BUDGET.md`
- `docs/VISUAL_LANGUAGE.md`
- `docs/CREDITS.md`
- `docs/PHASE_1_REPORT.md` through `docs/PHASE_11_REPORT.md`
- `docs/TEST_REPORT.md`

## Visual sources

The untouched supplied references are:

- `assets/reference/hacklu-2026-banner.png`
- `assets/reference/hacklu-2026-logo.png`

Key motifs are the broken monumental 2 and 0, green data vortex, spider camera, flying camera, padlock, onion, chain link, CRT pedestal, cables, and ruined skyline. The preferred palette is black, dark grey, muted olive, cyan, and active-system green, with red/blue reserved for warnings and lights.

Generated visual sources and motif crops are under `assets/source/`; packed C64 data is under `assets/c64/`. Run `make assets` to regenerate derived visual assets and `make validate-assets` to validate packed game data.

## Known limitations

Phase 11 supplies a third themed action world and a projectile-pattern boss, but this is not yet a content-rich full game:

- regular enemies reuse one base artwork and do not shoot;
- Level 3 has a separate palette, traversal and hazards but still shares the common world extent and portal framework; there is no hidden room or bonus level;
- only one falling block and one rolling ball can be active because they deliberately reuse the bounded seven-object pool;
- the final ending is a compact status state, not a dedicated ending screen; there is no title screen;
- the internal danger rank is 16-bit and cycles indefinitely, but finite movement speed and one-byte boss HP necessarily saturate; the status displays only its low byte;
- no sprite multiplexer;
- PAL only;
- no real-hardware verification yet.

The project directory currently has no Git repository. Create version control before broad future changes if the user approves; do not assume rollback is available.

## Recommended next Phase-12 increment

The approved redesign direction is formalized in `docs/GAME_REDESIGN.md`: the
player travels from a hotel origin through recognizable hack.lu conference spaces,
completes a fictional three-part RCE PoC for placeholder Product X, and reaches the
stage to give the talk. Follow its incremental delivery steps rather than
attempting a single wholesale conversion.

The campaign remains level-based and now has four proposed origin routes: hotel
entrance, hotel room, restrooms, or bar. They converge through some or all of the
hotel corridor, lobby/chill-out area, hack.lu main-room entrance, registration,
and conference-room/stage route. The supplied hack.lu 2026 identity must make the
shared conference spaces clearly recognizable without copying a real hotel floor
plan or depicting real people. Because the runtime currently has only three
layouts, first build a three-level vertical slice; expanded route-manifest,
loading, persistence, memory, and test work must precede the full location list.

New and even grotesque fictional enemy families are allowed when they add readable
behavior, fit the fixed budgets, and preserve a validated damage-free mandatory
route.

Phase 12 should begin with the route manifest, narrative shell, and HUD, followed
by the reusable hack.lu identity kit and the three-layout vertical slice. If the
goal is materially more simultaneous enemies or action objects, design and budget
an explicit sprite multiplexer first; do not silently overbook the existing
eight-sprite publication contract.

## Suggested first prompt in the new session

```text
Read AGENTS.md, docs/PROJECT_HANDOFF.md, and docs/GAME_REDESIGN.md completely.
Inspect the Phase-12 narrative shell, Phase-11 gameplay foundation, and test
harness. Then implement and validate the selected three-layout route slice,
preserving all scrolling, collision, persistence, audiovisual, memory-layout, and
PAL timing contracts.
```
