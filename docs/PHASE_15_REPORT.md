# Phase 15 report: two-route auditorium

Phase 15 turns the middle layout into a distinct platform level instead of a
denser variation of the foyer. Physics, collision boxes, camera behavior, sprite
ownership and the 50 Hz scheduler remain unchanged.

## Playable change

- The continuous lower aisle remains the mandatory recovery route.
- Two upper-route waves begin and end on reachable row-7 landings.
- Each upper wave rises to row 6 only after a row-7 approach, so no 64-pixel
  ground jump is required.
- Gaps in the upper rows create optional running-jump sequences while always
  allowing a fall back to the lower aisle.
- ENTRY and PAYLOAD retain their authored supports; TRIGGER moves to world X 792
  on the final broad row-7 landing before the boss/stage approach.
- The crawl conduit remains a lower-route timing choice beneath the second upper
  wave rather than becoming a wall across both routes.

## Preventive validation

The generated manifest declares every upper-route segment, its two entry columns
and its two rejoin columns. Asset validation checks the complete solid span of
each segment and requires row-7 approach/rejoin surfaces. Pickup support and the
existing continuous row-8/9 ground-corridor contract remain mandatory.

The deterministic smoke signature now samples the authored entry, raised tier,
mid-route landing and final rejoin instead of coordinates from the superseded
auditorium. The Level-2 TRIGGER coordinate assertion is updated to X 792.

## Runtime budget

The more distinct auditorium increases the reversible three-layout table from
165 to 174 records. The loader still applies at most 16 records per frozen frame;
no additional steady-state Color-RAM work, object slot or sprite is introduced.

## Validation status

Asset, source-merge and game-design validators pass in the implementation
container. Full assembly, PAL VICE smoke/soak, D64 generation and a PAL screenshot
remain required in an equipped environment containing `ca65`, `x64sc` and
`c1541`.
