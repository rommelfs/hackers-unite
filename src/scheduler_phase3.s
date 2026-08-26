.include "constants.inc"

.export frame_loop
.importzp frame_pending
.import input_update, player_update, scroll_update, player_sprite_update, ui_update
.import game_update, level_exit_update, objects_update, game_state
.import frame_counter_lo, frame_counter_hi, dropped_frames, coarse_scroll_count
.import collision_landings
.import objects_activated, objects_collected, enemy_defeats, mutable_blocks_hit
.import object_persistence, mutable_block_state
.import test_fail_code, player_deaths, player_x_hi
.import object_x_lo, object_x_hi, object_y, object_active, object_index, enemy_direction
.import player_x_lo, player_y_lo, player_y_hi, player_vy
.import mutable_block_hit_test, test_x_hi, test_y_hi
.import player_damage, lives, damage_cooldown, game_over_count
.import camera_pixel_lo, camera_pixel_hi, running_jumps, objects_test_enemy_collision
.import high_landings, main_busy
.import sound_update
.import level_clear_timer, exit_entries, level_transitions, sfx_events, level_number
.import music_ticks, sfx_timer, sfx_priority, sfx_suppressed
.import sfx_damage, sfx_jump, static_map
.import joy_held, joy_pressed
.import enemies_present
.import projectile_update
.import boss_attack_update
.import player_airborne_entry
.import player_stance, crouch_frames, crawl_frames, player_grounded, player_vx
.import player_control_test, player_jump_test
.import projectile_active, projectile_x_lo, projectile_x_hi, projectile_y
.import projectile_direction, projectile_lifetime, projectile_cooldown
.import projectiles_fired, projectile_hits
.import projectile_mode, projectile_vy, bombs_thrown
.import objects_projectile_hit
.import boss_hp, boss_invuln, boss_hits, boss_defeats
.import trap_hits, secret_found, player_hazard_test
.import difficulty_rank_lo, difficulty_rank_hi
.import boss_attack_test_spawn
.import boss_shot_active, boss_shots_fired, boss_shot_hits
.import falling_drops, rolling_cycles, action_hits, falling_warning_timer
.import continue_seconds, continue_tick, continues_used, continue_timeouts
.import respawn_pending, death_timer
.import sprite_enable_shadow
.import objects_test_boss_update

.segment "CODE"
frame_loop:
@wait:
    sei
    lda frame_pending
    bne :+
    jmp @not_ready
:
    dec frame_pending
    cli
    lda #1
    sta main_busy

.ifdef DEBUG_BUILD
    lda #COLOR_PURPLE
    sta VIC_BORDER
.endif
    jsr input_update
    jsr game_update
    jsr sound_update
.ifdef DEBUG_BUILD
    lda #COLOR_BLUE
    sta VIC_BORDER
.endif
    lda game_state
    bne :+
    jsr player_update
:
.ifdef DEBUG_BUILD
    lda #COLOR_GREEN
    sta VIC_BORDER
.endif
    lda game_state
    cmp #GAME_LOAD_A
    bcs @skip_world
    jsr scroll_update
.ifdef DEBUG_BUILD
    lda #COLOR_RED
    sta VIC_BORDER
.endif
    jsr objects_update
    jsr boss_attack_update
    jsr projectile_update
    jsr level_exit_update
@skip_world:
.ifdef DEBUG_BUILD
    lda #COLOR_YELLOW
    sta VIC_BORDER
.endif
    jsr player_sprite_update
.ifdef DEBUG_BUILD
    lda #COLOR_DARK_GREY
    sta VIC_BORDER
.endif
    jsr ui_update
.ifdef DEBUG_BUILD
    lda #COLOR_BLACK
    sta VIC_BORDER
.endif
    lda #0
    sta main_busy

.ifdef AUTOTEST
    jmp @autotest_run
.segment "TESTCODE"
@autotest_run:
.ifdef SOAK_TEST
    lda frame_counter_hi
    cmp #30                 ; 7,680 PAL frames = 153.6 seconds
    bcs :+
    jmp @wait
:
.else
    lda frame_counter_lo
    cmp #240
    bcs :+
    jmp @wait
:
.endif
    lda #$40
    sta test_fail_code
    lda static_map+(2*64)+2
    cmp #METATILE_CHAIR_BACK_A
    beq :+
    jmp @fail
