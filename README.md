# Hackers Unite

Native C64 platform game, built from scratch with ca65/ld65. The current milestone
is **Phase 12: a hack.lu 2026 briefing and location-aware vertical-slice HUD on top
of the Phase-11 gameplay foundation**.

## Requirements

- cc65 2.19 or newer (`ca65`, `ld65`)
- VICE 3.10 or newer (`x64sc`, `c1541`)
- `rg` for host-side checks

## Commands

```sh
make build   # debug and release PRGs
make run     # launch the debug build in PAL VICE
make test    # binary checks plus an automated PAL VICE run
make soak    # 7,680-frame / 153.6-second PAL stress test
make disk    # release/hackers-unite.d64
make preview # build a Level-3 visual-inspection PRG
make assets  # regenerate C64 previews and motif crops
make validate-assets # verify charset, metatiles, colors, flags and map
make clean
```

The debug build visualizes main-loop work in the border. The release build removes those writes at assembly time. Joystick port 2 is sampled once per video frame; opposite directions resolve to neutral.

The soundtrack is Jesper Jensen's `Madness (part 1)` (1988 Noise), used with permission reported by the project owner. Full attribution and import details are in [docs/CREDITS.md](docs/CREDITS.md).

Controls: up, up-left or up-right jumps; a jump with at least one pixel/frame of run-up rises about 52 pixels instead of the standing jump's 31 pixels. Down ducks, down-left/down-right crawls at reduced speed. Fire shoots straight, Fire+Up throws a high bomb arc, and Fire+Down throws a descending bomb; Fire+Up deliberately throws instead of jumping. Collect all three data objects, defeat the Level-2 boss through its central weak core, survive the Level-3 factory gauntlet, reach the portal and press up. Fire advances into the next, harder L1/L2/L3 cycle. After losing the last life, Fire accepts the nine-second Continue and restarts the current section with three lives while preserving score and rank. The camera follows only after the player leaves its horizontal comfort window.

## Current acceptance

- BASIC-startable PRG at `$0801`
- deterministic VIC bank and screen/charset setup
- two-event raster split for scrolling playfield and fixed status
- saturating one-frame queue with overrun counter
- port-2 joystick held/new state
- reproducible Debug, Release and D64 artifacts
- automated PAL smoke test through VICE's debug cartridge
- project-owned 2 KiB charset in multicolor character mode
- 64x12 world built from 2x2-character metatiles
- separate character, color and behavior-flag tables
- deterministic asset generator and validator
- fine scrolling in 38-column mode and Screen A/B coarse flips
- fixed Color-RAM zones with zero steady-state scroll writes
- multicolor player sprite, 12.4 physics and software tile collision
- bounded SoA gameplay objects with camera-margin activation and sleeping
- spider enemy, access-key collectible, data bonus and 1-Up hardware sprites
- software AABB object collision, score, lives, damage, respawn and game over
- persistent collected/defeated state and an authoritative mutable-map patch
- three-item objective, far-right exit portal and explicit level-clear state
- staged Screen A/B rebuild for clean restart and next-run transitions
- one-voice SID feedback for jumping, pickups, enemies, damage, blocks and level clear
- reversible three-layout geometry table and level-specific objective positions
- `L1`/`L2`/`L3` status identification and a `SYSTEM OK` cycle-complete state
- authorized `Madness (part 1)` PSID soundtrack, advanced once per PAL frame
- prioritized gameplay effects layered over soundtrack voice 1
- seven stable object IDs mapped to all eight hardware sprites including the player
- two initial Level-1 enemies, an added later-cycle drone, and four Level-2 enemies
- three elevated Level-2 objectives that require reachable running jumps
- low-profile player collision, two crouch/crawl poses and a crawl-only conduit
- one physical, cooldown-limited projectile using a dynamically free hardware sprite
- projectile/enemy fixed-box hits with persistence, score and defeat feedback
- visible spike hazards, a hidden-block 1-Up and damage-tested foot collision
- a multi-hit expanded boss with invulnerability flash, rage phase and exit lock
- 16-bit endless danger rank; every cleared section advances the L1/L2/L3 cycle
- rank-scaled patrol cadence, extra movement steps and boss durability
- alternating, rank/rage-scaled Level-2 boss energy orbs
- red/yellow Level-3 factory palette and warning-stripe platforms
- visually separate spike and electrical floor hazards
- three warned falling-material lanes and a rank-scaled rolling ball
- 16-record-per-frame staged layout loading with no steady-state Color-RAM writes
- nine-second classic Continue preserving score, level and danger rank
- non-colliding, hidden falling-material warning phase
- high-contrast trap glyphs and autonomous bounded boss patrol
- exact 28x17-pixel boss weak-core window; blind floor-height shots miss
- high and descending ballistic bombs with dedicated artwork
- full-height 16-pixel spike and electrical warning silhouettes
- cold-boot `HACK.LU 2026` mission briefing with a staged transition into gameplay
- `FOYER`/`HACKLU`/`STAGE` objective labels for the current three-layout slice

See [docs/MEMORY_MAP.md](docs/MEMORY_MAP.md), [docs/GRAPHICS_FORMAT.md](docs/GRAPHICS_FORMAT.md), [docs/RASTER_BUDGET.md](docs/RASTER_BUDGET.md), [docs/PHASE_12_REPORT.md](docs/PHASE_12_REPORT.md), [docs/TEST_REPORT.md](docs/TEST_REPORT.md), and [docs/VISUAL_LANGUAGE.md](docs/VISUAL_LANGUAGE.md).
