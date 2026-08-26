.export charset_data, metatile_chars, metatile_colors, metatile_flags, static_map
.export world_chars, row_colors
.export player_sprite_data
.export object_sprite_data
.export stance_sprite_data, projectile_sprite_data, bomb_sprite_data
.export boss_sprite_data
.export action_sprite_data
.export level_layout_patches
.export metatile_count
.export sid_tune_data

.segment "SIDTUNE"
sid_tune_data:
    .incbin "assets/c64/madness-part-1.bin"

.segment "RODATA"
charset_data:
    .incbin "assets/c64/charset.bin"
metatile_chars:
    .incbin "assets/c64/metatile-chars.bin"
metatile_colors:
    .incbin "assets/c64/metatile-colors.bin"
metatile_flags:
    .incbin "assets/c64/metatile-flags.bin"
metatile_count = * - metatile_flags
static_map:
    .incbin "assets/c64/static-map.bin"
world_chars:
    .incbin "assets/c64/world-chars.bin"
row_colors:
    .incbin "assets/c64/row-colors.bin"
player_sprite_data:
    .incbin "assets/c64/player-sprites.bin"
object_sprite_data:
    .incbin "assets/c64/object-sprites.bin"
stance_sprite_data:
    .incbin "assets/c64/stance-sprites.bin"
projectile_sprite_data:
    .incbin "assets/c64/projectile-sprite.bin"
bomb_sprite_data:
    .incbin "assets/c64/bomb-sprite.bin"
boss_sprite_data:
    .incbin "assets/c64/boss-sprite.bin"
action_sprite_data:
    .incbin "assets/c64/action-sprites.bin"
level_layout_patches:
    .incbin "assets/c64/level-layout-patches.bin"