:
    lda static_map+(6*64)+56
    cmp #METATILE_STAGE_FRAME
    beq :+
    jmp @fail
:
    lda static_map+(6*64)+59
    cmp #METATILE_STAGE_SCREEN
    beq :+
    jmp @fail
:
    lda #$41
    sta test_fail_code
    lda dropped_frames
    beq :+
    jmp @fail
:
    lda #$42
    sta test_fail_code
    lda coarse_scroll_count
.ifndef SOAK_TEST
    cmp #8
    bcs :+
    jmp @fail
:
.else
    bne :+
    jmp @fail
:
.endif
    lda #$43
    sta test_fail_code
    lda collision_landings
    bne :+
    jmp @fail
:
    lda #$50
    sta test_fail_code
    lda running_jumps
    bne :+
    jmp @fail
:
    lda #$4F
    sta test_fail_code
    lda high_landings
    bne :+
    jmp @fail
:
    lda enemy_defeats
    bne :+
    jsr autotest_enemy_stomp
:
    lda mutable_block_state
    bne :+
    lda #10
    sta test_x_hi
    lda #8
    sta test_y_hi
    jsr mutable_block_hit_test
:
    lda trap_hits
    bne :+
    lda #0
    sta damage_cooldown
    sta player_x_lo
    lda #$12                ; world X 288, Level-1 spike column 18
    sta player_x_hi
    lda #$B0
    sta player_y_lo
    lda #$08
    sta player_y_hi
    jsr player_hazard_test
:
    lda #$51
    sta test_fail_code
    lda objects_activated
    cmp #4
    bcs :+
    jmp @fail
:
    lda #$52
    sta test_fail_code
    lda objects_collected
    cmp #3
    bcs :+
    jmp @fail
:
    lda #$53
    sta test_fail_code
    lda enemy_defeats
    bne @enemy_ok
    lda player_deaths
    beq @enemy_not_reached
    lda #$57
    sta test_fail_code
    jmp @fail
@enemy_not_reached:
    lda player_x_hi
    sta test_fail_code
    jmp @fail
@enemy_ok:
    lda #$54
    sta test_fail_code
    lda mutable_blocks_hit
    bne :+
    jmp @fail
:
    lda secret_found
    bne :+
    jmp @fail
:
    lda trap_hits
    bne :+
    jmp @fail
:
    lda #$55
    sta test_fail_code
    lda object_persistence
    and #$0F
    cmp #$0F
    beq :+
    jmp @fail
:
    lda #$56
    sta test_fail_code
    lda mutable_block_state
    bne :+
    jmp @fail
:
    lda VIC_SPR_ENABLE
    and #$01
    bne :+
    jmp @fail
:
    lda VIC_SPR_X_MSB
    and #$01
    beq :+
    jmp @fail
:
    lda VIC_SPR0_X
    cmp #24
    bcs :+
    jmp @fail
:
    cmp #241
    bcc :+
    jmp @fail
:
.ifndef SOAK_TEST
    jsr autotest_phase9_controls
    lda #$80
    sta test_fail_code
    lda crouch_frames
    bne :+
    jmp @fail
:
    lda crawl_frames
    bne :+
    jmp @fail
:
    lda player_vx
    cmp #8
    beq :+
    jmp @fail
:
    lda projectile_hits
    bne :+
    jmp @fail
:
.endif
.ifndef SOAK_TEST
    lda #$70
    sta test_fail_code
    lda enemies_present
    cmp #2
    beq :+
    jmp @fail
:
    jsr autotest_level_exit
    lda #$71
    sta test_fail_code
    lda game_state
    cmp #GAME_LEVEL_CLEAR
    beq :+
    jmp @fail
:
    lda #$72
    sta test_fail_code
    lda exit_entries
    cmp #1
    beq :+
    jmp @fail
:
    lda #$73
    sta test_fail_code
    lda level_clear_timer
    cmp #100
    beq :+
    jmp @fail
:
    lda #$74
    sta test_fail_code
    lda sfx_events
    bne :+
    jmp @fail
:
    lda #JOY_FIRE
    sta joy_pressed
    lda #1
    sta main_busy
    jsr game_update
    lda #0
    sta main_busy
    jsr autotest_finish_layout
    lda #$75
    sta test_fail_code
    lda game_state
    cmp #GAME_LOAD_A
    beq :+
    jmp @fail
:
    lda #$76
    sta test_fail_code
    lda level_transitions
    cmp #1
    beq :+
    jmp @fail
