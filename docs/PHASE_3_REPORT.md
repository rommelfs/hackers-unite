# Phase 3 report

## Delivered

- 64x12-metatile horizontal world, expanded to 128x24 characters
- `$D016` fine scrolling with 38-column side masking
- eight-pixel coarse boundaries separated from camera pixels
- Screen A/B hidden-buffer rebuild and `$D018` flip
- line-48 playfield and line-240 static-status raster split
- fixed Color-RAM zones with zero steady-state scroll writes
- camera range from pixel 0 through 704
- debug coarse-scroll profiling and flip counter

Shift and rebuild strategies were compared. Shift is faster, but an alternating hidden buffer is two camera columns behind and requires special reversal repair. Full rebuild is deterministic in both directions and passed the frame-overrun tests, so it remains the implementation.

