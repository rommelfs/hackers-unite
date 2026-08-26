# Phase 6 report: objective, transition and SID feedback

Phase 6 turns the Phase-5 object slice into a complete repeatable level loop. The player must collect the access key, data bonus and 1-Up, travel to the new portal at the far-right end of the world, and press up. The status row reports `ITEMS n/3`, changes to `EXIT UP` when the objective is ready, then shows `LEVEL WIN`.

## Level state machine

The runtime has explicit `PLAY`, `GAME_OVER`, `LEVEL_CLEAR`, `LOAD_A`, `LOAD_B` and `LOAD_READY` states. Entering the exit awards 200 points and freezes normal simulation. Fire advances to the next numbered run, resets objects and the mutable block, restores the player and camera, and rebuilds Screen A and Screen B on separate logical frames. Play resumes only after both buffers and their camera tags agree.

The next run currently reuses the authored world with reset collectibles and enemy state. This makes the objective replayable while keeping Phase 6 inside the existing 64x12-metatile content and bounded four-object budget; a distinct second map remains future content work.

## Sound

A small one-voice SID system now supplies original triangle-wave cues for jump, pickup, enemy defeat, player damage, mutable-block activation and level clear. Each effect sets a fixed frequency and PAL-frame duration. `sound_update` closes the gate deterministically once per logical frame; it does not add work to either raster IRQ.

## Validation

- strict Debug, Release, test and soak assembly/linking pass;
- host checks require the exit, transition and sound symbols;
- the automated PAL test verifies all three persistence bits, portal entry by up, the 100-frame clear state, a level transition, and at least one emitted sound event;
- the 7,680-frame / 153.6-second PAL soak finishes with zero dropped frames or missed line-48 deadlines;
- the release screenshot `build/phase6-start.png` was inspected for status text, sprite alignment, playfield integrity and raster artifacts;
- release size is 12,006 bytes; initialized data ends at `$36E4`, BSS at `$3745`, leaving 2,234 bytes before VIC bank 1.

## Remaining boundaries

There is no SID music, multi-voice priority system, distinct second map, hidden room, sprite multiplexer, NTSC mode or real-hardware verification yet. Those are not silently implied by this phase's repeatable level transition.
