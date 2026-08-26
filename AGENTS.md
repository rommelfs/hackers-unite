# Hackers Unite agent notes

Read `docs/PROJECT_HANDOFF.md` before changing the project. It is the authoritative current-state handoff.

## Project contract

- Native PAL Commodore 64 game for stock hardware: 6510, VIC-II, SID, 64 KiB.
- ca65/ld65 assembly; BASIC is only the `SYS` boot stub.
- Joystick port 2; multicolor character playfield; VIC-II hardware sprites.
- Original audiovisual identity derived from the supplied hack.lu 2026 references. Do not copy protected game assets, maps, characters, names, music, or sounds. The sole documented exception is Jesper Jensen's `Madness (part 1)`, whose use the project owner reports Jensen explicitly authorized; preserve its attribution in `docs/CREDITS.md`.
- Keep simulation deterministic and execute gameplay exactly once per logical 50 Hz frame.
- Preserve the fixed status raster zone, 38-column horizontal scrolling, Screen A/B buffering, and zero steady-state Color-RAM scroll writes.
- Sprite artwork must never define collision. Collision uses the fixed software box and authoritative metatile flags.

## Required validation

After gameplay or rendering changes, run:

```sh
make build test
make soak
make disk
```

Use PAL `x64sc`. Treat assembler/linker warnings, a nonzero dropped-frame count, visual VIC artifacts, or any failed host/VICE test as a regression. Inspect a screenshot for rendering changes; automated exit status alone is insufficient.

## Current boundary

Phases 1-11 are implemented. The authorized `Madness (part 1)` soundtrack forced a documented split layout: SID `$1800`, BSS `$2600`, primary code `$6000`, RODATA `$8000`; BASIC ROM is disabled after startup. The bounded player-projectile routine occupies the explicitly assigned secondary code window `$5500-$5754` in otherwise unused VIC-bank RAM. Preserve these ownership boundaries and the tune's once-per-logical-frame PAL play call. Phase 11 uses a staged three-layout patch loader capped at 16 records per frozen loading frame; do not move its full patch application into a live gameplay frame.

The project currently has no Git repository. Do not assume changes can be reverted through Git.
