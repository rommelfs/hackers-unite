#!/usr/bin/env python3
"""Static contract checks for the conference-route redesign."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
constants = (root / "src/constants.inc").read_text()
objects = (root / "src/objects.s").read_text()
powerups = (root / "src/powerups.s").read_text()
finale = (root / "src/finale.s").read_text()
assets = (root / "tools/build_c64_assets.py").read_text()
for name in ("POWER_RAPID", "POWER_STRONG", "POWER_SPEED", "POWER_EXTRA_LIFE"):
    assert name in constants and name in powerups, f"missing power-up {name}"
assert ".byte POWER_RAPID, POWER_STRONG, POWER_SPEED, POWER_EXTRA_LIFE" in powerups
assert "ora object_persistence" in objects, "pickup one-shot persistence missing"
assert "inc extra_lives_collected" in powerups
for state in ("WALK", "SCREEN", "DEMO", "APPLAUSE", "RESULT"):
    assert f"GAME_FINALE_{state}" in constants
assert "sta projectile_active" in finale and "sta boss_shot_active" in finale
for role in ("SOLID", "HAZARD", "DECORATION"):
    assert role in assets
for landmark in ("chair_row", "cable_trap", "live_cable", "stage_screen"):
    assert landmark in assets
print("game design validation: OK (4 power-ups, 5 finale states, visual roles)")
