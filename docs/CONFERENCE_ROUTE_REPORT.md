# Conference-route gameplay increment

## Repository and architecture assessment

The game remains native ca65/ld65 6510 assembly with a BASIC `SYS 2061` boot
stub. `startup.s` initializes the VIC, IRQ and BSS; `scheduler_phase3.s` runs the
single deterministic 50 Hz simulation. Rendering uses generated multicolor
characters, 2x2 metatiles, two screen buffers and hardware sprites. Collision is
software AABB plus generated metatile flags. The asset pipeline is
`tools/build_c64_assets.py` to packed files in `assets/c64`; host scripts and PAL
VICE smoke/soak runs form the test workflow. Music is the authorized imported
`Madness (part 1)` SID with one play call per logical frame.

The baseline already supplied movement, scrolling, crouching, three attacks,
patrols, a boss, static and action hazards, persistence, lives/continue, scoring,
three staged layouts and an entrance briefing. It lacked four typed temporary
power-ups, a weapon/effect HUD and the requested multi-state talk payoff.

## Visual and interaction grammar

The level is one conference journey in three acts:

1. **Foyer:** safe entrance, low chair rows, separate aisles, two isolated cable
   traps and early rapid/strong/speed teaching pickups.
2. **Auditorium:** alternate floor, seat and elevated routes, a crawl route,
   denser cables, blockers, a drone and the large AV gatekeeper.
3. **Stage rig:** warning panels and red/yellow rig hazards, bounded falling and
   rolling threats, gantries, a final recovery set and the framed projection wall.

Solid geometry has closed silhouettes and bright continuous lips. Background
chairs are dark and `DECORATION`; open spike/arc shapes are only `HAZARD`; the
stage has a cyan projection fill. Pickups use three bounded hardware-sprite slots
with distinct silhouettes, colors and an eight-frame white pulse; the layout table
selects their meanings. Collision remains
fixed-box and each persistence bit is set before its effect runs.

## Power-ups

The `powerup_types` table maps each layout's three pickup slots to four effects:

- **Rapid fire:** four-frame reload, five-second duration.
- **Power shot:** brighter shot moving six instead of four pixels per frame and
  dealing two core damage to the gatekeeper, within the bounded projectile budget.
- **Speed boost:** controlled top speed rises from 1.5 to 1.75 pixels per frame for
  five seconds while existing friction remains active.
- **Extra life:** increments lives and its audit counter exactly once; object
  persistence prevents repeat collection.

Damage clears temporary effects. Only `GAME_PLAY` advances timers. The HUD shows
weapon `N`, `R` or `P` and the relevant remaining timer. Pickup sound and a short
feedback pulse occur immediately.

## Talk finale

Stage completion enters five non-gameplay states: lectern arrival, projector
activation, fictional `ENTRY...` activity, `ACCESS G...` success with applause,
and `TALK COMPLETE`. Entry hides object sprites and cancels player and boss
projectiles. Fixed timers drive the sequence, its terminal/result region is
written to both screen caches, the success SID effect runs once, and Fire starts
the existing ranked replay transition. No commands, exploit code, credentials or
real target data are shown.

## Verification notes

`validate_game_design.py` guards all four types, one-shot persistence, five ending
states, projectile shutdown, ca65 cheap-label scope and central visual roles. The
existing PAL smoke/soak harness remains the timing and gameplay gate. This container lacked ca65 and
x64sc, and its package/network proxy returned HTTP 403, so emulator execution and
a fresh frame capture must be completed in the normal release environment.