:
    lda #$77
    sta test_fail_code
    lda level_number
    cmp #2
    beq :+
    jmp @fail
:
    lda difficulty_rank_hi
    beq :+
    jmp @fail
:
    lda difficulty_rank_lo
    cmp #1
    beq :+
    jmp @fail
:
    lda static_map+(6*64)+2
    cmp #METATILE_PLATFORM
    beq :+
    jmp @fail
:
    lda static_map+(7*64)+8
    cmp #METATILE_PLATFORM
    beq :+
    jmp @fail
:
    lda static_map+(7*64)+29
    cmp #METATILE_PLATFORM
    beq :+
    jmp @fail
:
    lda static_map+(7*64)+47
    cmp #METATILE_PLATFORM
    beq :+
    jmp @fail
:
    lda #$78
    sta test_fail_code
    lda object_x_lo+1
    cmp #<140
    beq :+
    jmp @fail
:
    lda object_x_lo+2
    cmp #<470
    beq :+
    jmp @fail
:
    lda object_x_hi+2
    cmp #>470
    beq :+
    jmp @fail
:
    lda object_x_lo+3
    cmp #<760
    beq :+
    jmp @fail
:
    lda object_x_hi+3
    cmp #>760
    beq :+
    jmp @fail
:
    lda object_y+1
    cmp #91
    beq :+
    jmp @fail
:
    lda object_y+2
    cmp #91
    beq :+
    jmp @fail
:
    lda object_y+3
    cmp #91
    beq :+
    jmp @fail
:
    lda enemies_present
    cmp #4
    beq :+
    jmp @fail
:
    lda boss_hp
    cmp #8
    beq :+
    jmp @fail
:
    ; Items alone cannot unlock the Level-2 exit while the boss lives.
    lda #$0E
    sta object_persistence
    lda #GAME_PLAY
    sta game_state
    jsr autotest_level_exit
    lda game_state
    beq :+
    jmp @fail
:
    ; Once all items are collected, the boss owns the freed 1-Up sprite slot
    ; and fires a visible horizontal energy orb.
    lda #1
    sta object_active+6
    lda #5
    sta lives
    lda #0
    sta damage_cooldown
    lda #$C0                ; player world X = 860
    sta player_x_lo
    lda #$35
    sta player_x_hi
    lda #$40                ; player world Y = 132
    sta player_y_lo
    lda #$08
    sta player_y_hi
    jsr boss_attack_test_spawn
    jsr boss_attack_update
    lda boss_shots_fired
    cmp #1
    beq :+
    jmp @fail
:
    lda boss_shot_hits
    cmp #1
    beq :+
    jmp @fail
:
    lda boss_shot_active
    beq :+
    jmp @fail
:
    lda object_x_lo+4
    cmp #<390
    beq :+
    jmp @fail
:
    lda object_x_lo+5
    cmp #<620
    beq :+
    jmp @fail
:
    lda object_x_hi+5
    cmp #>620
    beq :+
    jmp @fail
:
    lda object_x_lo+6
    cmp #<860
    beq :+
    jmp @fail
:
    lda object_x_hi+6
    cmp #>860
    beq :+
    jmp @fail
:
    ; Blind floor-height fire must miss the boss. Only the central weak core
    ; accepts a hit, which the two bomb arcs can cross from above or below.
    lda object_x_lo+6
    clc
    adc #24
    sta projectile_x_lo
    lda object_x_hi+6
    adc #0
    sta projectile_x_hi
    lda #147
    sta projectile_y
    jsr objects_projectile_hit
    beq :+
    jmp @fail
:
    lda boss_hp
    cmp #8
    beq :+
    jmp @fail
:
    lda #134
    sta projectile_y
    jsr objects_projectile_hit
    cmp #1
    beq :+
    jmp @fail
:
    lda boss_hp
    cmp #7
    beq :+
    jmp @fail
:
    lda #8
    sta boss_hp
    lda #0
    sta boss_invuln
    sta boss_hits
    ; Directly exercise autonomous arena patrol: the boss keeps its current
    ; direction and advances toward the authored boundary, independent of the
    ; player coordinate.
    lda #1
    sta enemy_direction+6
    lda #0
    sta frame_counter_lo
    ldx #6
    jsr objects_test_boss_update
    lda enemy_direction+6
    cmp #1
    beq :+
    jmp @fail
