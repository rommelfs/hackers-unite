# Phase 4 report

## Delivered

- Hardware sprite 0 permanently reserved for the player
- Four original multicolor frames: idle, walk A/B and jump
- Port-2 left/right acceleration and edge-triggered fire jump
- Signed 4.4 velocity with 16-bit 12.4 world positions
- Separate horizontal and vertical integration/collision passes
- Two-point leading-edge probes against authoritative metatile flags
- Exact landing, wall and ceiling correction to 16-pixel boundaries
- Gravity, fall-speed limit, friction and level clamping
- Camera comfort window from screen pixel 112 through 199
- Camera catch-up of two pixels per frame, faster than the player's 1.5-pixel maximum
- Bottom-of-world respawn guard

The sprite image never defines collision. The physical box remains fixed at offsets 2-13 horizontally and 1-20 vertically, independent of animation.

The short automation runs right, jumps every 64 frames, requires coarse flips and a resolved landing, verifies that sprite 0 is enabled and inside the visible VIC X range, and fails on any dropped frame. The soak automation reverses at both level ends for 7,680 PAL frames.

The Phase 4 visibility regression was caused by reusing the low-byte subtraction carry before subtracting the high byte of `player_x - camera_x`. The conversion now completes the 16-bit subtraction first and only then adds the VIC border offset. Camera catch-up was also raised from one to two pixels per frame so the player cannot outrun the comfort window.
