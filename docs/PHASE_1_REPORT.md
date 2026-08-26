# Phase 1 report

## Implemented

- Independent ca65/ld65 project and linker layout
- BASIC boot stub (`RUN` / autostart)
- PAL-oriented VIC initialization in multicolor character mode
- Dedicated VIC bank, active screen, reserved back buffer and private charset RAM
- Raster IRQ and deterministic one-frame scheduler
- Joystick port 2 decoder with held and edge-triggered state
- Debug border profiling and compile-time-clean Release build
- PRG and D64 packaging
- Host binary checks and automated VICE PAL smoke test

## Intentional limits

There is no player, physics, scrolling, world, sound, collision, enemy, item, score, or save state in Phase 1. Adding any of these now would blur the scheduler and memory-layout acceptance criteria. Phase 2 should add the authored multicolor charset, tile vocabulary, sprite multiplexer baseline, and the first original visual identity without changing this timing contract.

## Runtime diagnostics

The screen displays the low frame byte and dropped-frame counter. Joystick directions and fire appear as letters while held. A nonzero drop count indicates that the main loop missed a frame and is a hard performance warning for subsequent phases.

