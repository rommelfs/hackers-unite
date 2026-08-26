# Phase 5 report

## Delivered

- Four-entry Structure-of-Arrays object model with stable persistence IDs
- Camera-window activation from 32 pixels left through 351 pixels right, with sleeping outside that margin
- Ground spider-camera enemy with bounded patrol and fixed software AABB
- Access-key collectible, data bonus and 1-Up, each with distinct score/life behavior
- Hardware sprites 1-4 for gameplay objects; sprite 0 remains reserved for the player
- One authoritative mutable block at metatile `(10,8)`, stored as a patch rather than a copied map
- Persistent collected, defeated and mutated state across screen-buffer flips and return scrolling
- 16-bit score, lives, damage cooldown, respawn and a game-over state; fire starts a fresh game
- Fixed status row showing score, lives, frame count, dropped frames and `GAME OVER`
- Speed-sensitive jump: about 31 pixels standing and 52 pixels with run-up
- Reversal-safe cached one/two-column screen shifts and coherent line-48 scroll/sprite publication
- No decorative pickup decoys: every visible lock/key, bonus or 1-Up motif in the playfield is an interactive hardware-sprite object

Object art never defines collision. The player, enemy and items use fixed software boxes, and the mutable block collision checks its stable map coordinate and patch bit.

## Deterministic coverage

The short PAL test traverses the object field and verifies all four activations, three collections (worth `$00A0` before enemy points), enemy defeat, the full object persistence mask and block mutation. It requires a running jump and a resolved landing above the floor, then drives three explicit damage events and requires lives to reach zero with exactly one game-over transition.

The 7,680-frame soak repeatedly traverses the world in both directions, jumps, activates and sleeps objects, revisits consumed object positions, performs cached coarse shifts, flips Screen A/B and requires every main-loop frame to finish before its next line-48 deadline. `build/run-jump-scroll-fixed.png` was inspected for sprite placement, repaired edge columns, the fixed status strip and VIC artifacts; its colored outer-border bands are intentional Debug-build profiling.

Pickup visibility was additionally checked before and after collection in `build/collectible-start.png` and `build/collectible-after.png`.
