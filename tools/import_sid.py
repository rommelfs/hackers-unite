#!/usr/bin/env python3
"""Archive and extract the fixed-load C64 payload from a PSID v2 file."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def c_string(raw: bytes) -> str:
    return raw.split(b"\0", 1)[0].decode("latin-1")


if len(sys.argv) != 5:
    raise SystemExit("usage: import_sid.py SOURCE ARCHIVE PAYLOAD METADATA")

source, archive, payload_path, metadata_path = map(Path, sys.argv[1:])
data = source.read_bytes()
if len(data) < 0x7E or data[:4] != b"PSID":
    raise SystemExit("expected a PSID file with an embedded load address")

version = int.from_bytes(data[4:6], "big")
data_offset = int.from_bytes(data[6:8], "big")
header_load = int.from_bytes(data[8:10], "big")
init_address = int.from_bytes(data[10:12], "big")
play_address = int.from_bytes(data[12:14], "big")
songs = int.from_bytes(data[14:16], "big")
start_song = int.from_bytes(data[16:18], "big")
speed = int.from_bytes(data[18:22], "big")
if version != 2 or data_offset != 0x7C or header_load != 0:
    raise SystemExit("unsupported PSID layout")

load_address = int.from_bytes(data[data_offset : data_offset + 2], "little")
payload = data[data_offset + 2 :]
if (load_address, init_address, play_address, songs, start_song, speed) != (
    0x1800,
    0x1800,
    0x1806,
    1,
    1,
    0,
):
    raise SystemExit("unexpected Madness part 1 addresses or playback mode")

archive.parent.mkdir(parents=True, exist_ok=True)
payload_path.parent.mkdir(parents=True, exist_ok=True)
metadata_path.parent.mkdir(parents=True, exist_ok=True)
archive.write_bytes(data)
payload_path.write_bytes(payload)
metadata_path.write_text(
    json.dumps(
        {
            "format": "PSID v2",
            "title": c_string(data[0x16:0x36]),
            "author": c_string(data[0x36:0x56]),
            "copyright": c_string(data[0x56:0x76]),
            "load_address": load_address,
            "end_address": load_address + len(payload) - 1,
            "init_address": init_address,
            "play_address": play_address,
            "songs": songs,
            "start_song": start_song,
            "speed": "VBI/50 Hz",
            "payload_bytes": len(payload),
            "permission": "Use authorized by the project owner, who reports permission from Jesper Jensen.",
        },
        indent=2,
    )
    + "\n"
)
print(
    f"SID import: {len(payload)} bytes at ${load_address:04X}-${load_address + len(payload) - 1:04X}, "
    f"init=${init_address:04X}, play=${play_address:04X}"
)