:
    lda object_x_lo+6
    cmp #<861
    beq :+
    jmp @fail
:
    lda #<860
    sta object_x_lo+6
    ; Standing on the platform above leaves a clear six-pixel body gap and
    ; must not deal free stomp damage to the boss.
    ldx #6
    jsr autotest_boss_platform_gap
    lda boss_hp
    cmp #8
    beq :+
    jmp @fail
:
    ldx #0
    jsr autotest_enemy_exact_stomp
    ldx #4
    jsr autotest_enemy_exact_stomp
    ldx #5
    jsr autotest_enemy_exact_stomp
    lda #0
    sta boss_invuln
    ldx #6
    jsr autotest_enemy_exact_stomp
    lda boss_hp
    cmp #7
    beq :+
    jmp @fail
:
    ; A contact during the flash bounces but must not bypass invulnerability.
    ldx #6
    jsr autotest_enemy_exact_stomp
    lda boss_hp
    cmp #7
    beq :+
    jmp @fail
:
@boss_stomp_loop:
    lda boss_hp
    beq @boss_stomp_done
    lda #0
    sta boss_invuln
    ldx #6
    jsr autotest_enemy_exact_stomp
    jmp @boss_stomp_loop
@boss_stomp_done:
    lda #$7B
    sta test_fail_code
    lda object_persistence
    and #$71
    cmp #$71
    beq :+
    jmp @fail
:
    lda enemy_defeats
    cmp #4
    beq :+
    jmp @fail
:
    lda boss_hits
    cmp #8
    beq :+
    jmp @fail
:
    lda boss_defeats
    cmp #1
    beq :+
    jmp @fail
:
    lda #$79
    sta test_fail_code
    lda music_ticks
    bne :+
    jmp @fail
:
    lda #0
    sta sfx_timer
    sta sfx_priority
    sta sfx_suppressed
    jsr sfx_damage
    jsr sfx_jump
    lda sfx_priority
    cmp #3
    beq :+
    jmp @fail
:
    lda sfx_suppressed
    bne :+
    jmp @fail
:
    lda #$4E
    sta object_persistence
    lda #GAME_PLAY
    sta game_state
    jsr autotest_level_exit
    lda #JOY_FIRE
    sta joy_pressed
    lda #1
    sta main_busy
    jsr game_update
    lda #0
    sta main_busy
    jsr autotest_finish_layout
    lda #$7A
    sta test_fail_code
    lda game_state
    cmp #GAME_LOAD_A
    beq :+
    jmp @fail
:
    lda level_transitions
    cmp #2
    beq :+
    jmp @fail
:
    lda difficulty_rank_lo
    cmp #2
    beq :+
    jmp @fail
:
    lda level_number
    cmp #3
    beq :+
    jmp @fail
:
    lda #$81
    sta test_fail_code
    lda static_map+(9*64)+8
    cmp #METATILE_SPIKE
    beq :+
    jmp @fail
:
    lda static_map+(9*64)+9
    cmp #METATILE_SPIKE
    beq :+
    jmp @fail
:
    lda static_map+(9*64)+13
    beq :+                  ; formerly an isolated, ambiguous electric trap
    jmp @fail
:
    lda static_map+(9*64)+22
    cmp #METATILE_ELECTRIC
    beq :+
    jmp @fail
:
    lda static_map+(9*64)+23
    cmp #METATILE_ELECTRIC
    beq :+
    jmp @fail
:
    lda static_map+(1*64)+20
    cmp #METATILE_FACTORY
    beq :+
    jmp @fail
:
    lda object_x_lo+1
    cmp #<280
    beq :+
    jmp @fail
:
    lda object_x_hi+2
    cmp #>520
    beq :+
    jmp @fail
:
    lda object_y+3
    cmp #75
    beq :+
    jmp @fail
:
    lda #$82
    sta test_fail_code
    lda #GAME_PLAY
    sta game_state
    ; Force both new action objects through an authoritative update/collision.
    lda #0
    sta camera_pixel_lo
    sta camera_pixel_hi
    lda #65
    sta object_x_lo+6
    lda #0
    sta object_x_hi+6
    jsr objects_update
    lda rolling_cycles
    bne :+
    jmp @fail
:
    lda #$85
    sta test_fail_code
    lda #$58
    sta camera_pixel_lo
    lda #$02
    sta camera_pixel_hi
    lda #2
    sta falling_warning_timer
    lda #16
    sta object_y+5
    jsr objects_update
    lda object_y+5
    beq :+
    jmp @fail
