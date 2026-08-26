# Phase 7 report: second layout and prioritized SID audio

Phase 7 extends the repeatable objective into a two-layout campaign loop. Completing Level 1 now loads Level 2 with visibly different platform geometry and objective placement; completing Level 2 cycles back to a fully restored Level 1. The status row identifies the active layout as `L1` or `L2` during play, loading and completion states.

## Compact second layout

A full second collision map plus pre-expanded character world would require 2,304 additional bytes and exceed the safe space below VIC bank 1. Instead, the asset generator derives 32 reversible metatile differences. Each six-byte record names an authoritative map offset, its expanded-world top-left offset, and the Level-1/Level-2 tile values.

`level_layout_apply` updates the mutable RAM-backed map and all four expanded character cells for each record while gameplay is frozen. The existing `LOAD_A`, `LOAD_B` and `LOAD_READY` states then rebuild both screen buffers. Collision therefore reads exactly the geometry that rendering displays; no sprite or character artwork becomes collision authority.

Level 2 moves platforms across all three scrolling sections and relocates the key, data bonus and 1-Up to world X 140, 470 and 760. The portal and three-item completion contract remain unchanged.

### Reachability correction

The first Phase-7 layout placed the platform at X 736-799 on metatile row 8, intersecting the ground corridor and trapping the last item at X 760 behind authoritative solid collision. The platform now occupies row 6 as an elevated tier. Asset validation rejects any solid metatile on ground-corridor rows 8 or 9 in either layout, so ground pickups cannot be sealed behind a full-height map wall again.

## Two-voice SID design

Voice 1 remains dedicated to event effects. Every effect now has a priority: jump is lowest, pickup/enemy/block are medium, damage is high and level clear is highest. A lower-priority request is rejected while a stronger cue is active, preventing routine movement from cutting off important feedback.

Voice 2 plays a compact four-note pulse-wave motif. Level 1 and Level 2 use different note tables, advancing once every 12 PAL frames. Music pauses outside active play. Both voices are advanced from the once-per-frame scheduler; raster IRQs remain free of SID sequencing.

## Validation

- the asset validator reconstructs Level 2 from the 193-byte patch file and rejects bad offsets, base tiles, size headers or a layout identical to Level 1;
- the automated PAL smoke test verifies Level-2 selection, a changed platform tile, all three Level-2 object positions, music ticks, rejection of a low-priority effect, and the full Level-2-to-Level-1 geometry restoration;
- `make build test`, `make soak` and `make disk` pass;
- the soak completes 7,680 PAL frames / 153.6 emulated seconds with zero dropped frames or missed line-48 deadlines;
- `build/phase7-last-item-fixed.png` was inspected in VICE and shows the formerly blocked pickup on a continuous floor with the moved platform safely elevated;
- release size is 12,543 bytes; initialized data ends at `$38FD`, BSS ends at `$3963`, leaving 1,692 bytes before `$4000`.

## Remaining boundaries

The two layouts share one world extent, tile vocabulary, portal and object types; Level 2 is not a separately themed 2,304-byte map. There is still no title screen, final campaign ending, SID tracker song, sprite multiplexer, NTSC mode or real-hardware verification.
