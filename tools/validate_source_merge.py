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
if "death_timer" in scroll and ".import respawn_render_row, death_timer" not in scroll:
    errors.append("src/scroll.s: death_timer compatibility reference lacks its import")
if '.segment "CODE3"' not in scroll:
    errors.append("src/scroll.s: missing Phase 13 CODE3 respawn renderer")

state = (ROOT / "src/state.s").read_text()
if ".export respawn_pending, respawn_render_row, death_timer" not in state:
    errors.append("src/state.s: incomplete Phase 13 respawn state export")

for config in ("cfg/c64.cfg", "cfg/c64-test.cfg"):
    if 'CODE3:    load = TUNE,      type = ro, start = $5800;' not in (
        ROOT / config
    ).read_text():
        errors.append(f"{config}: missing CODE3 at $5800")

if errors:
    raise SystemExit("source merge validation failed:\n- " + "\n- ".join(errors))

print("source merge validation: OK")
