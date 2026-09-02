# Phase 16 report: backstage mastery route

Phase 16 completes the platformer-first three-layout vertical slice by rebuilding
the stage-rig layout as a readable backstage mastery route. Runtime physics,
collision boxes, action-object ownership, raster scheduling and finale states are
unchanged.

## Playable change

- A broad first deck follows the opening two-column cable field and provides a
  stable landing before the first required component.
- The middle deck begins after the electrical field and leaves a safe two-column
  recovery span beside the first falling-equipment lane.
- A row-7 approach deck leads to the final row-6 lighting gantry, preserving the
  production jump-height contract.
- The final row-7 deck returns the player to the visible stage approach after the
  high gantry instead of ending the upper sequence over a hazard.
- Existing spike/electrical silhouettes, warned falling lanes, rolling case and
  final stage remain mechanically unchanged.

## Preventive validation

The manifest declares all five route decks and four ground-level recovery spans.
Asset validation requires every declared deck cell to be solid and limits decks
to reachable rows 6/7. Recovery spans must contain at least two columns and no
hazard flags. Existing checks continue to enforce grouped floor hazards, buffers
around falling lanes and the reachable row-7 approach to the high gantry.

The Level-3 smoke signature now samples the first deck, high-tier approach,
lighting gantry and final stage-return deck before testing hazard families. This
separates route-shape regressions from trap-mechanic diagnostics.

## Runtime budget

The reversible layout table grows from 174 to 178 records and retains the
16-record-per-frozen-frame application cap. No live-frame map application, new
sprite owner or steady-state Color-RAM write is introduced.

## Validation status

Asset, source-merge and game-design validators pass in the implementation
container. Full assembly, PAL VICE smoke/soak, D64 generation and a PAL screenshot
remain required in an equipped environment containing `ca65`, `x64sc` and
`c1541`.
