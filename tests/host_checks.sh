#!/bin/sh
set -eu

prg="release/hackers-unite.prg"
map="release/hackers-unite.map"

test -s "$prg"
test -s "$map"
load_hex=$(od -An -tx1 -N2 "$prg" | tr -d ' \n')
test "$load_hex" = "0108"
rg -q 'raster_irq' release/hackers-unite.lbl
rg -q 'vic_init' release/hackers-unite.lbl
rg -q 'charset_data' release/hackers-unite.lbl
rg -q 'tilemap_render' release/hackers-unite.lbl
rg -q 'scroll_update' release/hackers-unite.lbl
rg -q 'player_update' release/hackers-unite.lbl
rg -q 'player_sprite_update' release/hackers-unite.lbl
rg -q 'objects_update' release/hackers-unite.lbl
rg -q 'player_damage' release/hackers-unite.lbl
rg -q 'level_exit_update' release/hackers-unite.lbl
rg -q 'level_transitions' release/hackers-unite.lbl
rg -q 'sound_update' release/hackers-unite.lbl
rg -q 'sfx_level_clear' release/hackers-unite.lbl
rg -q 'level_layout_apply' release/hackers-unite.lbl
rg -q 'level_layout_patches' release/hackers-unite.lbl
rg -q 'music_ticks' release/hackers-unite.lbl
rg -q 'sfx_priority' release/hackers-unite.lbl
rg -q 'enemies_present' release/hackers-unite.lbl
rg -q 'mutable_block_hit_test' release/hackers-unite.lbl
rg -q 'running_jumps' release/hackers-unite.lbl
rg -q 'high_landings' release/hackers-unite.lbl
rg -q 'main_busy' release/hackers-unite.lbl
rg -q 'sprite_xy_shadow' release/hackers-unite.lbl
rg -q 'projectile_update' release/hackers-unite.lbl
rg -q 'projectile_hits' release/hackers-unite.lbl
rg -q 'bombs_thrown' release/hackers-unite.lbl
rg -q 'boss_shots_fired' release/hackers-unite.lbl
rg -q 'falling_drops' release/hackers-unite.lbl
rg -q 'continues_used' release/hackers-unite.lbl
rg -q 'falling_warning_timer' release/hackers-unite.lbl
rg -q 'player_stance' release/hackers-unite.lbl
rg -q 'al 001800 .sid_tune_data' release/hackers-unite.lbl
rg -q '^CODE[[:space:]]+006000' "$map"
rg -q '^RODATA[[:space:]]+008000' "$map"
rg -q '^BSS[[:space:]]+002600' "$map"
test "$(wc -c < assets/c64/object-sprites.bin | tr -d ' ')" -eq 256
test "$(wc -c < assets/c64/boss-sprite.bin | tr -d ' ')" -eq 64
test "$(wc -c < assets/c64/action-sprites.bin | tr -d ' ')" -eq 192
patch_count=$(od -An -tu1 -N1 assets/c64/level-layout-patches.bin | tr -d ' ')
patch_bytes=$(wc -c < assets/c64/level-layout-patches.bin | tr -d ' ')
test "$patch_bytes" -eq "$((1 + patch_count * 7))"
test "$(wc -c < assets/c64/stance-sprites.bin | tr -d ' ')" -eq 128
test "$(wc -c < assets/c64/projectile-sprite.bin | tr -d ' ')" -eq 64
test "$(wc -c < assets/c64/bomb-sprite.bin | tr -d ' ')" -eq 64
test "$(wc -c < assets/c64/madness-part-1.bin | tr -d ' ')" -eq 3283
size=$(wc -c < "$prg" | tr -d ' ')
test "$size" -lt 40960
echo "host checks: OK (${size} bytes, load address \$0801)"
