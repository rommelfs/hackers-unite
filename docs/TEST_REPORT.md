# Phase 11 test report

Tested on 2026-08-18 with the Homebrew cc65 2.19 package (ca65 reports V2.18), VICE x64sc 3.10, and PAL VIC-II timing.

| Check | Result |
|---|---|
| Strict assembly (warnings fail) | Pass |
| Debug and Release link | Pass |
| PRG load address `$0801` | Pass |
| Linker regions do not overlap | Pass: SID `$1800`, BSS `$2600`, code `$6000`, RODATA `$8000` |
| Required exported symbols | Pass |
| PAL autostart through BASIC stub | Pass |
| 240-frame movement/collision test | Pass |
| Debug-cart controlled exit | Pass |
| D64 creation and PRG insertion | Pass |
| Visual screen inspection | Pass |
| Project charset is exactly 2 KiB | Pass |
| Metatile character/color/flag tables agree | Pass |
| Hires/multicolor Color-RAM mode bits | Pass |
| 64x12 map indices remain in range | Pass |
| 128x24 expanded world dimensions | Pass |
| Screen A/B coarse flips | Pass |
| 38-column playfield / fixed status split | Pass |
| Player frames are 64-byte aligned | Pass |
| Automated jumps and resolved landings | Pass |
| Up/up-left/up-right jump input | Pass |
| Duck/crawl state and reduced crawl speed | Pass |
| Running-jump path and elevated-platform landing | Pass |
| Camera and level bounds | Pass |
| Main loop completes before next line-48 publish | Pass, zero deadline misses |
| Reversal-safe one/two-column hidden-buffer shifts | Pass |
| Scroll and hardware-sprite shadows published coherently | Pass |
| Player sprite enabled and visible in VIC X range | Pass |
| 7,680-frame PAL soak | Pass, 153.6 emulated seconds |
| Seven stable object IDs and activation margin | Pass |
| Collectible, bonus and 1-Up collection | Pass, persistent mask verified |
| No non-interactive pickup lookalikes in world map | Pass, start/end screenshots inspected |
| Enemy software AABB and stomp defeat | Pass |
| Projectile spawn, complete 24x21 small-enemy box, defeat and persistence | Pass, right-edge X+20 regression covered |
| Hand-aligned projectile pixels | Pass, top-three-row asset invariant |
| Exact floor-snap stomp for enemy IDs 0/4/5/6 | Pass |
| Grounded equal-height enemy contact remains damage | Pass by explicit state branch |
| Mutable-block collision, patch persistence and secret 1-Up | Pass |
| Non-solid spike hazard and fixed-foot damage | Pass |
| Damage, lives and game-over transition | Pass, three deterministic hits |
| Object sprite alignment and visibility | Pass, four 64-byte frames |
| Three-pickup exit lock | Pass, persistence bits 1-3 required |
| Level-2 boss exit lock | Pass, portal rejects entry until boss bit 6 |
| Portal entry with joystick up | Pass, far-right zone verified |
| Level-clear and staged Screen A/B transition | Pass |
| SID event integration | Pass, jump/pickup/enemy/damage/block/clear entry points linked |
| Imported soundtrack payload | Pass, 3,283 bytes at `$1800-$24D2` |
| Imported soundtrack cadence | Pass, `$1806` called once per logical PAL frame |
| Recorded audio signal | Pass, 5.024 s WAV; peak 12,857 / RMS 3,015.2 |
| Reversible Level-2 geometry | Pass, selected from the 144-record three-layout table |
| Collision-map and expanded-world patch agreement | Pass |
| Level-1/Level-2 ground foot corridor row 9 | Pass, no solid metatiles |
| Level-2 crawl conduit | Pass, exactly row-8 columns 34-36 are solid |
| Level-2 campaign completion state | Pass, `GAME_COMPLETE` reached |
| Endless campaign restart | Pass, `GAME_COMPLETE` resumes harder Level 1 |
| 16-bit danger-rank progression | Pass, increments after every cleared section |
| Level-2 objective positions | Pass, X 140 / 470 / 760 |
| SID player activity counter | Pass, 12-frame diagnostic ticks verified |
| Sound-effect priority | Pass, jump cannot interrupt damage |
| Enemy difficulty progression | Pass, Level 1 = 2 then 3 / Level 2 = 4 |
| Independent enemy patrol directions and bounds | Pass |
| Drone and boss behavior | Pass, ID 5 vertical motion / ID 6 autonomous arena patrol, rank speed and rage phase |
| Multi-hit boss | Pass, eight rank-1 hits, invulnerability and one defeat counted |
| Boss projectile pattern | Pass, reserved-slot rule, alternating heights, hit and rage cadence |
| Elevated Level-2 objectives | Pass, all three on reachable 48-pixel tiers |
| Eight-sprite coordinate publication | Pass, 16 X/Y shadow bytes |
| Three-layout patch table | Pass, 144 records / 1,009 bytes, map/world agreement |
| Staged layout application | Pass, at most 16 patch records per frozen loading frame |
| Distinct Level-3 factory theme | Pass, red/yellow warning palette and factory geometry |
| Spike/electric trap distinction | Pass, separate graphics with authoritative non-solid hazard flags |
| Falling-material hazard | Pass, warned lanes, drop cycle and fixed software AABB |
| Rolling-ball hazard | Pass, leftward cycle, rank speed step and fixed software AABB |
| Level-3 objective positions | Pass, X 280 / 520 / 760 on reachable tiers |
| Three-section campaign cycle | Pass, L1 -> L2 -> L3 -> `SYSTEM OK` -> harder L1 |
| Level-3 action sprite publication | Pass, falling block, rolling ball and player remain aligned |
| Falling-material warning phase | Pass, 50 frames with no sprite bit or collision box |
| Classic Continue | Pass, nine-second state, Fire acceptance, three lives, level/rank preservation |
| Continue timeout | Pass, transitions separately to `GAME OVER` |
| Boss anti-magnetism | Pass, authored patrol direction remains independent of player X |
| Boss/platform collision separation | Pass, six-pixel vertical gap leaves boss HP unchanged |
| Static trap contrast | Pass, both trap glyph families use bright background-2 ink and distinct silhouettes |
| L03R02 hazard readability | Pass, three paired fields, no isolated traps or green floor ink, safe falling-lane buffers |
| Boss weak-core accuracy | Pass, floor-height shot misses; core-height shot damages exactly once |
| High bomb input/arc | Pass, Fire+Up selects mode 1 and initial VY -4 |
| Descending bomb input/arc | Pass, Fire+Down selects mode 2 and initial VY +2 |
| Dedicated bomb artwork | Pass, padded 64-byte pointer `$49` frame |
| Full-height trap warnings | Pass, spike/electric metatiles use all four character cells |

