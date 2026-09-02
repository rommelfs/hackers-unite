#!/usr/bin/env python3
"""Validate Phase-2 VIC-II assets and their color-mode contract."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "c64"
manifest = json.loads((ASSETS / "asset-manifest.json").read_text())
charset = (ASSETS / "charset.bin").read_bytes()
chars = (ASSETS / "metatile-chars.bin").read_bytes()
colors = (ASSETS / "metatile-colors.bin").read_bytes()
flags = (ASSETS / "metatile-flags.bin").read_bytes()
tilemap = (ASSETS / "static-map.bin").read_bytes()
world_chars = (ASSETS / "world-chars.bin").read_bytes()
row_colors = (ASSETS / "row-colors.bin").read_bytes()
player_sprites = (ASSETS / "player-sprites.bin").read_bytes()
object_sprites = (ASSETS / "object-sprites.bin").read_bytes()
stance_sprites = (ASSETS / "stance-sprites.bin").read_bytes()
projectile_sprite = (ASSETS / "projectile-sprite.bin").read_bytes()
bomb_sprite = (ASSETS / "bomb-sprite.bin").read_bytes()
boss_sprite = (ASSETS / "boss-sprite.bin").read_bytes()
action_sprites = (ASSETS / "action-sprites.bin").read_bytes()
level_patches = (ASSETS / "level-layout-patches.bin").read_bytes()

errors: list[str] = []
count = manifest["metatile_count"]
map_width, map_height = manifest["map_size_metatiles"]
exit_left, exit_right = manifest["exit_zone_pixels"]
hires_end = manifest["hires_character_range"][1]

if len(charset) != 2048:
    errors.append(f"charset has {len(charset)} bytes, expected 2048")
if len(chars) != count * 4:
    errors.append("metatile character table size mismatch")
if len(colors) != count * 4:
    errors.append("metatile color table size mismatch")
if len(flags) != count:
    errors.append("metatile flag table size mismatch")
if len(tilemap) != map_width * map_height:
    errors.append("static map dimensions mismatch")
if len(world_chars) != map_width * 2 * map_height * 2:
    errors.append("expanded world character dimensions mismatch")
if len(row_colors) != map_height * 2:
    errors.append("row color table dimensions mismatch")
if manifest.get("phase") != 12:
    errors.append("asset manifest must identify the auditorium rebuild as Phase 12")
if manifest.get("campaign_sections") != ["foyer", "auditorium", "stage_rig"]:
    errors.append("Phase-12 campaign section order is invalid")
if manifest.get("final_goal") != "speaker_stage":
    errors.append("Phase-12 final goal must be the speaker stage")
if manifest.get("affordance_revision") != 1:
    errors.append("asset manifest lacks the solid/hazard affordance revision")
if any(color < 8 or color > 15 for color in row_colors):
    errors.append("playfield row colors must select multicolor mode")
if not (0 <= exit_left < exit_right <= map_width * 16):
    errors.append("exit zone lies outside the world")
portal_index = manifest["metatile_names"].index("stage_frame")
vortex_index = manifest["metatile_names"].index("stage_screen")
for portal_y in range(6, 10):
    portal_row = tilemap[portal_y * map_width : (portal_y + 1) * map_width]
    if list(portal_row[56:63]) != [portal_index] + [vortex_index] * 5 + [portal_index]:
        errors.append(f"stage layout mismatch on metatile row {portal_y}")
if len(player_sprites) != manifest["sprite_frame_count"] * 64:
    errors.append("player sprite data is not 64-byte aligned per frame")
if any(player_sprites[index] != 0 for index in range(63, len(player_sprites), 64)):
    errors.append("player sprite padding bytes must be zero")
if len(object_sprites) != manifest["object_sprite_count"] * 64:
    errors.append("object sprite data is not 64-byte aligned per frame")
if len(stance_sprites) != manifest["stance_sprite_count"] * 64:
    errors.append("stance sprite data is not 64-byte aligned per frame")
if len(projectile_sprite) != 64:
    errors.append("projectile sprite must occupy exactly one 64-byte frame")
if any(stance_sprites[index] != 0 for index in range(63, len(stance_sprites), 64)):
    errors.append("stance sprite padding bytes must be zero")
if projectile_sprite[-1] != 0:
    errors.append("projectile sprite padding byte must be zero")
if not any(projectile_sprite[:9]) or any(projectile_sprite[9:63]):
    errors.append("projectile pixels must occupy the hand-aligned top three rows only")
if len(bomb_sprite) != 64 or bomb_sprite[-1] != 0:
    errors.append("bomb sprite must occupy one padded 64-byte frame")
if not any(bomb_sprite[:33]) or any(bomb_sprite[33:63]):
    errors.append("bomb silhouette must occupy only its compact top eleven rows")
if len(boss_sprite) != 64 or boss_sprite[-1] != 0:
    errors.append("boss sprite must be one padded 64-byte frame")
if len(action_sprites) != manifest["action_sprite_count"] * 64:
    errors.append("action sprite table size mismatch")
if any(action_sprites[index] != 0 for index in range(63, len(action_sprites), 64)):
    errors.append("action sprite padding bytes must be zero")
if not level_patches or level_patches[0] != manifest["level_layout_patch_count"]:
    errors.append("level-layout patch count header mismatch")
patch_stride = manifest["level_layout_patch_stride"]
if len(level_patches) != manifest["level_layout_patch_count"] * patch_stride + 1:
    errors.append("level-layout patch table size mismatch")

level2_map = bytearray(tilemap)
level3_map = bytearray(tilemap)
level2_world_chars = bytearray(world_chars)
level3_world_chars = bytearray(world_chars)
for patch_offset in range(1, len(level_patches), patch_stride):
    map_offset = level_patches[patch_offset] | (level_patches[patch_offset + 1] << 8)
    world_offset = level_patches[patch_offset + 2] | (level_patches[patch_offset + 3] << 8)
    base_tile = level_patches[patch_offset + 4]
    level2_tile = level_patches[patch_offset + 5]
    level3_tile = level_patches[patch_offset + 6]
    if map_offset >= len(tilemap) or world_offset + 129 >= len(world_chars):
        errors.append(f"level-layout patch {(patch_offset - 1) // patch_stride} is out of range")
        continue
    if tilemap[map_offset] != base_tile:
        errors.append(f"level-layout patch {(patch_offset - 1) // patch_stride} has wrong base tile")
        continue
    level2_map[map_offset] = level2_tile
    char_index = level2_tile * 4
    level2_world_chars[world_offset] = chars[char_index]
    level2_world_chars[world_offset + 1] = chars[char_index + 1]
    level2_world_chars[world_offset + 128] = chars[char_index + 2]
    level2_world_chars[world_offset + 129] = chars[char_index + 3]
    level3_map[map_offset] = level3_tile
    char_index = level3_tile * 4
    level3_world_chars[world_offset] = chars[char_index]
    level3_world_chars[world_offset + 1] = chars[char_index + 1]
    level3_world_chars[world_offset + 128] = chars[char_index + 2]
    level3_world_chars[world_offset + 129] = chars[char_index + 3]
if level2_map == tilemap or level2_world_chars == world_chars:
    errors.append("level 2 must differ from the base map and expanded world")
if level3_map in (tilemap, level2_map) or level3_world_chars in (world_chars, level2_world_chars):
    errors.append("level 3 must be a distinct map and expanded world")

chair_indices = {
    manifest["metatile_names"].index("chair_back_a"),
    manifest["metatile_names"].index("chair_back_b"),
    manifest["metatile_names"].index("audience_a"),
    manifest["metatile_names"].index("audience_b"),
}
if sum(tile in chair_indices for tile in tilemap) < 80:
    errors.append("auditorium lacks the repeated chair banks required by Phase 12")
chair_row_index = manifest["metatile_names"].index("chair_row")
if flags[chair_row_index] != 1:
    errors.append("foreground chair rows must be unambiguously solid")
tech_gantry_index = manifest["metatile_names"].index("tech_gantry")
hall_wall_index = manifest["metatile_names"].index("hall_wall")
for name in manifest.get("solid_metatiles", []):
    index = manifest["metatile_names"].index(name)
    if flags[index] != 1:
        errors.append(f"declared solid metatile {name} lacks the exclusive SOLID flag")
    if not all(chars[index * 4 + cell] for cell in range(4)):
        errors.append(f"declared solid metatile {name} has a visually open cell")
for index in (chair_row_index, tech_gantry_index, hall_wall_index):
    glyph_bytes = b"".join(
        charset[chars[index * 4 + cell] * 8 : chars[index * 4 + cell] * 8 + 8]
        for cell in range(4)
    )
    if any(((byte >> shift) & 3) == 0 for byte in glyph_bytes for shift in (0, 2, 4, 6)):
        errors.append("load-bearing metatile contains a visually open pixel")
for name in manifest.get("hazard_metatiles", []):
    index = manifest["metatile_names"].index(name)
    if flags[index] != 2:
        errors.append(f"declared hazard metatile {name} must be hazardous and non-solid")
for name in manifest.get("decoration_metatiles", []):
    index = manifest["metatile_names"].index(name)
    if flags[index] & 3:
        errors.append(f"declared decoration metatile {name} affects collision")
rubble_index = manifest["metatile_names"].index("fallen_chair")
for layout_name, layout in (("foyer", tilemap), ("auditorium", level2_map), ("stage", level3_map)):
    foot_row = layout[9 * map_width : 10 * map_width]
    if rubble_index in foot_row:
        errors.append(f"{layout_name} places non-colliding rubble on the player foot line")
if flags[portal_index] & 3 or flags[vortex_index] & 3:
    errors.append("stage frame and screen must remain decorative/non-solid")
for section_name, layout_map in (
    ("foyer", tilemap), ("auditorium", level2_map), ("stage rig", level3_map)
):
    for stage_y in range(6, 10):
        stage_row = layout_map[stage_y * map_width : (stage_y + 1) * map_width]
        if list(stage_row[56:63]) != [portal_index] + [vortex_index] * 5 + [portal_index]:
            errors.append(f"{section_name} loses the visible stage target on row {stage_y}")

# Rows 8 and 9 form the continuous ground-level traversal corridor. A solid
# metatile here becomes an unpassable 16-pixel wall and can trap a ground item.
for layout_name, layout_map in (("level 1", tilemap), ("level 2", level2_map), ("level 3", level3_map)):
    for corridor_row in (8, 9):
        solid_columns = [
            column
            for column in range(map_width)
            if flags[layout_map[corridor_row * map_width + column]] & 1
        ]
        allowed = []
        if layout_name == "level 2" and corridor_row == 8:
            tunnel_left, tunnel_right = manifest["level2_crawl_tunnel"]
            allowed = list(range(tunnel_left, tunnel_right + 1))
        if solid_columns != allowed:
            errors.append(
                f"{layout_name} blocks ground corridor row {corridor_row} "
                f"at columns {solid_columns}, expected {allowed}"
            )

# The foyer teaches one safe ground pickup, then uses two broad elevated rewards.
for pickup_index, (pickup_x, pickup_y) in enumerate(manifest["level1_pickups"]):
    support_x = pickup_x // 16
    support_y = (pickup_y + 21) // 16
    if not (flags[tilemap[support_y * map_width + support_x]] & 1):
        errors.append(f"foyer kit item at ({pickup_x},{pickup_y}) lacks solid support")
    if pickup_index == 0 and pickup_x >= manifest["level1_traps"][0] * 16:
        errors.append("foyer ENTRY pickup must precede the first taught trap")
    if pickup_index > 0 and pickup_y == 139:
        errors.append("later foyer kit rewards must teach elevated route reading")

safe_start_end = manifest["level1_safe_start_end"]
if any(flags[tilemap[9 * map_width + x]] & 2 for x in range(safe_start_end + 1)):
    errors.append("foyer safe start contains a floor hazard")
if manifest["level1_teaching_enemy_x"] // 16 >= manifest["level1_traps"][0]:
    errors.append("foyer does not teach its first patrol before its first cable")
for recovery_left, recovery_right in manifest["level1_recovery_spans"]:
    if recovery_right - recovery_left < 1:
        errors.append("foyer recovery span is too short")
    if any(flags[tilemap[9 * map_width + x]] & 2 for x in range(recovery_left, recovery_right + 1)):
        errors.append("foyer recovery span contains a hazard")

# The mutable secret at (10,8) is injected by physics rather than stored in the
# static map. A solid row-7 platform directly above it creates a 32-pixel wall
# with no player-height corridor and blocks the mandatory route before scrolling.
hidden_x, hidden_y = manifest["level1_hidden_block"]
if flags[tilemap[(hidden_y - 1) * map_width + hidden_x]] & 1:
    errors.append("foyer stacks solid geometry above the mutable hidden block")

# Every Level-2 objective sits exactly 21 pixels above an authoritative solid
# platform. The 48-pixel tier is reachable only with the implemented run jump.
for pickup_x, pickup_y in manifest["level2_pickups"]:
    support_x = pickup_x // 16
    support_y = (pickup_y + 21) // 16
    if not (flags[level2_map[support_y * map_width + support_x]] & 1):
        errors.append(f"level 2 pickup at ({pickup_x},{pickup_y}) lacks solid support")
    platform_top = support_y * 16
    if 160 - platform_top > 48:
        errors.append(f"level 2 pickup at ({pickup_x},{pickup_y}) exceeds run-jump tier")

# Phase 15 authors two explicit upper-route waves over the continuous lower
# aisle. Validate the complete declared landing surfaces rather than relying on
# a few smoke-test coordinates that drift whenever the route is recomposed.
for segment_left, segment_right, segment_row in manifest["level2_upper_segments"]:
    if segment_left > segment_right or segment_row not in (6, 7):
        errors.append("level 2 upper-route segment metadata is invalid")
        continue
    segment = level2_map[
        segment_row * map_width + segment_left:
        segment_row * map_width + segment_right + 1
    ]
    if any(not (flags[tile] & 1) for tile in segment):
        errors.append(
            f"level 2 upper route is not continuous at row {segment_row}, "
            f"columns {segment_left}-{segment_right}"
        )
for entry in manifest["level2_branch_entries"]:
    if not (flags[level2_map[7 * map_width + entry]] & 1):
        errors.append(f"level 2 branch entry {entry} lacks a row-7 approach")
for rejoin in manifest["level2_rejoins"]:
    if not (flags[level2_map[7 * map_width + rejoin]] & 1):
        errors.append(f"level 2 upper route does not rejoin at column {rejoin}")
for pickup_x, pickup_y in manifest["level3_pickups"]:
    support_x = pickup_x // 16
    support_y = (pickup_y + 21) // 16
    if not (flags[level3_map[support_y * map_width + support_x]] & 1):
        errors.append(f"level 3 pickup at ({pickup_x},{pickup_y}) lacks solid support")
    if 160 - support_y * 16 > 64:
        errors.append(f"level 3 pickup at ({pickup_x},{pickup_y}) is unreachable")
step_left, step_right = manifest["level3_step_platform"]
platform_index = manifest["metatile_names"].index("tech_gantry")
if list(level3_map[7 * map_width + step_left : 7 * map_width + step_right + 1]) != [
    platform_index
] * (step_right - step_left + 1):
    errors.append("level 3 high tier lacks its reachable row-7 approach step")

hazard_index = manifest["metatile_names"].index("cable_trap")
if flags[hazard_index] != 2:
    errors.append("spike trap must be HAZARD-only, never SOLID")
for layout_name, layout_map, expected in (
    ("level 1", tilemap, manifest["level1_traps"]),
    ("level 2", level2_map, manifest["level2_traps"]),
    ("level 3", level3_map, manifest["level3_spike_traps"]),
):
    actual = [x for x in range(map_width) if layout_map[9 * map_width + x] == hazard_index]
    if actual != expected:
        errors.append(f"{layout_name} trap columns {actual}, expected {expected}")
    for x in actual:
        if not (flags[layout_map[10 * map_width + x]] & 1):
            errors.append(f"{layout_name} trap column {x} lacks solid floor support")
electric_index = manifest["metatile_names"].index("live_cable")
if flags[electric_index] != 2:
    errors.append("electric trap must be HAZARD-only, never SOLID")
actual_electric = [x for x in range(map_width) if level3_map[9 * map_width + x] == electric_index]
if actual_electric != manifest["level3_electric_traps"]:
    errors.append(
        f"level 3 electric columns {actual_electric}, expected {manifest['level3_electric_traps']}"
    )
level3_hazards = sorted(manifest["level3_spike_traps"] + manifest["level3_electric_traps"])
for column in level3_hazards:
    if column - 1 not in level3_hazards and column + 1 not in level3_hazards:
        errors.append(f"level 3 hazard column {column} is an ambiguous isolated trap")
for lane in manifest["level3_falling_lanes"]:
    if any(abs(column - lane) < 3 for column in level3_hazards):
        errors.append(f"level 3 falling lane {lane} lacks a two-column safe floor buffer")
# Static row colors mean trap contrast must live in the glyph bit pairs. Both
# hazards require the bright shared background-2 ink, while their packed shapes
# must remain visibly different.
spike_glyphs = charset[88 * 8 : 90 * 8] + charset[96 * 8 : 98 * 8]
electric_glyphs = charset[94 * 8 : 96 * 8] + charset[98 * 8 : 100 * 8]
if not any(byte & 0xAA for byte in spike_glyphs):
    errors.append("spike glyphs lack bright background-2 contrast")
if not any(byte & 0xAA for byte in electric_glyphs):
    errors.append("electric glyphs lack bright background-2 contrast")
if spike_glyphs == electric_glyphs:
    errors.append("spike and electric glyph silhouettes must differ")
for hazard_name, glyph_data in (("spike", spike_glyphs), ("electric", electric_glyphs)):
    if any(((byte >> shift) & 3) == 3 for byte in glyph_data for shift in (0, 2, 4, 6)):
        errors.append(f"{hazard_name} glyphs may not use green floor ink")
if chars[hazard_index * 4] == 0 or chars[electric_index * 4] == 0:
    errors.append("floor hazards must occupy both character rows for a full-height warning")
warning_index = manifest["metatile_names"].index("rig_warning")
for lane in manifest["level3_falling_lanes"]:
    if level3_map[2 * map_width + lane] != warning_index:
        errors.append(f"level 3 falling lane {lane} lacks its overhead warning panel")
if not (0 <= manifest["level3_rolling_spawn"] < map_width * 16):
    errors.append("level 3 rolling-ball spawn lies outside the world")
if any(object_sprites[index] != 0 for index in range(63, len(object_sprites), 64)):
    errors.append("object sprite padding bytes must be zero")
speaker_kit_frames = [object_sprites[index * 64 : (index + 1) * 64] for index in (1, 2, 3)]
if len(set(speaker_kit_frames)) != 3 or any(not any(frame[:63]) for frame in speaker_kit_frames):
    errors.append("badge, slide USB and coffee must be three distinct visible sprites")

for index, (char, color) in enumerate(zip(chars, colors)):
    if color > 15:
        errors.append(f"cell {index}: invalid color {color}")
    if char <= hires_end and color >= 8:
        errors.append(f"cell {index}: hires char {char} selects multicolor via color {color}")
    if char > hires_end and color < 8:
        errors.append(f"cell {index}: multicolor char {char} lacks color-RAM mode bit")

legal_mask = manifest["legal_flags_mask"]
for index, value in enumerate(flags):
    if value & ~legal_mask:
        errors.append(f"metatile {index}: illegal flags ${value:02x}")
for index, value in enumerate(tilemap):
    if value >= count:
        errors.append(f"map cell {index}: metatile index {value} out of range")

# Pickup-looking character tiles are retained as source vocabulary only. In the
# playable map they would be false affordances because collection is sprite-based.
for pickup_name in ("badge_symbol", "slides_symbol", "coffee_symbol"):
    pickup_index = manifest["metatile_names"].index(pickup_name)
    if pickup_index in tilemap:
        errors.append(f"map contains non-interactive pickup lookalike: {pickup_name}")

if errors:
    raise SystemExit("asset validation failed:\n- " + "\n- ".join(errors))

row_costs = []
for row in range(map_height):
    cells = tilemap[row * map_width : (row + 1) * map_width]
    row_costs.append(sum(len(set(colors[cell * 4 : cell * 4 + 4])) for cell in cells))
print(
    "asset validation: OK "
    f"({count} metatiles, {map_width}x{map_height}, color-cost max={max(row_costs)}, scroll-color-writes=0)"
)
