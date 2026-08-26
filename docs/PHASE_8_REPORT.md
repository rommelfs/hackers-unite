# Phase 8 report: escalating enemies and objective routes

Phase 8 addresses the flat difficulty curve directly. Level 1 now introduces two ground enemies while keeping its three pickups on the safe floor route. Level 2 activates four enemies, moves its three objectives onto authored platform tiers, and makes the two late patrols move every PAL frame instead of every second frame.

## Seven-object hardware budget

The fixed SoA object set grows from four to seven stable IDs, exactly filling hardware sprites 1-7 while sprite 0 remains exclusive to the player. IDs 0-3 retain the original enemy, key, bonus and 1-Up meanings; IDs 4-6 are additional enemies. They reuse the original spider-camera sprite with red, purple and light-blue individual colors, so Phase 8 increases encounter density without spending another sprite-art block or introducing a multiplexer.

Level 1 activates enemies at world X 340 and 600. Level 2 activates four patrols around X 220, 390, 620 and 860. All use independent direction bytes and 32-pixel patrol spans. The final two Level-2 enemies update every frame; earlier enemies update every second frame. A game-state check stops the remaining object loop immediately after a lethal hit, preventing multiple overlapping enemies from charging several deaths in one logical frame.

## Level-2 route

The second layout now uses 25 reversible patches. Its objectives remain spread across the full level at X 140, 470 and 760, but all three sit at Y 91 on solid row-7 platforms. Those platform tops are 48 pixels above the floor: unreachable by the 31-pixel standing jump, but reachable by the tested 52-pixel running jump. Each objective therefore asks the player to create space, build speed and time a jump while patrols pressure the ground route.

The asset validator reconstructs Level 2 and checks every objective's solid support, the maximum 48-pixel rise, legal patch offsets and the open ground corridor on rows 8-9. Collision remains authoritative map data; item and enemy artwork never determines reachability.

## Validation

- `make build test`, `make soak` and `make disk` pass;
- the smoke test verifies two Level-1 enemies, four Level-2 enemies, all three elevated objective coordinates, their platform cells, map restoration and the existing gameplay/audio contracts;
- enemy IDs 0, 4, 5 and 6 are each stomp-tested in the exact floor-snap landing frame;
- all 16 hardware-sprite coordinate bytes publish coherently at line 48;
- the 7,680-frame / 153.6-second PAL soak completes with zero dropped frames or deadline misses;
- `build/phase8-level2-pressure.png` was visually inspected: the final elevated objective, clear run-up lane, multiple colored enemies, status raster and screen boundaries render cleanly;
- release size is 12,762 bytes; initialized data ends at `$39D8`, BSS ends at `$3A58`, leaving 1,447 bytes before `$4000`.

## Exact-landing correction

Tile collision is resolved before object collision. Previously, a jump that reached an enemy on the exact floor-landing frame could already have its Y snapped to 139 and vertical velocity reset to zero. The enemy test then saw equal-height sprites and treated the visually correct landing as side damage, most noticeably on the second enemy. `player_airborne_entry` now records whether the player entered that logical frame in the air. Equal-height contact counts as a stomp only for that one landing frame; ordinary grounded contact remains damage.

## Remaining boundaries

Enemy quantity, speed and placement now escalate, but all four enemies share one patrol/stomp behavior and one base sprite. There are still no airborne or projectile enemies, boss, title/final ending, sprite multiplexer, NTSC mode or real-hardware verification.
