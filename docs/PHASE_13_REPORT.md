# Phase 13 report: readable routes and ordered respawn

Phase 13 is a focused playability correction. It does not introduce the planned
equipment system; that work is capacity-gated as the next gameplay phase.

## Implemented

- Taking damage now enters a dedicated death state. The player flashes for 25
  PAL frames, disappears, and only then does the camera travel back toward the
  section origin at two pixels per logical frame.
- The player is respawned only after the camera reaches zero. A lethal hit uses
  the same presentation before opening Continue, so a replacement player can
  never exist invisibly at the origin during the camera return.
- Traversable chair rows and factory gantries now have a bright, enclosed
  16-pixel support fascia. Decorative audience chairs remain dark and open, so
  collision-bearing platforms have a consistent silhouette in every layout.
- Level 1 now starts with three enemies instead of two: two floor patrols and a
  later flying patrol. The seven-object ceiling and fixed software boxes remain
  unchanged; Level 2 still uses all four enemy-capable IDs.

## Power-up follow-up contract

The next gameplay phase will replace the current always-available projectile
set with persistent, mutually exclusive equipment states. It must implement the
following progression without adding simulation passes or artwork-based
collision:

1. Start a new campaign unarmed. Stomping remains available.
2. Sword: short, directional Fire attack with a fixed software rectangle.
3. Stone: ballistic Fire throw.
4. Pistol: straight Fire shot.
5. Bombs: Fire plus direction selects the arc.
6. Bonus life: immediate life increment.
7. Power: upgrade the held weapon's damage or reach, with a documented cap.
8. Run boost: raise acceleration/top speed only if PAL soak timing and the
   existing collision probes remain safe at the higher displacement.

Weapon pickups must not consume permanent hardware-sprite slots. The preferred
implementation swaps one bounded pickup through the existing object pool and
stores `weapon_kind`, `weapon_power`, and `run_boost` in BSS. The projectile
slot remains singular and deterministic. HUD state must make “unarmed” and the
active weapon explicit. This phase is intentionally deferred rather than
silently treating the existing Fire modes as finished power-ups.

## Preserved contracts

Death presentation is still advanced exactly once per logical 50 Hz frame.
Camera return reuses the existing one/two-column Screen A/B publisher and does
not write Color RAM. Player and enemy collision remain authoritative fixed
software boxes. The staged three-layout patch loader and SID play cadence are
unchanged.
