# Phase 11 graphics format

## Charset

`charset.bin` is exactly 2,048 bytes: 256 characters of eight bytes each. Characters `0-63` are high-resolution status glyphs. Characters `64-255` are reserved for multicolor scene graphics. The VIC uses global background colors from `$D021-$D023`; a Color-RAM value with bit 3 set selects multicolor interpretation for its cell.

## Metatiles

Every metatile covers 2x2 characters, or 16x16 displayed pixels. Its data is split into parallel tables:

- `metatile-chars.bin`: four character indices in TL, TR, BL, BR order
- `metatile-colors.bin`: four Color-RAM values in the same order
- `metatile-flags.bin`: one behavior byte, separate from rendering

Defined flags are `SOLID=$01`, `HAZARD=$02` and `DECORATION=$80`. Rendering never reads behavior flags. Collision reads the authoritative map tile, never character graphics. Spike and electrical metatiles are `HAZARD`-only, visually different and never invisible walls. Both occupy all four cells of their 2x2-character metatile, producing full-height 16-pixel warnings above the floor. They use the bright shared background-2 ink—light blue in Levels 1/2 and yellow in Level 3—against the black playfield, with large triangular and alternating zigzag silhouettes.

## World map

`static-map.bin` is 64x12 metatile indices. The converter also emits a 128x24-character world. A coarse step copies exactly 40x24 characters into the hidden screen, then publishes it through `$D018`. Row 24 is a dedicated high-resolution status row copied to both buffers.

## Color-RAM cost

The world uses 24 fixed horizontal Color-RAM zones. Color RAM is initialized before raster IRQs begin and needs zero steady-state scroll writes. This deliberately trades per-object cell colors for deterministic, tear-free scrolling.

Level 3 changes only the global multicolor registers at its loading boundary, selecting a warning-red/yellow factory palette. It does not write Color RAM while scrolling.

## Player sprites

`player-sprites.bin` contains four 64-byte-aligned multicolor hardware-sprite frames: idle, two walk phases and jump. Hardware sprite 0 is permanently reserved for the player. Shared colors are dark grey and cyan; the individual color is green.

`stance-sprites.bin` adds two 64-byte-aligned crouch/crawl poses at pointers `$4C-$4D`. Their artwork sits low in the unchanged 21-line cell, so feet do not jump when the pose changes. Collision remains a software box: crouching disables the upper leading-edge probe, and standing is allowed only after both shoulder probes clear the ceiling.

## Gameplay-object sprites

`object-sprites.bin` contains four 64-byte-aligned original multicolor sprites: spider camera enemy, access key, data bonus and 1-Up core. Stable object IDs 0-3 retain the original enemy/item mapping; IDs 4-6 are additional enemies reusing the spider artwork with individual colors. IDs 0-6 map directly to hardware sprites 1-7, while sprite 0 remains the player. Inactive, offscreen and persistent-consumed objects have their enable bit cleared. Artwork is presentation only. Every interaction uses fixed software AABBs and object/map state.

Lock, onion and chain character glyphs remain available in the authored vocabulary, but the current world map does not place them as decoration. This prevents a non-interactive character tile from being mistaken for a collectible; pickup-looking entities in the playable view are object sprites.

`projectile-sprite.bin` is one 64-byte frame at pointer `$48`. A live shot borrows the highest currently unused hardware sprite among 1-7 after normal object rendering; it never displaces the player and disappears cleanly when no slot is available. Projectile art does not define hits: map and enemy tests use integer coordinates and fixed software boxes.

Its lit pixels occupy the sprite cell's top three rows. Since the physical shot is spawned eight pixels below the player's fixed top, this aligns the visible muzzle with the hand rather than the foot.

`bomb-sprite.bin` is a separate padded frame at pointer `$49` / `$5240`. Its round body and short fuse occupy the top eleven rows. Bombs use white individual color, the shared sprite multicolors, and the same dynamically borrowed free hardware slot as the straight shot; only one player projectile can exist at once.

`boss-sprite.bin` is one original armored-eye frame at pointer `$50`. Level-2 object ID 6 uses VIC X/Y expansion for presentation, while a separately authored fixed 36x44 software box remains authoritative for hits and stomps.

`action-sprites.bin` contains three original frames at `$51-$53`: falling material, a rolling ball and a boss energy orb. In Level 3, stable object IDs 5/6 use the first two frames and fixed software boxes. Falling material has a 50-frame warning phase during which its object Y is zero and it is neither rendered nor collision-active; only the actual drop owns a visible damage box. The boss orb uses hardware sprite 4 only after the 1-Up has been collected, so it never hides a required item.

The mutable block at metatile `(10,8)` is a patch over the immutable map. Its two-by-two character overlay is applied while rebuilding a hidden screen, while collision consults the patch state directly. Mutating it invalidates the rendered camera column, forces a normal hidden-buffer rebuild and reveals a one-shot 1-Up/score bonus.

## Exit portal

The far-right exit occupies world pixels 944-1007 and is composed from the original portal-frame and green-vortex metatiles. It is decorative and non-solid; completion is an explicit gameplay-zone test, never a graphics collision. The portal accepts up only after persistence bits 1-3 show that all three pickups were collected. In Level 2 it additionally requires boss bit 6.

## Three-layout patches

`level-layout-patches.bin` is 1,009 bytes: one count byte and 144 reversible seven-byte records containing map/world offsets plus the Level-1/2/3 tile indices. Runtime applies at most 16 records per loading frame, then rebuilds Screen A/B. The authoritative map and expanded character world therefore change together without breaching the normal PAL-frame budget.

This is a real geometry variant rather than a palette or status-only change. Platforms move in all three scrolling sections and support the Level-2 pickups at world `(140,91)`, `(470,91)` and `(760,91)`. Their tops are 48 pixels above the floor, matching the tested running-jump tier. Three additional row-8 platform cells form the crawl conduit at columns 34-36. Applying the Level-1 side of the same records can restore the original map without storing another 2,304-byte map/world pair.

Level 3 uses warning-stripe platforms, a reachable row-7 step to its row-6 high tier, three overhead drop-warning lanes and three grouped spike/electric floor fields. Hazard glyphs exclude the green floor ink and each falling lane has a two-column safe buffer. Metatile rows 8/9 remain free of unapproved solid walls in all layouts; row 10 remains the authoritative support floor.
