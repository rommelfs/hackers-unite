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
for row in (
    ".byte POWER_RAPID, POWER_STRONG, POWER_SPEED",
    ".byte POWER_RAPID, POWER_STRONG, POWER_EXTRA_LIFE",
    ".byte POWER_SPEED, POWER_STRONG, POWER_EXTRA_LIFE",
):
    assert row in powerups
assert "object_type_table:" in objects
assert objects.count(".byte TYPE_ENEMY, TYPE_ENEMY, TYPE_ENEMY") >= 3
assert objects.count("object_type_table:") == 1
for obsolete in (
    "object_types_l2:", "object_types_l3:",
    "l1_object_types:", "l2_object_types:", "l3_object_types:",
):
    assert obsolete not in objects, f"obsolete split object table returned: {obsolete}"
assert "ora object_persistence" in objects, "pickup one-shot persistence missing"
assert "inc extra_lives_collected" in powerups
for state in ("WALK", "SCREEN", "DEMO", "APPLAUSE", "RESULT"):
    assert f"GAME_FINALE_{state}" in constants
assert "sta projectile_active" in finale and "sta boss_shot_active" in finale
# ca65 cheap-local labels are scoped by the previous non-local label. The object
# type helper must not split object_collide from its later @enemy/@boss handlers.
collide = objects.index("object_collide:")
no_hit = objects.index("@no_hit:", collide)
helper = objects.index("object_type_for_level:")
assert helper > no_hit, "object type helper breaks object_collide cheap-label scope"
for role in ("SOLID", "HAZARD", "DECORATION"):
    assert role in assets
for landmark in ("chair_row", "cable_trap", "live_cable", "stage_screen"):
    assert landmark in assets
print("game design validation: OK (4 power-ups, 5 finale states, visual roles)")