:
    lda sprite_enable_shadow
    and #$40
    beq :+
    jmp @fail               ; warning phase must have no blocking sprite/box
:
    lda #0
    sta falling_warning_timer
    lda #138
    sta object_y+5
    jsr objects_update
    lda falling_drops
    bne :+
    jmp @fail
:
    lda #$86
    sta test_fail_code
    lda #5
    sta lives
    lda #0
    sta damage_cooldown
    lda object_x_lo+6
    asl
    asl
    asl
    asl
    sta player_x_lo
    lda object_x_hi+6
    asl
    asl
    asl
    asl
    sta player_x_hi
    lda object_x_lo+6
    lsr
    lsr
    lsr
    lsr
    ora player_x_hi
    sta player_x_hi
    lda object_y+6
    asl
    asl
    asl
    asl
    sta player_y_lo
    lda object_y+6
    lsr
    lsr
    lsr
    lsr
    sta player_y_hi
    ldx #6
    jsr objects_test_enemy_collision
    lda action_hits
    bne :+
    jmp @fail
:
    lda #$83
    sta test_fail_code
    lda #$0E
    sta object_persistence
    lda #GAME_PLAY
    sta game_state
    jsr autotest_level_exit
    lda #JOY_FIRE
    sta joy_pressed
    lda #1
    sta main_busy
    jsr game_update
    lda #0
    sta main_busy
    jsr autotest_finish_layout
    lda #$87
    sta test_fail_code
    lda game_state
    cmp #GAME_COMPLETE
    beq :+
    jmp @fail
:
    lda #$88
    sta test_fail_code
    lda difficulty_rank_lo
    cmp #3
    beq :+
    jmp @fail
:
    lda #$89
    sta test_fail_code
    lda level_transitions
    cmp #3
    beq :+
    jmp @fail
:
    ; SYSTEM OK is a breather; Fire begins a harder Level-1 cycle without
    ; resetting score, lives, or the 16-bit danger rank.
    lda #JOY_FIRE
    sta joy_pressed
    lda #1
    sta main_busy
    jsr game_update
    lda #0
    sta main_busy
    jsr autotest_finish_layout
    lda #$8A
    sta test_fail_code
    lda game_state
    cmp #GAME_LOAD_A
    beq :+
    jmp @fail
:
    lda level_number
    cmp #1
    beq :+
    jmp @fail
:
    lda difficulty_rank_lo
    cmp #3
    beq :+
    jmp @fail
:
    lda enemies_present
    cmp #3
    beq :+
    jmp @fail
:
    jsr autotest_damage_cycle
    lda #$61
    sta test_fail_code
    lda lives
    beq :+
    jmp @fail
:
    lda #$62
    sta test_fail_code
    lda game_state
    cmp #GAME_CONTINUE
    beq :+
    jmp @fail
:
    lda continue_seconds
    cmp #9
    beq :+
    jmp @fail
:
    lda #$63
    sta test_fail_code
    lda player_deaths
    cmp #3
    beq :+
    jmp @fail
:
    lda #$64
    sta test_fail_code
    lda game_over_count
    cmp #1
    beq :+
    jmp @fail
:
    lda #$8B
    sta test_fail_code
    lda #JOY_FIRE
    sta joy_pressed
    jsr game_update
    jsr autotest_finish_layout
    lda continues_used
    cmp #1
    beq :+
    jmp @fail
:
    lda lives
    cmp #3
    beq :+
    jmp @fail
:
    lda level_number
    cmp #1
    beq :+
    jmp @fail
:
    lda difficulty_rank_lo
    cmp #3
    beq :+
    jmp @fail
:
    ; Let a one-tick continue expire: this must enter the separate new-game
    ; GAME OVER state instead of silently restarting the campaign.
    lda #GAME_CONTINUE
    sta game_state
    lda #1
    sta continue_seconds
    sta continue_tick
    lda #0
    sta joy_pressed
    jsr game_update
    lda game_state
    cmp #GAME_OVER
    beq :+
    jmp @fail
:
    lda continue_timeouts
    cmp #1
    beq :+
    jmp @fail
:
.endif
    lda #0
    sta $D7FF
@halt:
    jmp @halt
@fail:
    lda test_fail_code
    bne :+
    lda #$FF
