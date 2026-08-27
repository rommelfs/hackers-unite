.exportzp frame_pending, screen_ptr, color_ptr, source_ptr
.export frame_counter_lo, frame_counter_hi, dropped_frames
.export joy_raw, joy_held, joy_previous, joy_pressed
.export tile_map_index, tile_row, tile_col
.export camera_pixel_lo, camera_pixel_hi, camera_char
.export visible_buffer, rendered_camera_char, scroll_d016, visible_d018
.export screen_a_char, screen_b_char
.export scroll_direction, coarse_scroll_count, irq_phase
.export player_x_lo, player_x_hi, player_y_lo, player_y_hi
.export player_vx, player_vy, player_grounded, player_frame, player_anim_timer
.export player_airborne_entry
.export player_stance, player_facing, crouch_frames, crawl_frames
.export player_pixel_lo, player_pixel_hi, test_x_lo, test_x_hi, test_y_lo, test_y_hi
.export collision_landings, player_respawns
.export running_jumps
.export high_landings, main_busy
.export sprite_xy_shadow, sprite_enable_shadow, sprite_msb_shadow
.export object_x_lo, object_x_hi, object_y, object_active
.export object_persistence, object_ever_active, enemy_direction
.export object_temp_lo, object_temp_hi, object_index, object_enable_mask, object_msb_mask
.export score_lo, score_hi, lives, game_state, damage_cooldown
.export objects_activated, objects_collected, enemy_defeats, mutable_block_state
.export mutable_blocks_hit, player_deaths, game_over_count
.export test_fail_code
.export level_number, level_clear_timer, exit_entries, level_transitions
.export sfx_timer, sfx_events, sfx_priority, sfx_suppressed
.export sfx_freq
.export music_timer, music_step, music_ticks
.export enemies_present
.export projectile_active, projectile_x_lo, projectile_x_hi, projectile_y
.export projectile_direction, projectile_lifetime, projectile_cooldown
.export projectiles_fired, projectile_hits
.export projectile_mode, projectile_vy, bombs_thrown
.export boss_hp, boss_invuln, boss_hits, boss_defeats
.export trap_hits, secret_found
.export difficulty_rank_lo, difficulty_rank_hi
.export boss_shot_active, boss_shot_x_lo, boss_shot_x_hi, boss_shot_y
.export boss_shot_direction, boss_shot_cooldown, boss_shot_lifetime
.export boss_shots_fired, boss_shot_hits
.export falling_drops, rolling_cycles, action_hits
.export continue_seconds, continue_tick, continues_used, continue_timeouts
.export falling_warning_timer
.export respawn_pending, respawn_render_row, death_timer
.export power_weapon, rapid_timer, strong_timer, speed_timer, power_flash
.export powerups_collected, extra_lives_collected, powerups_expired
.export finale_timer, finale_step, applause_events

.segment "ZEROPAGE"
frame_pending:  .res 1
screen_ptr:     .res 2
color_ptr:      .res 2
source_ptr:     .res 2

.segment "BSS"
frame_counter_lo: .res 1
frame_counter_hi: .res 1
dropped_frames:   .res 1
joy_raw:           .res 1
joy_held:          .res 1
joy_previous:      .res 1
joy_pressed:       .res 1
tile_map_index:    .res 1
tile_row:          .res 1
tile_col:          .res 1
camera_pixel_lo:   .res 1
camera_pixel_hi:   .res 1
camera_char:       .res 1
visible_buffer:    .res 1
rendered_camera_char: .res 1
scroll_d016:       .res 1
visible_d018:      .res 1
screen_a_char:     .res 1
screen_b_char:     .res 1
scroll_direction:  .res 1
coarse_scroll_count: .res 1
irq_phase:         .res 1
player_x_lo:       .res 1
player_x_hi:       .res 1
player_y_lo:       .res 1
player_y_hi:       .res 1
player_vx:         .res 1
player_vy:         .res 1
player_grounded:   .res 1
player_airborne_entry: .res 1
player_frame:      .res 1
player_anim_timer: .res 1
player_stance:    .res 1
player_facing:    .res 1
crouch_frames:    .res 1
crawl_frames:     .res 1
player_pixel_lo:   .res 1
player_pixel_hi:   .res 1
test_x_lo:         .res 1
test_x_hi:         .res 1
test_y_lo:         .res 1
test_y_hi:         .res 1
collision_landings: .res 1
player_respawns:   .res 1
running_jumps:     .res 1
high_landings:     .res 1
main_busy:         .res 1
sprite_xy_shadow:  .res 16
sprite_enable_shadow: .res 1
sprite_msb_shadow: .res 1
object_x_lo:       .res 7
object_x_hi:       .res 7
object_y:          .res 7
object_active:     .res 7
object_persistence: .res 1
object_ever_active: .res 1
enemy_direction:  .res 7
object_temp_lo:    .res 1
object_temp_hi:    .res 1
object_index:      .res 1
object_enable_mask: .res 1
object_msb_mask:   .res 1
score_lo:          .res 1
score_hi:          .res 1
lives:             .res 1
game_state:        .res 1
damage_cooldown:   .res 1
objects_activated: .res 1
objects_collected: .res 1
enemy_defeats:     .res 1
mutable_block_state: .res 1
mutable_blocks_hit: .res 1
player_deaths:     .res 1
game_over_count:   .res 1
test_fail_code:    .res 1
level_number:      .res 1
level_clear_timer: .res 1
exit_entries:      .res 1
level_transitions: .res 1
sfx_timer:         .res 1
sfx_events:        .res 1
sfx_priority:      .res 1
sfx_suppressed:    .res 1
sfx_freq:          .res 1
music_timer:       .res 1
music_step:        .res 1
music_ticks:       .res 1
enemies_present:   .res 1
projectile_active: .res 1
projectile_x_lo:   .res 1
projectile_x_hi:   .res 1
projectile_y:      .res 1
projectile_direction: .res 1
projectile_lifetime: .res 1
projectile_cooldown: .res 1
projectiles_fired: .res 1
projectile_hits:   .res 1
projectile_mode:   .res 1
projectile_vy:     .res 1
bombs_thrown:      .res 1
boss_hp:           .res 1
boss_invuln:       .res 1
boss_hits:         .res 1
boss_defeats:      .res 1
trap_hits:         .res 1
secret_found:      .res 1
difficulty_rank_lo: .res 1
difficulty_rank_hi: .res 1
boss_shot_active:   .res 1
boss_shot_x_lo:     .res 1
boss_shot_x_hi:     .res 1
boss_shot_y:        .res 1
boss_shot_direction: .res 1
boss_shot_cooldown: .res 1
boss_shot_lifetime: .res 1
boss_shots_fired:   .res 1
boss_shot_hits:     .res 1
falling_drops:      .res 1
rolling_cycles:     .res 1
action_hits:        .res 1
continue_seconds:   .res 1
continue_tick:      .res 1
continues_used:     .res 1
continue_timeouts:  .res 1
falling_warning_timer: .res 1
respawn_pending:       .res 1
respawn_render_row:    .res 1
death_timer:           .res 1
power_weapon:          .res 1
rapid_timer:           .res 1
strong_timer:          .res 1
speed_timer:           .res 1
power_flash:           .res 1
powerups_collected:    .res 1
extra_lives_collected: .res 1
powerups_expired:      .res 1
finale_timer:          .res 1
finale_step:           .res 1
applause_events:       .res 1
