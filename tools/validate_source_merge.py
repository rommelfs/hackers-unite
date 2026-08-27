#!/usr/bin/env python3
"""Reject partial web-UI merge resolutions before invoking ca65."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILES = [
    *ROOT.glob("src/*.[is][n]c"),
    *ROOT.glob("src/*.s"),
    *ROOT.glob("cfg/*.cfg"),
]

errors: list[str] = []
for path in SOURCE_FILES:
    text = path.read_text()
    relative = path.relative_to(ROOT)
    for marker in ("<<<<<<<", "=======", ">>>>>>>"):
        if marker in text:
            errors.append(f"{relative}: unresolved merge marker {marker}")

scroll = (ROOT / "src/scroll.s").read_text()
if '.import respawn_render_row' not in scroll:
    errors.append("src/scroll.s: missing Phase 13 respawn_render_row import")
if ".import respawn_render_row, death_timer" not in scroll:
    errors.append("src/scroll.s: missing Phase 13 death-return state imports")
if "scroll_return_update:" not in scroll or "jmp scroll_publish" not in scroll:
    errors.append("src/scroll.s: incomplete Phase 13 camera-return publisher")
if '.segment "CODE3"' not in scroll:
    errors.append("src/scroll.s: missing Phase 13 CODE3 respawn renderer")

state = (ROOT / "src/state.s").read_text()
if ".export respawn_pending, respawn_render_row, death_timer" not in state:
    errors.append("src/state.s: incomplete Phase 13 respawn state export")

constants = (ROOT / "src/constants.inc").read_text()
if "GAME_DEATH       = 10" not in constants:
    errors.append("src/constants.inc: missing GAME_DEATH state")

game = (ROOT / "src/game.s").read_text()
if "@death:" not in game or "sta death_timer" not in game:
    errors.append("src/game.s: incomplete Phase 13 death presentation")
if "lda #GAME_LOAD_READY\n    sta game_state\n    rts" not in game:
    errors.append("src/game.s: respawn loader can fall through past GAME_LOAD_READY")

sprites = (ROOT / "src/sprites.s").read_text()
if ".import game_state, death_timer" not in sprites:
    errors.append("src/sprites.s: missing death-flicker state imports")

for config in ("cfg/c64.cfg", "cfg/c64-test.cfg"):
    if 'CODE3:    load = TUNE,      type = ro, start = $5800;' not in (
        ROOT / config
    ).read_text():
        errors.append(f"{config}: missing CODE3 at $5800")

if errors:
    raise SystemExit("source merge validation failed:\n- " + "\n- ".join(errors))

print("source merge validation: OK")
