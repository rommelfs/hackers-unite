# Phase 13 report: readable geometry and deterministic recovery

Phase 13 is the stabilization pass after the Phase-12 briefing. It keeps the
three-layout gameplay content but makes collision affordances explicit and changes
death recovery to reset the camera before republishing the player.

## Runtime changes

- A hit hides gameplay sprites, resets camera state to the section origin, and
  enters a frozen respawn rebuild.
- Screen A and Screen B are rebuilt in eight-row slices. The player is placed at
  spawn only after both buffers are coherent at camera zero.
- The slice routine lives in the dedicated linker segment `CODE3` at `$5800`,
  preserving the projectile window at `$5500-$5754` and primary-code headroom at
  `$6000`.
- The HUD chooses its location string once per frame and copies it through a single
  bounded loop.
- A zero-valued `death_timer` compatibility cell remains exported so a previously
  conflict-resolved `scroll.s` can still assemble. It does not drive recovery;
  `respawn_pending` and `respawn_render_row` remain authoritative.

## Visual changes

- Foreground platforms use closed full-height silhouettes and uninterrupted top
  edges that match their authoritative 16x16 collision cells.
- Walls use a closed cross-braced silhouette; hazards remain visibly open and
  carry no `SOLID` flag.
- Non-colliding fallen chairs no longer sit on the player foot line.
- Generator metadata and host validation enforce solid, hazard, and decoration
  roles without committing regenerated binary diffs to pull requests.

## Validation contract

`make build test`, `make soak`, and `make disk` remain the release gate. The smoke
test identifies a dropped-frame regression as debug-cart code `$41` (decimal 65).
The respawn autotest additionally proves camera-zero-before-spawn ordering and
completion of all Screen A/B slices.
