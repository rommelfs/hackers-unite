#!/usr/bin/env python3
"""Build deterministic Phase-2 C64 graphics from compact source definitions."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "c64"

FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
    "6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    "/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
    ":": ["00000", "00100", "00100", "00000", "00100", "00100", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "00100", "00100"],
}


def hires(rows: list[str]) -> bytes:
    data = [0]
    for row in rows:
        value = 0
        for bit in row:
            value = (value << 1) | (bit == "1")
        data.append(value << 1)
    return bytes(data[:8])


def mc(*rows: str) -> bytes:
    if len(rows) != 8 or any(len(row) != 4 for row in rows):
        raise ValueError("multicolor characters require eight rows of four pixels")
    return bytes(sum(int(pixel) << (6 - index * 2) for index, pixel in enumerate(row)) for row in rows)


def sprite(*rows: str) -> bytes:
    if len(rows) != 21 or any(len(row) != 12 for row in rows):
        raise ValueError("sprites require 21 rows of twelve multicolor pixels")
    output = bytearray()
    for row in rows:
        value = sum(int(pixel) << (22 - index * 2) for index, pixel in enumerate(row))
        output.extend(value.to_bytes(3, "big"))
    output.append(0)
    return bytes(output)


charset = [bytes(8) for _ in range(256)]
for index, letter in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ", start=1):
    charset[index] = hires(FONT[letter])
for number in range(10):
    charset[27 + number] = hires(FONT[str(number)])
for index, symbol in enumerate("-/:.", start=37):
    charset[index] = hires(FONT[symbol])

glyphs = {
    64: mc("3333", "3333", "3333", "3333", "3333", "3333", "3333", "3333"),
    65: mc("1111", "1331", "3113", "1331", "3113", "1331", "3113", "1111"),
    66: mc("1111", "1001", "1221", "1001", "1221", "1001", "1001", "1111"),
    67: mc("2222", "1111", "3030", "3333", "3030", "3333", "1010", "1111"),
    68: mc("1111", "3030", "3333", "3030", "3333", "1010", "1111", "1010"),
    69: mc("0000", "0330", "3223", "3113", "3113", "3333", "3003", "3003"),
    70: mc("0000", "0330", "3113", "3223", "3113", "3333", "3003", "3003"),
    71: mc("0000", "1111", "2222", "1111", "0000", "0330", "0000", "0000"),
    72: mc("0130", "0130", "0130", "0130", "0130", "0130", "0130", "0130"),
    73: mc("0130", "0130", "0130", "0111", "0003", "0003", "0003", "0003"),
    74: mc("1110", "1220", "1210", "1220", "1210", "1220", "1210", "1110"),
    75: mc("0111", "0221", "0121", "0221", "0121", "0221", "0121", "0111"),
    76: mc("1110", "1220", "1210", "1220", "1210", "1220", "1110", "0000"),
    77: mc("0111", "0221", "0121", "0221", "0121", "0221", "0111", "0000"),
    78: mc("1111", "1221", "2332", "3223", "3223", "2332", "1221", "1111"),
    79: mc("1111", "1221", "2322", "3232", "2323", "2232", "1221", "1111"),
    80: mc("1111", "1221", "1231", "1221", "1111", "0330", "3003", "3333"),
    81: mc("0330", "3003", "3003", "3333", "3213", "3213", "3333", "0000"),
    82: mc("0030", "0130", "0330", "3223", "3333", "1331", "0330", "0000"),
    83: mc("0330", "3003", "0300", "0030", "3003", "0330", "0000", "0000"),
    84: mc("0000", "1111", "1221", "1331", "1221", "1111", "0030", "0030"),
    85: mc("0000", "0000", "2220", "0010", "0020", "0000", "0000", "0000"),
    86: mc("0330", "3223", "3113", "3113", "3333", "3003", "3003", "0000"),
    87: mc("0000", "0300", "0330", "3030", "3303", "0033", "0330", "3003"),
    88: mc("2211", "2111", "1111", "1221", "2222", "1111", "2222", "1111"),
    89: mc("1122", "1112", "1111", "1221", "2222", "1111", "2222", "1111"),
    90: mc("0000", "0000", "0101", "1010", "0101", "1010", "3333", "1111"),
    91: mc("0000", "0300", "0030", "0300", "0030", "0300", "3333", "1111"),
    92: mc("1111", "3003", "0330", "3003", "0330", "3003", "1111", "0000"),
    93: mc("3333", "1001", "1331", "1031", "1301", "1331", "1001", "3333"),
    94: mc("0200", "2200", "2100", "0120", "0022", "0020", "0200", "2222"),
    95: mc("0020", "0022", "0012", "0210", "2200", "0200", "0020", "2222"),
    96: mc("0000", "0000", "0000", "0002", "0022", "0021", "0211", "2211"),
    97: mc("0000", "0000", "0000", "2000", "2200", "1200", "1120", "1122"),
    98: mc("0020", "0200", "0220", "0020", "0210", "2100", "2200", "0200"),
    99: mc("0200", "0020", "0220", "0200", "0120", "0012", "0022", "0020"),
    # Safe, load-bearing geometry uses an unbroken bright lip and visible
    # supports through the complete 16-pixel metatile. Background chairs never
    # use this silhouette, so landing surfaces read before their collision box.
    100: mc("3333", "3333", "1111", "1311", "1311", "1311", "1311", "1311"),
    101: mc("3333", "3333", "1111", "1131", "1131", "1131", "1131", "1131"),
    102: mc("1311", "1311", "1311", "1311", "1311", "1111", "3333", "3333"),
    103: mc("1131", "1131", "1131", "1131", "1131", "1111", "3333", "3333"),
    # Stage-rig platforms share the same solid outline but add diagonal warning
    # braces. The outline, rather than the warning color, communicates solidity.
    104: mc("3333", "3333", "1111", "1122", "1112", "1121", "1112", "1121"),
    105: mc("3333", "3333", "1111", "2211", "2111", "1211", "2111", "1211"),
    106: mc("1121", "1112", "1121", "1112", "1121", "1111", "3333", "3333"),
    107: mc("1211", "2111", "1211", "2111", "1211", "1111", "3333", "3333"),
    # Full-height blocking wall: closed border and cross-brace, with no open
    # bottom that could suggest a crawl-through decoration.
    108: mc("3333", "3111", "3131", "3113", "3131", "3111", "3131", "3333"),
    109: mc("3333", "1113", "1313", "3113", "1313", "1113", "1313", "3333"),
    110: mc("3333", "3131", "3111", "3131", "3113", "3131", "3111", "3333"),
    111: mc("3333", "1313", "1113", "1313", "3113", "1313", "1113", "3333"),
}
for index, data in glyphs.items():
    charset[index] = data

SOLID = 1
HAZARD = 1 << 1
DECORATION = 1 << 7
metatiles: list[tuple[str, list[int], list[int], int]] = []


def tile(name: str, chars: list[int], colors: list[int], flags: int = 0) -> int:
    if len(chars) != 4 or len(colors) != 4:
        raise ValueError(name)
    metatiles.append((name, chars, colors, flags))
    return len(metatiles) - 1


EMPTY = tile("empty", [0, 0, 0, 0], [0, 0, 0, 0])
SKY_A = tile("chair_back_a", [0, 0, 69, 70], [0, 0, 8, 8], DECORATION)
SKY_B = tile("chair_back_b", [0, 0, 70, 69], [0, 0, 8, 8], DECORATION)
SKY_DENSE_A = tile("audience_a", [69, 70, 69, 70], [8, 8, 8, 8], DECORATION)
SKY_DENSE_B = tile("audience_b", [70, 69, 70, 69], [8, 8, 8, 8], DECORATION)
CABLE_H = tile("ceiling_light", [71, 71, 0, 0], [11, 11, 0, 0], DECORATION)
CABLE_V = tile("hanging_cable", [72, 0, 72, 0], [11, 0, 11, 0], DECORATION)
CABLE_CORNER = tile("light_corner", [73, 71, 0, 0], [11, 11, 0, 0], DECORATION)
FLOOR = tile("aisle_floor", [67, 67, 68, 68], [13, 13, 11, 11], SOLID)
FLOOR_CRACK = tile("aisle_marker", [67, 67, 66, 68], [13, 13, 11, 11], SOLID)
PLATFORM = tile("chair_row", [100, 101, 102, 103], [13, 13, 13, 13], SOLID)
WALL = tile("hall_wall", [108, 109, 110, 111], [11, 11, 11, 11], SOLID)
PORTAL_BLOCK = tile("stage_frame", [74, 75, 76, 77], [9, 9, 11, 11], DECORATION)
TWO_TOP = tile("banner_top", [76, 75, 74, 65], [9, 9, 9, 11], DECORATION)
TWO_MID = tile("banner_mid", [65, 74, 74, 65], [11, 9, 9, 11], DECORATION)
TWO_BOTTOM = tile("banner_bottom", [74, 65, 76, 65], [9, 11, 9, 11], DECORATION)
ZERO_TL = tile("stage_arch_tl", [76, 75, 74, 0], [9, 9, 9, 0], DECORATION)
ZERO_TR = tile("stage_arch_tr", [74, 77, 0, 75], [9, 9, 0, 9], DECORATION)
ZERO_ML = tile("stage_arch_ml", [74, 0, 74, 0], [9, 0, 9, 0], DECORATION)
ZERO_MR = tile("stage_arch_mr", [0, 75, 0, 75], [0, 9, 0, 9], DECORATION)
ZERO_BL = tile("stage_arch_bl", [74, 0, 76, 75], [9, 0, 9, 9], DECORATION)
ZERO_BR = tile("stage_arch_br", [0, 75, 74, 77], [0, 9, 9, 9], DECORATION)
VORTEX_A = tile("stage_screen", [78, 79, 79, 78], [13, 13, 13, 13], DECORATION)
TERMINAL = tile("av_cart", [80, 80, 72, 72], [13, 13, 11, 11], DECORATION)
LOCK = tile("badge_symbol", [0, 81, 0, 0], [0, 15, 0, 0], DECORATION)
ONION = tile("slides_symbol", [0, 82, 0, 0], [0, 9, 0, 0], DECORATION)
CHAIN = tile("coffee_symbol", [0, 83, 0, 0], [0, 9, 0, 0], DECORATION)
DRONE = tile("projector", [84, 85, 0, 0], [11, 10, 0, 0], DECORATION)
SIGNAL = tile("exit_sign", [0, 85, 0, 0], [0, 10, 0, 0], DECORATION)
RUBBLE = tile("fallen_chair", [0, 0, 87, 66], [0, 0, 11, 11], DECORATION)
SPIKE_TRAP = tile("cable_trap", [96, 97, 88, 89], [10, 10, 10, 10], HAZARD)
ELECTRIC_TRAP = tile("live_cable", [98, 99, 94, 95], [15, 15, 15, 15], HAZARD)
FACTORY_PANEL = tile("tech_panel", [92, 93, 93, 92], [11, 11, 11, 11], DECORATION)
DROP_WARNING = tile("rig_warning", [90, 91, 91, 90], [10, 10, 10, 10], DECORATION)
FACTORY_PLATFORM = tile("tech_gantry", [104, 105, 106, 107], [10, 10, 10, 10], SOLID)

width, height = 64, 12
world = [[EMPTY for _ in range(width)] for _ in range(height)]
# The base layout is the foyer teaching level. Conference seating remains in the
# background, but broad black sight-lines split it into readable play beats:
# arrival, first opponent, cable lesson, reward route, and stage approach.
aisle_columns = {
    0, 1, 2, 3, 10, 11, 12, 13, 20, 21, 30, 31,
    40, 41, 51, 52, 58, 59, 60, 61, 62, 63,
}
for x in range(width):
    if x % 4 == 1:
        world[0][x] = CABLE_H
    if x not in aisle_columns:
        world[2][x] = SKY_A if x % 2 == 0 else SKY_B
        world[4][x] = SKY_DENSE_A if x % 2 == 0 else SKY_DENSE_B
        world[6][x] = SKY_A if x % 2 == 0 else SKY_B
    world[10][x] = FLOOR_CRACK if x % 8 == 4 else FLOOR
    world[11][x] = WALL

# Suspended AV details mark the boundaries between challenges without looking
# collectible or changing the authoritative collision map.
for x in (12, 30, 41, 52):
    world[1][x] = CABLE_V
for x in (21, 42):
    world[3][x] = DRONE
# Never place non-colliding rubble on the foot line: it looked like a blocking
# object despite carrying decoration-only flags. The clear aisle is intentional.
world[8][13] = TERMINAL
world[8][32] = TERMINAL
world[3][16] = SIGNAL
world[3][38] = SIGNAL

# The foyer uses short, separated landings rather than a regular obstacle grid.
# The first raised row is optional; later rows carry required kit and teach the
# full production run jump with generous take-off and landing space.
for start, finish, row in (
    (5, 9, 7), (25, 30, 7), (34, 39, 7),
    (46, 51, 7), (53, 56, 6),
):
    for x in range(start, finish):
        world[row][x] = PLATFORM

# The far-right construction reads as the illuminated stage. It is restamped
# after each layout variant so later platform authoring cannot cover its screen.
def stamp_stage(layout: list[list[int]]) -> None:
    for y in range(4, 10):
        layout[y][56] = PORTAL_BLOCK
        for x in range(57, 62):
            layout[y][x] = VORTEX_A
        layout[y][62] = PORTAL_BLOCK


stamp_stage(world)

# Two isolated cable fields are each preceded and followed by long safe ground.
# The first appears only after movement, one pickup, and one patrol have been
# taught; the second combines the already-known jump with an elevated reward.
level1_traps = [22, 43]
for x in level1_traps:
    world[9][x] = SPIKE_TRAP

# Phase-12 three-section table. Only changed metatiles are stored in the PRG; the
# runtime can apply either side of every patch, so a new game can also restore
# layout 1 after layout 2 has modified the RAM-backed map.
level2_world = [row[:] for row in world]

# The auditorium restores denser chair banks and its own regular landing rhythm,
# so it reads as a new location rather than a palette/label swap of the foyer.
for x in range(width):
    if x not in {0, 1, 12, 13, 30, 31, 49, 50, 58, 59, 60, 61, 62, 63}:
        level2_world[2][x] = SKY_A if x % 2 == 0 else SKY_B
        level2_world[4][x] = SKY_DENSE_A if x % 2 == 0 else SKY_DENSE_B
        level2_world[6][x] = SKY_A if x % 2 == 0 else SKY_B

# Remove the foyer-only foreground landings before authoring the auditorium.
for y in (5, 6, 7):
    for x in range(2, 57):
        if level2_world[y][x] == PLATFORM:
            level2_world[y][x] = EMPTY
for start, finish, row in (
    # Two readable upper-route waves sit above the continuous lower aisle. Each
    # begins and ends on the 48-pixel row-7 tier; row 6 is reached only from a
    # row-7 approach, never by a blind/impossible ground jump.
    (6, 11, 7), (12, 18, 6), (20, 26, 6), (28, 33, 7),
    (35, 40, 7), (41, 47, 6), (48, 54, 7),
):
    for x in range(start, finish):
        level2_world[row][x] = PLATFORM

# A low data conduit creates a genuine crawl-only floor route.
for x in range(34, 37):
    level2_world[8][x] = PLATFORM

# The main seating section combines inherited and additional cable traps around
# chair-row landings and the hostile AV-boss approach.
for x in level1_traps:
    level2_world[9][x] = EMPTY
level2_traps = [12, 22, 32, 43, 50]
for x in level2_traps:
    level2_world[9][x] = SPIKE_TRAP
stamp_stage(level2_world)

# The final backstage/stage section adds technical gantries, two visually
# distinct cable hazards and explicit rig warnings for falling loudspeakers.
level3_world = [row[:] for row in world]
for x in range(width):
    level3_world[1][x] = FACTORY_PANEL if x % 2 == 0 else DROP_WARNING
for y in (5, 6, 7):
    for x in range(5, 59):
        if level3_world[y][x] == PLATFORM:
            level3_world[y][x] = EMPTY
for start, finish, row in (
    (15, 20, 7), (29, 35, 7), (40, 44, 7), (44, 51, 6), (54, 58, 7),
):
    for x in range(start, finish):
        level3_world[row][x] = FACTORY_PLATFORM
for x in (26, 41, 53):
    level3_world[2][x] = DROP_WARNING
    level3_world[3][x] = CABLE_V

# The first factory run teaches hazards as three unmistakable two-tile fields,
# with long safe approach and landing zones. Dynamic debris and the rolling
# ball provide the later action instead of a carpet of isolated floor damage.
level3_spike_traps = [8, 9, 37, 38]
level3_electric_traps = [22, 23]
for x in level1_traps:
    level3_world[9][x] = EMPTY
for x in level3_spike_traps:
    level3_world[9][x] = SPIKE_TRAP
for x in level3_electric_traps:
    level3_world[9][x] = ELECTRIC_TRAP
stamp_stage(level3_world)

level_layout_patches = bytearray()
for meta_y in range(height):
    for meta_x in range(width):
        base_tile = world[meta_y][meta_x]
        level2_tile = level2_world[meta_y][meta_x]
        level3_tile = level3_world[meta_y][meta_x]
        if base_tile == level2_tile == level3_tile:
            continue
        map_offset = meta_y * width + meta_x
        world_offset = meta_y * 2 * width * 2 + meta_x * 2
        level_layout_patches.extend(
            [
                map_offset & 0xFF,
                map_offset >> 8,
                world_offset & 0xFF,
                world_offset >> 8,
                base_tile,
                level2_tile,
                level3_tile,
            ]
        )

# Pre-expand metatiles for the time-bounded Phase-3 viewport rebuild.
world_chars = [[0 for _ in range(width * 2)] for _ in range(height * 2)]
for meta_y, row in enumerate(world):
    for meta_x, meta_index in enumerate(row):
        _, chars4, _, _ = metatiles[meta_index]
        world_chars[meta_y * 2][meta_x * 2 : meta_x * 2 + 2] = chars4[0:2]
        world_chars[meta_y * 2 + 1][meta_x * 2 : meta_x * 2 + 2] = chars4[2:4]

# Fixed per-row Color-RAM zones eliminate steady-state scroll color writes.
row_colors = bytes([11, 11, 8, 8, 8, 9, 9, 11, 11, 13, 13, 13, 13, 11, 11, 11, 11, 11, 13, 13, 13, 11, 11, 11])

player_sprites = b"".join(
    [
        sprite(
            "000001100000", "000012210000", "000012210000", "000001100000",
            "000011110000", "000132231000", "001132231100", "001133331100",
            "000133331000", "000133331000", "000013310000", "000013310000",
            "000013310000", "000031130000", "000031130000", "000310013000",
            "000310013000", "003100001300", "003100001300", "031000000130",
            "000000000000",
        ),
        sprite(
            "000001100000", "000012210000", "000012210000", "000001100000",
            "000011110000", "000132231000", "001132231100", "001133331100",
            "000133331000", "000133331000", "000013310000", "000013310000",
            "000031130000", "000310130000", "003100130000", "031000130000",
            "310000130000", "000000013000", "000000013000", "000000001300",
            "000000000000",
        ),
        sprite(
            "000001100000", "000012210000", "000012210000", "000001100000",
            "000011110000", "000132231000", "001132231100", "001133331100",
            "000133331000", "000133331000", "000013310000", "000013310000",
            "000013130000", "000013013000", "000013001300", "000013000130",
            "000130000013", "001300000000", "001300000000", "013000000000",
            "000000000000",
        ),
        sprite(
            "000001100000", "000012210000", "000012210000", "000001100000",
            "000111111000", "001132231100", "011132231110", "001133331100",
            "000133331000", "000133331000", "000013310000", "000013310000",
            "000031130000", "000310013000", "003100001300", "031000000130",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
    ]
)

# Low-profile player poses. Their pixels sit in the bottom half of the normal
# 21-line sprite cell so changing pose never changes the authoritative feet Y.
stance_sprites = b"".join(
    [
        sprite(
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000", "000000000000", "000001100000", "000012210000",
            "000012210000", "000001100000", "000111111000", "001132231100",
            "011133331110", "001133331100", "000311113000", "003100001300",
            "031000000130", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
        sprite(
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000", "000000000000", "000000000000", "000001100000",
            "000012210000", "000012210000", "000111111000", "011132231110",
            "113333333311", "033111111330", "003100001300", "031000000130",
            "310000000013", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
    ]
)

projectile_sprite = sprite(
    "000001100000", "000013310000", "000001100000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000",
)

bomb_sprite = sprite(
    "000000100000", "000001300000", "000001100000", "000013310000",
    "000132231000", "001322223100", "001321123100", "001322223100",
    "000132231000", "000013310000", "000001100000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000", "000000000000", "000000000000", "000000000000",
    "000000000000",
)

boss_sprite = sprite(
    "000011110000", "000133331000", "001322223100", "013211112310",
    "132111111231", "321133331123", "321322223123", "321321123123",
    "321322223123", "321133331123", "132111111231", "013233332310",
    "001322223100", "000133331000", "003311113300", "033100001330",
    "331000000133", "310030030013", "100300003001", "003000000300",
    "030000000030",
)

action_sprites = b"".join(
    [
        sprite(
            "000000000000", "000033330000", "000311113000", "003122221300",
            "031233332130", "312333333213", "312330033213", "312303303213",
            "312330033213", "312333333213", "031233332130", "003122221300",
            "000311113000", "000033330000", "000003300000", "000030030000",
            "000300003000", "003000000300", "030000000030", "300000000003",
            "000000000000",
        ),
        sprite(
            "000001100000", "000133331000", "001322223100", "013211112310",
            "132103301231", "321030030123", "321300003123", "321300003123",
            "321030030123", "132103301231", "013211112310", "001322223100",
            "000133331000", "000001100000", "000000000000", "000000000000",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
        sprite(
            "000001100000", "000013310000", "000132231000", "001322223100",
            "013211112310", "132103301231", "321030030123", "132103301231",
            "013211112310", "001322223100", "000132231000", "000013310000",
            "000001100000", "000000000000", "000000000000", "000000000000",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
    ]
)

# Phase-12 object sprites: conference bug, speaker badge, slide USB and coffee
# 1-Up. They share the player's multicolor registers and retain individual ink.
object_sprites = b"".join(
    [
        sprite(
            "000000000000", "000001100000", "000112211000", "001123321100",
            "011233332110", "011232232110", "001233332100", "000122221000",
            "000011110000", "000301103000", "003010010300", "030010010030",
            "300010010003", "000010010000", "000100001000", "001000000100",
            "010000000010", "100000000001", "000000000000", "000000000000",
            "000000000000",
        ),
        sprite(
            "000000000000", "000003300000", "000030030000", "000300003000",
            "003000000300", "000311113000", "003122221300", "031200002130",
            "031203302130", "031200002130", "031222222130", "003111111300",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
        sprite(
            "000000000000", "000000000000", "000000000000", "000000003300",
            "000000033100", "000033331100", "000312221100", "003122221100",
            "031222221100", "031223321100", "031222221100", "003111111100",
            "000333333000", "000300003000", "000333333000", "000000000000",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
        sprite(
            "000000000000", "000003000000", "000030000000", "000003000000",
            "000000300000", "000033330000", "000311113000", "003122221300",
            "031222221130", "031222221133", "031222221133", "031222221130",
            "003111111300", "000333333000", "000030030000", "000300003000",
            "000000000000", "000000000000", "000000000000", "000000000000",
            "000000000000",
        ),
    ]
)

OUT.mkdir(parents=True, exist_ok=True)
(OUT / "charset.bin").write_bytes(b"".join(charset))
(OUT / "metatile-chars.bin").write_bytes(bytes(value for _, chars, _, _ in metatiles for value in chars))
(OUT / "metatile-colors.bin").write_bytes(bytes(value for _, _, colors, _ in metatiles for value in colors))
(OUT / "metatile-flags.bin").write_bytes(bytes(flags for _, _, _, flags in metatiles))
(OUT / "static-map.bin").write_bytes(bytes(value for row in world for value in row))
(OUT / "world-chars.bin").write_bytes(bytes(value for row in world_chars for value in row))
(OUT / "row-colors.bin").write_bytes(row_colors)
(OUT / "player-sprites.bin").write_bytes(player_sprites)
(OUT / "object-sprites.bin").write_bytes(object_sprites)
(OUT / "stance-sprites.bin").write_bytes(stance_sprites)
(OUT / "projectile-sprite.bin").write_bytes(projectile_sprite)
(OUT / "bomb-sprite.bin").write_bytes(bomb_sprite)
(OUT / "boss-sprite.bin").write_bytes(boss_sprite)
(OUT / "action-sprites.bin").write_bytes(action_sprites)
(OUT / "level-layout-patches.bin").write_bytes(
    bytes([len(level_layout_patches) // 7]) + level_layout_patches
)
(OUT / "asset-manifest.json").write_text(
    json.dumps(
        {
            "phase": 12,
            "charset_bytes": 2048,
            "hires_character_range": [0, 63],
            "multicolor_character_range": [64, 255],
            "metatile_size_characters": [2, 2],
            "metatile_count": len(metatiles),
            "metatile_names": [name for name, _, _, _ in metatiles],
            "affordance_revision": 1,
            "solid_metatiles": ["aisle_floor", "aisle_marker", "chair_row", "hall_wall", "tech_gantry"],
            "hazard_metatiles": ["cable_trap", "live_cable"],
            "decoration_metatiles": [name for name, _, _, tile_flags in metatiles if tile_flags == DECORATION],
            "map_size_metatiles": [width, height],
            "map_size_characters": [width * 2, height * 2],
            "viewport_size_characters": [40, 24],
            "exit_zone_pixels": [944, 1008],
            "level_count": 3,
            "level_layout_patch_count": len(level_layout_patches) // 7,
            "level_layout_patch_stride": 7,
            "level1_pickups": [[156, 139], [436, 91], [756, 91]],
            "level2_pickups": [[140, 91], [470, 91], [792, 91]],
            "level2_crawl_tunnel": [34, 36],
            "level2_upper_segments": [[6, 10, 7], [12, 17, 6], [20, 25, 6], [28, 32, 7], [35, 39, 7], [41, 46, 6], [48, 53, 7]],
            "level2_branch_entries": [6, 35],
            "level2_rejoins": [32, 53],
            "level1_traps": level1_traps,
            "level1_safe_start_end": 10,
            "level1_teaching_enemy_x": 340,
            "level1_recovery_spans": [[23, 24], [44, 45]],
            "level1_hidden_block": [10, 8],
            "level2_traps": level2_traps,
            "level3_pickups": [[280, 91], [520, 91], [760, 75]],
            "level3_step_platform": [40, 43],
            "level3_spike_traps": level3_spike_traps,
            "level3_electric_traps": level3_electric_traps,
            "level3_falling_lanes": [26, 41, 53],
            "level3_rolling_spawn": 900,
            "campaign_sections": ["foyer", "auditorium", "stage_rig"],
            "final_goal": "speaker_stage",
            "row_color_count": len(row_colors),
            "sprite_frame_count": 4,
            "sprite_bytes": len(player_sprites),
            "object_sprite_count": 4,
            "object_sprite_bytes": len(object_sprites),
            "stance_sprite_count": 2,
            "stance_sprite_bytes": len(stance_sprites),
            "projectile_sprite_bytes": len(projectile_sprite),
            "bomb_sprite_bytes": len(bomb_sprite),
            "boss_sprite_bytes": len(boss_sprite),
            "action_sprite_count": 3,
            "action_sprite_bytes": len(action_sprites),
            "legal_flags_mask": SOLID | HAZARD | DECORATION,
        },
        indent=2,
    )
    + "\n"
)
print(
    f"C64 assets: {len(metatiles)} metatiles, {width}x{height} map, "
    f"{len(level_layout_patches) // 7} three-layout patches"
)