:
    pha
    and #$0F
    sta VIC_BORDER
    pla
    lsr
    lsr
    lsr
    lsr
    sta VIC_BG0
    lda test_fail_code
    sta $D7FF
    jmp @halt
.endif
.segment "CODE"
    jmp @wait

@not_ready:
    cli
    jmp @wait

.ifdef AUTOTEST
.segment "TESTCODE"
autotest_phase9_controls:
    lda #1
    sta player_grounded
    lda #0
    sta player_vx
    sta joy_pressed
    sta crouch_frames
    sta crawl_frames
    lda #(JOY_DOWN | JOY_RIGHT)
    sta joy_held
    ldx #8
:
    jsr player_control_test
    dex
    bne :-
    lda #0
    sta player_stance
    lda #JOY_UP
    sta joy_pressed
    jsr player_jump_test

    lda #0
    sta joy_held
    sta joy_pressed
    sta projectile_active
    sta projectile_cooldown
    lda #JOY_FIRE
    sta joy_pressed
    jsr projectile_update
    lda #0
    sta projectile_active
    sta projectile_cooldown
    lda #(JOY_FIRE | JOY_UP)
    sta joy_held
    lda #JOY_FIRE
    sta joy_pressed
    jsr projectile_update
    lda projectile_mode
    cmp #1
    beq :+
    jmp @control_fail
:
    lda projectile_vy
    cmp #$FC
    beq :+
    jmp @control_fail
:
    lda #0
    sta projectile_active
    sta projectile_cooldown
    lda #(JOY_FIRE | JOY_DOWN)
    sta joy_held
    lda #JOY_FIRE
    sta joy_pressed
    jsr projectile_update
    lda projectile_mode
    cmp #2
    beq :+
    jmp @control_fail
:
    lda projectile_vy
    cmp #2
    beq :+
    jmp @control_fail
:
    lda bombs_thrown
    cmp #2
    beq :+
@control_fail:
    lda #0
    sta projectile_hits
    rts
:
    lda #0
    sta joy_held
    sta joy_pressed
    sta projectile_active
    sta projectile_mode
    sta projectile_vy
    lda object_persistence
    and #$EF
    sta object_persistence
    lda #1
    sta object_active+4
    sta projectile_active
    sta projectile_direction
    lda #10
    sta projectile_lifetime
    lda object_x_lo+4
    clc
    adc #16                ; update advances to +20, inside the 24px enemy box
    sta projectile_x_lo
    lda object_x_hi+4
    adc #0
    sta projectile_x_hi
    lda object_y+4
    sta projectile_y
    jsr projectile_update
    lda object_persistence
    and #$EF
    sta object_persistence
    dec enemy_defeats
    rts

autotest_enemy_stomp:
    lda #0
    sta game_state
    lda object_x_lo
    sec
    sbc #100
    sta camera_pixel_lo
    lda object_x_hi
    sbc #0
    sta camera_pixel_hi
    lda object_x_lo
    asl
    asl
    asl
    asl
    sta player_x_lo
    lda object_x_hi
    asl
    asl
    asl
    asl
    sta player_x_hi
    lda object_x_lo
    lsr
    lsr
    lsr
    lsr
    ora player_x_hi
    sta player_x_hi
    lda #$80                ; y = 120 pixels in 12.4
    sta player_y_lo
    lda #$07
    sta player_y_hi
    lda #1
    sta player_vy
    sta object_active
    ldx #0
    jsr objects_test_enemy_collision
    rts

; X = enemy ID. Reproduce the exact tile-landing frame: the floor has snapped
; player Y and VY, but the player entered the frame airborne.
autotest_enemy_exact_stomp:
    stx object_index
    lda object_x_lo,x
    asl
    asl
    asl
    asl
    sta player_x_lo
    lda object_x_hi,x
    asl
    asl
    asl
    asl
    sta player_x_hi
    lda object_x_lo,x
    lsr
    lsr
    lsr
    lsr
    ora player_x_hi
    sta player_x_hi
    lda object_y,x
    cpx #6
    bne @stomp_y_ready
    lda level_number
    cmp #2
    bne @regular_stomp_y
    lda object_y,x
    sec
    sbc #21                ; boss top contact: player feet meet its body
    bne @stomp_y_ready
@regular_stomp_y:
    lda object_y,x          ; exact tile equality, including the airborne drone
