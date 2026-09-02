# Phase 14 report: platformer-first foyer

Phase 14 is the first level-composition pass after confirming that the production
movement itself already feels right. It deliberately leaves physics, camera,
collision, raster scheduling and player actions unchanged and instead rebuilds
the foyer around a classic teach-test-recover rhythm.

## Playable change

- The opening ten metatile columns are a hazard-free arrival zone.
- ENTRY appears on the safe main aisle before the first threat combination.
- The first conference-bug patrol is encountered before the first cable trap.
- Two isolated cable traps replace the previous early obstacle placement; each
  has authored safe approach, landing and recovery ground.
- PAYLOAD and TRIGGER now sit on broad elevated rows later in the route instead
  of being handed out together along the opening floor.
- Short foreground landings, black sight-line breaks, hanging AV markers and
  repeated direction signs divide the 64-metatile route into readable beats.
- The auditorium restores its own denser chair banks and regular platform rhythm,
  preventing the second section from inheriting the foyer composition verbatim.

The stage remains visible at the far right throughout. Existing bounded object
IDs, persistence bits, sprite ownership and fixed software collision boxes are
unchanged.

## Validation additions

The generated manifest now records the safe-start boundary, first teaching enemy,
recovery spans and revised foyer pickup coordinates. Asset validation proves that
the start and recovery spans contain no hazards, that the patrol precedes the
first cable, and that the two later required pickups have authoritative elevated
support.

The layout split increases the reversible three-layout patch table from 144 to
163 records. Runtime application remains capped at 16 records per frozen loading
frame; no patch application was moved into live gameplay.

## Environment validation status

Asset, source-merge and game-design validators pass. Full assembly, PAL VICE smoke
and soak tests, D64 generation and an emulator screenshot remain required in an
equipped environment because `ca65`, `x64sc` and `c1541` are not installed in the
implementation container. A static packed-charset inspection was used only to
review composition; it is not a substitute for the mandatory PAL screenshot.

## Smoke-test follow-up

The first equipped-environment run exposed debug-cart exit `$40`: the smoke test
still required a background chair at foyer metatile `(2,2)`, which Phase 14 had
intentionally cleared as part of the opening sight-line. The test now verifies
that opening gap, the first retained chair bank, the first raised landing and the
new cable at column 22 separately. Its focused hazard probe was moved from the old
column 18 coordinate to the same authoritative column 22. These assertions test
the Phase-14 map instead of restoring the superseded auditorium-shaped foyer.
