# Phase 13 memory map

| Range | Owner | Notes |
|---|---|---|
| `$0002-$0008` | Zero page | frame queue and three 16-bit renderer pointers |
| `$0801-$084D` | Boot | BASIC `SYS` stub and startup/BSS clearing code |
| `$1800-$24D2` | Imported SID payload | `Madness (part 1)`, init `$1800`, play `$1806` |
| `$24D3-$2502` | SID workspace reserve | out-of-payload work cells referenced by the imported player |
| `$2600-$26AC` | Runtime BSS | frame, input, camera, sprite shadow, player/stance, shot/bomb arc, objects, action hazards, Continue countdown, danger-rank, transition, respawn slicing, merge compatibility and sound state |
| `$26AD-$3FFF` | Free main RAM | 6,483 bytes before VIC bank |
| `$4000-$43FF` | Screen A | active 40x25 matrix |
| `$4400-$47FF` | Screen B | active hidden/visible scroll buffer |
| `$4800-$4FFF` | Charset RAM | project-owned runtime copy, 256 glyphs / 2 KiB |
| `$5000-$50FF` | Player sprite RAM | four 64-byte frames, pointers `$40-$43` |
| `$5100-$51FF` | Object sprite RAM | enemy, collectible, bonus and 1-Up, pointers `$44-$47` |
| `$5200-$523F` | Projectile sprite RAM | one 64-byte frame, pointer `$48` |
| `$5240-$527F` | Bomb sprite RAM | one 64-byte frame, pointer `$49` |
| `$5300-$537F` | Stance sprite RAM | crouch and crawl, pointers `$4C-$4D` |
| `$5400-$543F` | Boss sprite RAM | one expanded armored-eye frame, pointer `$50` |
| `$5440-$54FF` | Action sprite RAM | falling material, rolling ball and boss orb, pointers `$51-$53` |
| `$5280-$52FF`, `$5380-$53FF` | Free sprite RAM | available with explicit ownership |
| `$5500-$5754` | Secondary game code | bounded straight-shot and ballistic-bomb lifecycle |
| `$5755-$57FF` | Free VIC-bank RAM | 171 bytes between secondary code windows |
| `$5800-$5FFF` | Respawn renderer code window | eight-row Screen A/B rebuild slices; no VIC pointer targets this range |
| `$6000-$7E2E` | Primary game code | gameplay, rendering, IRQ, Continue state, staged layout loader, sound bridge and support routines |
| `$7DDE-$7FFF` | Free primary-code RAM | 546 bytes |
| `$8000-$A200` | Read-only game data | charset source, three-layout table, maps, UI strings and packed sprite sources |
| `$A21D-$AFFF` | Free RAM with BASIC ROM disabled | 3,555 bytes in the configured read-only region |
| `$D800-$DBE7` | Color RAM | active colors; changed only explicitly |

VIC bank 1 is selected through CIA2. After the BASIC `SYS` entry, `$01=$36` hides BASIC ROM while retaining KERNAL and I/O, making game/test RAM at `$A000-$BFFF` executable. The linker fixes the licensed tune at its required address, keeps BSS beyond its workspace, and places code/data in non-overlapping regions. Screen A and B are both active; charset and sprite sources are copied into their aligned VIC addresses during startup. Automated builds place their test-only harness at `$B000`; this segment is absent from release builds.

The hardware stack retains the full `$0100-$01FF` page.
