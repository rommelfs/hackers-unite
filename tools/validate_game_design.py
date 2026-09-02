#!/usr/bin/env python3
"""Static contract checks for the conference-route redesign."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
constants = (root / "src/constants.inc").read_text()
objects = (root / "src/objects.s").read_text()
powerups = (root / "src/powerups.s").read_text()
finale = (root / "src/finale.s").read_text()
scheduler = (root / "src/scheduler_phase3.s").read_text()
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
for state in ("WALK", "SCREEN", "DEMO", "APPLAUSE", "RESULT"):
    assert f"cmp #GAME_FINALE_{state}" in scheduler
assert "lda applause_events" in scheduler
for code in range(0xA0, 0xA8):
    assert f"lda #${code:02X}" in scheduler, f"missing precise finale failure code ${code:02X}"
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
# Keep the deterministic smoke signature synchronized with the authored Phase-14
# foyer. These are source-level checks because packed assets are regenerated and
# deliberately not committed.
for signature in (
    "static_map+(2*64)+2",
    "static_map+(2*64)+4",
    "static_map+(7*64)+7",
    "static_map+(9*64)+22",
):
    assert signature in scheduler, f"missing Phase-14 smoke signature {signature}"
assert "level1_traps = [22, 43]" in assets
assert "lda #$16                ; world X 352, Phase-14 cable column 22" in scheduler
for signature in (
    "static_map+(7*64)+6",
    "static_map+(6*64)+12",
    "static_map+(7*64)+29",
    "static_map+(7*64)+49",
):
    assert signature in scheduler, f"missing Phase-15 auditorium signature {signature}"
assert "<792" in objects and ">792" in objects
assert "objects_test_object_collision = object_collide" in objects
assert "jsr autotest_collect_foyer_kit" in scheduler
assert "cmp #2" in scheduler[scheduler.index("lda #$51"):scheduler.index("lda #$52")]
pickup_harness = scheduler[scheduler.index("autotest_collect_foyer_kit:"):scheduler.index("autotest_enemy_exact_stomp:")]
assert "stx object_index" in pickup_harness and "ldx object_index" in pickup_harness
# Route choreography may legitimately avoid a hazard. Hazard mechanics belong to
# the focused $58 probe after live VIC assertions, not the grouped secret checks.
secret_checks = scheduler[scheduler.index("lda #$54"):scheduler.index("lda #$55")]
assert "lda #$59" in secret_checks and "trap_hits" not in secret_checks
print("game design validation: OK (4 power-ups, 5 finale states, visual roles)")
