# PAL raster and cycle budget

PAL provides 312 lines and roughly 19,656 CPU cycles per frame. Line 48 atomically publishes the active screen, 38-column fine-scroll value and shadowed sprite coordinates, then queues exactly one logical frame. Line 240 only restores the fixed 40-column status setting.

Both IRQ branches are fixed and contain no rendering, physics or map decoding. The playfield branch performs bounded register copies only; all simulation and map work remains in the main loop. Sprite Y positions are safely below the short line-48 publication interval.

The main loop owns all per-frame work and prepares the next line-48 state. Each screen buffer tracks the camera character column it contains. A normal coarse step updates the hidden buffer by one or two columns using row-parallel absolute-indexed shifts, then repairs only the exposed columns from the expanded world. On reversal, an already matching hidden buffer flips without a copy. A full 960-character rebuild remains only as a recovery path for a cache delta greater than two.

Phase 5 adds a fixed four-entry object loop after camera update. Each entry performs a bounded activation comparison; only active, unconsumed entries update, run software AABB collision and prepare one fixed hardware-sprite slot. There is no search, allocation or multiplexer. The mutable block refreshes four cells in each affected screen rather than invalidating the buffers.

Phase 6 adds one bounded exit-zone comparison and a constant-time SID envelope tick per logical frame. A level transition deliberately spreads the two full screen rebuilds over separate frames (`LOAD_A`, `LOAD_B`, `LOAD_READY`); physics, scrolling and object simulation are suspended until both buffers are coherent. This keeps a transition out of the steady-state raster budget and prevents a half-old/half-new buffer from becoming visible.

Phase 7 applies its 32 reversible metatile patches only while gameplay is frozen at the level transition. Steady-state work adds a constant-time voice-2 music sequencer tick and one priority comparison when an effect is requested. Music changes note every 12 PAL frames; no tracker decoding, variable-length stream or SID work occurs in either raster IRQ. The full Phase-7 workload still completes the 7,680-frame soak with zero dropped frames.

Phase 9 retains the bounded seven-entry object loop and publishes all 16 sprite X/Y registers at line 48. There is still no sorting or multiplexer. The single projectile runs once after object processing and deterministically borrows the highest free hardware sprite slot; no additional IRQ work is introduced. Level 2 processes four enemies and three pickups, with IDs 5-6 moving every frame. The 7,680-frame PAL soak remains at zero dropped frames and missed line-48 deadlines.

Phase 11 introduced the reversible layout table, currently 144 seven-byte records for three worlds. Runtime transitions enter `LOAD_LAYOUT` and apply at most 16 records per frozen frame before the existing `LOAD_A`, `LOAD_B` and `LOAD_READY` stages. A one-frame full application exceeded the PAL deadline and is therefore reserved for cold boot before IRQs start. The falling block and rolling ball reuse object IDs 5-6 in Level 3; the boss orb is a single bounded lifecycle that appears only after the third pickup frees hardware sprite 4. All three use fixed software boxes and add no raster-IRQ work.

The later combat pass retains the single-active-player-projectile limit. Straight shots and both bomb arcs share one fixed update, cooldown and dynamically borrowed sprite slot. Bomb gravity is one signed addition per frame plus a bounded increment every fourth frame; the boss weak-core check is one fixed X/Y window. Moving this routine to `$5500-$5754` changes memory ownership only, not raster work or publication order.

The soundtrack integration replaces the Phase-7 four-note sequencer with the imported `$1806` PSID play routine. It is called once from `sound_update` per logical PAL frame, never from either raster IRQ. Active gameplay effects reassert voice 1 only after that call. The full player, gameplay and scrolling workload still completes the 7,680-frame soak with zero dropped frames and missed line-48 deadlines.

`frame_pending` is deliberately saturating. `main_busy` additionally makes a missed line-48 deadline count as a dropped frame even if the queue itself was already consumed. The optimized coarse shift plus simultaneous object work completed the 7,680-frame soak with zero dropped frames.
