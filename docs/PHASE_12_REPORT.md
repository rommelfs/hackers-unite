# Phase 12 report: hack.lu narrative shell

Phase 12 starts the redesign with the smallest playable vertical slice: a cold-boot
briefing screen and location-aware objective HUD. It deliberately does not claim
that the expanded hotel route or new enemy families are implemented yet.

## Implemented

- Cold boot now opens on a dedicated `HACK.LU 2026` briefing instead of dropping
  directly into moving gameplay.
- The briefing states the stage destination, fictional RCE PoC objective, and its
  `ENTRY`, `PAYLOAD`, and `TRIGGER` components.
- Fire starts the route. Both scrolling buffers are restored through the existing
  staged renderer before simulation resumes.
- Player and object sprites remain hidden while the briefing owns the playfield.
- Automated builds bypass the interactive briefing, preserving deterministic test
  entry into gameplay; the existing Phase-12 preview still opens at the stage rig.
- The live objective field identifies the current vertical-slice location as
  `FOYER`, `HACKLU`, or `STAGE` while retaining the three-item count.
- Landable chair rows and stage gantries now have a continuous top edge and visible
  full-height supports; blocking walls use a closed cross-braced silhouette.
- Non-colliding fallen-chair decoration was removed from the player foot line, and
  generated assets declare/validate their solid, hazard, and decoration roles.
- Damage now resets the camera and rebuilds both start-position screen buffers
  before the player is placed at the section spawn and published again.

## Preserved contracts

The presentation is rendered once before IRQs start. It adds no live-frame screen
or Color-RAM rewrite, no new sprite ownership, and no gameplay update. Starting the
route uses `GAME_LOAD_A`, `GAME_LOAD_B`, and `GAME_LOAD_READY`, so title characters
cannot leak into scrolling Screen A/B buffers. The status raster row, rank display,
collision model, object bounds, memory windows, soundtrack call rate, and staged
layout-patch limit are unchanged.

## Remaining redesign work

The three existing maps remain the foyer/auditorium/stage vertical slice. The hotel
entrance, room, corridor, lobby/chill-out area, main-room entrance, registration,
bar, and restroom routes still require the capacity-gated manifest and content
work defined in `docs/GAME_REDESIGN.md`. A title or HUD label is not evidence that
those locations exist.

## Validation

The required build was attempted in the implementation environment, but `ca65`
and VICE are unavailable. Package installation was also blocked by the configured
Ubuntu mirror returning HTTP 403. Full `make build test`, `make soak`, `make disk`,
and PAL screenshot inspection therefore remain mandatory in the equipped project
environment before this phase can be treated as release-verified.
