# Phase 17 report: stage-console demo finale

Phase 17 replaces the compact eight-character ending labels with a staged
conference-console presentation. The sequence is fictional and contains no real
product, exploit, credentials or actionable shell command.

## Presentation

1. The player approaches the lectern while a 30x16 monitor is built one bounded
   row per frozen finale frame in both cached screens.
2. The projector links ENTRY, PAYLOAD and TRIGGER on a hack.lu stage shell.
3. A typewriter script emits fictional PoC status, abstract signal bytes and an
   execution beat in a 26x8 terminal window.
4. More than eight script lines force two real in-window scroll operations.
5. The final line is the theatrical, non-actionable `ROOT@STAGE:#` prompt with a
   blinking cursor.
6. `SYSTEM OPEN`, audience animation and the existing success cue lead into the
   result/replay state.

The typewriter duration is 250 PAL frames. Terminal scrolling copies only the
bounded 26x8 window and occurs at newline boundaries while gameplay is frozen.
Music remains outside the finale module and continues its once-per-logical-frame
play call.

## Commodore-key shortcut

Pressing the standalone Commodore key enters the complete finale sequence from
any game state. Input performs a bounded direct CIA-1 matrix scan of PA7/PB5 after
joystick sampling, restores both data-direction registers and port A, and emits an
edge-triggered `cheat_pressed` event. Holding the key cannot restart the finale
every frame. The shortcut is intentionally retained as a development/demo aid.

## Preventive validation

- The smoke harness executes the complete typewriter script and its two scrolls.
- `$A8` reports a script that does not reach its end marker.
- `$A9` reports a missing final `R` at the root-prompt screen position.
- Source validation requires the terminal script/scroll routines, script-done
  state, Commodore matrix constants and cheat-to-finale call.
- The script uses only fictional presentation text and runs no prompt command.

## Validation status

Host-side source, asset and design validators pass in the implementation
container. Full assembly, PAL VICE smoke/soak, D64 generation and screenshots of
boot, scrolling demo and root prompt remain required in an equipped environment.

## Equipped linker follow-up

The first equipped build showed that the already tight `$6000-$7FFF` primary
`CODE` area overflowed by 11 bytes after adding the Commodore feature. Moving only
the matrix scanner was insufficient because the new call and game-state dispatch
still consumed exactly the remaining primary headroom. The complete bounded input
module now resides in the existing `$5800-$5FFF` `CODE3` window. Scheduler calls,
joystick-first ordering, keyboard semantics and the memory map are unchanged,
while the primary segment recovers the complete former input routine rather than
only the scanner body.