The short emulator build additionally exercises the boss orb, autonomous boss patrol, all three layouts, the Level-3 trap flags and contrast invariants, a collision-free falling-material warning, a falling-material cycle, a rolling-ball cycle, Continue acceptance/timeout, Level-3 completion and the rank-3 campaign restart. The soak build reverses at both level ends and repeats movement, seven-entry object activation/collision, cached shifts, camera tracking, SID updates and buffer flips for 7,680 frames. Both fail on a queued-frame overrun or a missed line-48 main-loop deadline.

The soundtrack-enabled Phase-11 release is 39,426 bytes. Its size includes zero-filled PRG gaps required to load fixed-address tune, code and data regions through `$A200`; this is layout cost rather than equal live content. Automated PRGs place their test-only harness at `$B000`, visible after BASIC ROM is disabled. Up-jump, crouch/crawl, straight shots, both bomb throws, exact boss-core hits/misses, full-height traps, action hazards, boss projectiles, autonomous boss patrol, Continue acceptance/timeout, staged three-layout loading, endless restart and `GAME_COMPLETE` are covered by the smoke harness. `build/l03r02-readable-traps.png` was inspected for the grouped red/yellow hazards, safe green/cyan floor, player alignment, status split and VIC artifacts. `build/madness-part-1-gameplay.wav` remains the verified soundtrack capture. Colored outer-border bands in automated Debug screenshots are intentional profiling.
