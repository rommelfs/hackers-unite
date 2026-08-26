# Phase 9 report

Phase 9 turns the two layouts into a small complete campaign and gives the player more expressive movement and combat.

## Controls and traversal

Up now jumps, including the up-left and up-right diagonals. The existing speed-sensitive standing/running jump model is unchanged. Down selects a low collision stance; down-left and down-right crawl at a capped 0.5 pixel per frame. Releasing down stands only when two authoritative map probes confirm headroom. Two new low-profile sprite frames preserve the player's feet position.

Level 2 adds a three-metatile crawl-only conduit on row 8. The asset validator explicitly permits exactly those three solid shoulder cells while continuing to require an open row-9 foot corridor.

## Combat and pressure

Fire launches one physical shot in the current facing direction. The shot has a ten-frame cooldown, a 48-frame lifetime, map collision, fixed-box enemy collision, persistence, score and the existing enemy-defeat sound. Rendering borrows the highest free object-sprite slot deterministically; the seven stable logical object IDs and player reservation remain unchanged.

The Level-2 enemy at ID 5 now moves vertically as a drone while retaining its horizontal patrol. ID 6 reacquires the player's metatile, moves at double speed and blinks white as a compact warning. Stomping remains available alongside shooting.

## Campaign ending

Completing Level 1 still stages a clean Screen-A/Screen-B rebuild into Level 2. Completing Level 2 now enters `GAME_COMPLETE` and displays `SYSTEM OK`; fire begins a fresh Level-1 campaign. It no longer silently wraps layouts.

## Authorized soundtrack integration

Jesper Jensen's `Madness (part 1)` is integrated with permission reported by the project owner and attributed in `docs/CREDITS.md`. Its fixed payload occupies `$1800-$24D2`, with work cells reserved through `$2502`; the original init `$1800` and play `$1806` entry points are used. The game disables BASIC ROM after its `SYS` entry, places BSS at `$2600`, code at `$6000` and read-only data at `$8000`. Gameplay effects remain prioritized and temporarily override voice 1 after each music tick.

## Verification

- `make build test`: asset validation, host checks and PAL VICE smoke test pass.
- `make soak`: 7,680 frames / 153.6 emulated seconds pass with no dropped frame.
- `make disk`: release D64 regenerated.
- `build/phase9-crawl-encounter.png`: crouched player, crawl conduit, elevated geometry, drone and fixed status split visually inspected without VIC artifacts.
- `build/madness-part-1-gameplay.wav`: 5.024 seconds of non-silent VICE output, peak 12,857 and RMS 3,015.2.
- `build/madness-part-1-gameplay.png`: soundtrack-enabled release rendering visually inspected without VIC artifacts.

The soundtrack-enabled release PRG is 38,147 bytes and loads through `$9D01`. The larger file includes the zero-filled gaps required by its fixed-address SID, code and read-only-data regions; live BSS occupies only `$2600-$268D`.