@stomp_y_ready:
    sta test_y_hi
    asl
    asl
    asl
    asl
    sta player_y_lo
    lda test_y_hi
    lsr
    lsr
    lsr
    lsr
    sta player_y_hi
    lda #0
    sta player_vy
    lda #1
    sta player_airborne_entry
    ldx object_index
    jsr objects_test_enemy_collision
    rts

; Reproduce the Level-2 platform position directly above the expanded boss.
; The old absolute 44-pixel Y distance treated this clear gap as a stomp.
autotest_boss_platform_gap:
    stx object_index
    lda object_x_lo,x
    asl
    asl
    asl
    asl
    sta player_x_lo
    lda object_x_hi,x
    asl
    asl
    asl
    asl
    sta player_x_hi
    lda object_x_lo,x
    lsr
    lsr
    lsr
    lsr
    ora player_x_hi
    sta player_x_hi
    lda #$B0                ; Y=91: feet at 112, boss begins at 118
    sta player_y_lo
    lda #$05
    sta player_y_hi
    lda #0
    sta player_vy
    sta player_airborne_entry
    ldx object_index
    jsr objects_test_enemy_collision
    rts

autotest_finish_layout:
    sei
@next:
    lda game_state
    cmp #GAME_LOAD_LAYOUT
    bne @done
    jsr game_update
    jmp @next
@done:
    cli
    rts

autotest_damage_cycle:
    lda #0
    sta game_state
    sta damage_cooldown
    sta player_deaths
    sta game_over_count
    lda #3
    sta lives
    lda #$40
    sta camera_pixel_lo
    lda #1
    sta camera_pixel_hi
    lda #$20
    sta player_x_lo
    lda #$20
    sta player_x_hi
    jsr player_damage
    lda game_state
    cmp #GAME_DEATH
    beq :+
    jmp @respawn_fail
:
    lda death_timer
    cmp #25
    beq :+
    jmp @respawn_fail
:
    lda camera_pixel_lo
    cmp #$40
    beq :+
    jmp @respawn_fail
:
    lda camera_pixel_hi
    cmp #1
    beq :+
    jmp @respawn_fail
:
    lda player_x_hi
    cmp #$20                ; impact presentation keeps the death position
    beq :+
    jmp @respawn_fail
:
    lda #0
    sta death_timer
    sta camera_pixel_lo      ; skip travel; exercise arrival ordering directly
    sta camera_pixel_hi
    jsr game_update
    lda game_state
    cmp #GAME_LOAD_A
    beq :+
    jmp @respawn_fail
:
    lda camera_pixel_lo
    ora camera_pixel_hi
    beq :+
    jmp @respawn_fail
:
    lda respawn_pending
    cmp #1
    beq :+
    jmp @respawn_fail
:
    lda player_x_hi
    cmp #$20                ; player is not moved before the camera reset
    beq :+
    jmp @respawn_fail
:
@finish_respawn:
    jsr game_update         ; eight rows per call; A then B at camera zero
    lda game_state
    cmp #GAME_LOAD_READY
    beq @respawn_ready
    cmp #GAME_LOAD_A
    beq @finish_respawn
    cmp #GAME_LOAD_B
    beq @finish_respawn
    jmp @respawn_fail
@respawn_ready:
    lda respawn_pending
    beq :+
    jmp @respawn_fail
:
    lda player_x_hi
    cmp #$04
    beq :+
    jmp @respawn_fail
:
    lda game_state
    cmp #GAME_LOAD_READY
    beq :+
    jmp @respawn_fail
:
    lda #GAME_PLAY
    sta game_state
    lda #0
    sta damage_cooldown
    jsr player_damage
    lda #0
    sta death_timer
    sta camera_pixel_lo
    sta camera_pixel_hi
    jsr game_update
    lda #0                  ; second rebuild was covered above; reach last life
    sta respawn_pending
    lda #GAME_PLAY
    sta game_state
    sta damage_cooldown
    lda #0
    jsr player_damage
    lda #0
    sta death_timer
    sta camera_pixel_lo
    sta camera_pixel_hi
    jsr game_update
    rts
@respawn_fail:
    lda #$8C
    sta test_fail_code
    sta $D7FF
@respawn_halt:
    jmp @respawn_halt

autotest_level_exit:
    lda #$00
    sta player_x_lo
    lda #$3B
    sta player_x_hi
    lda #JOY_UP
    sta joy_held
    jsr level_exit_update
    lda #0
    sta joy_held
    rts
.endif
