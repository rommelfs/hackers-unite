.include "constants.inc"

.export game_init, game_update, level_exit_update, player_damage, add_score
.import joy_held, joy_pressed
.import player_init, player_respawn, player_level_start, objects_init
.import player_x_hi
.import score_lo, score_hi, lives, game_state, damage_cooldown
.import player_deaths, game_over_count, object_persistence
.import mutable_block_state, mutable_blocks_hit
.import level_number, level_clear_timer, exit_entries, level_transitions
.import difficulty_rank_lo, difficulty_rank_hi
.import boss_defeats, boss_hits, trap_hits, secret_found
.import falling_drops, rolling_cycles, action_hits
.import continue_seconds, continue_tick, continues_used, continue_timeouts
.import respawn_pending, respawn_render_row, death_timer, sprite_enable_shadow, sprite_msb_shadow
.import camera_pixel_lo, camera_pixel_hi, camera_char
.import rendered_camera_char, screen_a_char, screen_b_char
.import visible_buffer, visible_d018, scroll_d016
.import window_render_target, window_render_respawn_slice, scroll_return_update
.import level_layout_apply, level_layout_begin, level_layout_step
.import sfx_damage, sfx_level_clear

.segment "CODE"
game_init:
    pha                     ; A=0 cold boot, nonzero staged runtime restart
    lda #0
    sta score_lo
    sta score_hi
    sta game_state
    sta damage_cooldown
    sta player_deaths
    sta game_over_count
    sta mutable_block_state
    sta mutable_blocks_hit
    sta level_clear_timer
    sta exit_entries
    sta level_transitions
    sta difficulty_rank_lo
    sta difficulty_rank_hi
    sta boss_defeats
    sta boss_hits
    sta trap_hits
    sta secret_found
    sta falling_drops
    sta rolling_cycles
    sta action_hits
    sta continue_seconds
    sta continue_tick
    sta continues_used
    sta continue_timeouts
    sta respawn_pending
    sta respawn_render_row
    sta death_timer          ; compatibility only; sliced recovery owns timing
.ifdef PHASE12_PREVIEW
    lda #3
.else
    lda #1
.endif
    sta level_number
    jsr apply_level_palette
    pla
    bne @staged_restart
    jsr level_layout_apply
    jmp @layout_ready
@staged_restart:
    jsr level_layout_begin
@layout_ready:
    lda #3
    sta lives
    jsr objects_init
    rts

game_update:
    lda damage_cooldown
    beq :+
    dec damage_cooldown
:
    lda game_state
    bne :+
    rts
:
    cmp #GAME_OVER
    bne :+
    jmp @game_over
:
    cmp #GAME_CONTINUE
    bne :+
    jmp @continue
:
    cmp #GAME_BRIEFING
    bne :+
    jmp @briefing
:
    cmp #GAME_DEATH
    bne :+
    jmp @death
:
    cmp #GAME_LEVEL_CLEAR
    bne :+
    jmp @level_clear
:
    cmp #GAME_COMPLETE
    bne :+
    jmp @complete
:
    cmp #GAME_LOAD_A
    bne :+
    jmp @load_a
:
    cmp #GAME_LOAD_B
    bne :+
    jmp @load_b
:
    cmp #GAME_LOAD_LAYOUT
    bne :+
    jmp @load_layout
:
    ; GAME_LOAD_READY: both buffers are coherent, resume next frame.
    lda #GAME_PLAY
    sta game_state
    rts

@briefing:
    lda joy_pressed
    and #JOY_FIRE
    bne :+
    rts
:
    jsr player_level_start
    jsr objects_init
    jmp begin_level_load

@death:
    lda death_timer
    beq @death_return
    dec death_timer
    rts
@death_return:
    jsr scroll_return_update
    lda camera_pixel_lo
    ora camera_pixel_hi
    beq @death_arrived
    rts
@death_arrived:
    lda lives
    bne @death_respawn
    lda #GAME_CONTINUE
    sta game_state
    rts
@death_respawn:
    lda #50                 ; recovery protection begins at the actual spawn
    sta damage_cooldown
    lda #1
    sta respawn_pending
    lda #0
    sta respawn_render_row
    sta sprite_enable_shadow
    sta sprite_msb_shadow
    jmp begin_level_load

@game_over:
    lda joy_pressed
    and #JOY_FIRE
    bne :+
    rts
:
    jsr player_init
    lda #1
    jsr game_init
    jmp begin_level_patch

; Classic nine-second continue: Fire restarts the current section with three
; lives while preserving score, level and danger rank. Expiry exposes the
; normal GAME OVER/new-game state.
@continue:
    lda joy_pressed
    and #JOY_FIRE
    bne @continue_accept
    dec continue_tick
    beq :+
    rts
:
    lda #50
    sta continue_tick
    dec continue_seconds
    beq :+
    rts
:
    inc continue_timeouts
    lda #GAME_OVER
    sta game_state
    rts
@continue_accept:
    inc continues_used
    lda #3
    sta lives
    lda #0
    sta damage_cooldown
    sta mutable_block_state
    jsr apply_level_palette
    jsr level_layout_begin
    jsr objects_init
    jsr player_level_start
    jmp begin_level_patch

@level_clear:
    lda level_clear_timer
    beq :+
    dec level_clear_timer
:
    lda joy_pressed
    and #JOY_FIRE
    bne :+
    rts
:
    inc difficulty_rank_lo
    bne :+
    inc difficulty_rank_hi
:
    lda level_number
    cmp #3
    beq @campaign_complete
    inc level_number
    inc level_transitions
    lda #0
    sta mutable_block_state
    jsr apply_level_palette
    jsr level_layout_begin
    jsr objects_init
    jsr player_level_start
    jmp begin_level_patch

@campaign_complete:
    lda #GAME_COMPLETE
    sta game_state
    inc level_transitions
    rts

@complete:
    lda joy_pressed
    and #JOY_FIRE
    beq @done
    lda #1
    sta level_number
    inc level_transitions
    lda #0
    sta mutable_block_state
    jsr apply_level_palette
    jsr level_layout_begin
    jsr objects_init
    jsr player_level_start
    jmp begin_level_patch

@load_layout:
    jsr level_layout_step
    bne @done
    lda #GAME_LOAD_A
    sta game_state
    rts

@load_a:
    lda respawn_pending
    beq @load_a_full
    lda #>SCREEN_A
    jsr window_render_respawn_slice
    lda respawn_render_row
    bne @done
    lda #GAME_LOAD_B
    sta game_state
    rts
@load_a_full:
    lda #>SCREEN_A
    jsr window_render_target
    lda #GAME_LOAD_B
    sta game_state
    rts

@load_b:
    lda respawn_pending
    beq @load_b_full
    lda #>SCREEN_B
    jsr window_render_respawn_slice
    lda respawn_render_row
    bne @done
    jmp @load_b_ready
@load_b_full:
    lda #>SCREEN_B
    jsr window_render_target
@load_b_ready:
    lda #0
    sta screen_a_char
    sta screen_b_char
    sta rendered_camera_char
    sta visible_buffer
    lda #$02
    sta visible_d018
    lda #$17
    sta scroll_d016
    lda respawn_pending
    beq :+
    lda #0
    sta respawn_pending
    jsr player_respawn      ; camera and both start buffers are ready first
:
    lda #GAME_LOAD_READY
    sta game_state
@done:
    rts

begin_level_load:
    lda #0
    sta camera_pixel_lo
    sta camera_pixel_hi
    sta camera_char
    lda #GAME_LOAD_A
    sta game_state
    rts

begin_level_patch:
    lda #0
    sta camera_pixel_lo
    sta camera_pixel_hi
    sta camera_char
    lda #GAME_LOAD_LAYOUT
    sta game_state
    rts

; Global multicolor registers may change at a level boundary without touching
; steady-state Color RAM. Level 3 uses an unmistakable warning-red factory set.
apply_level_palette:
    lda level_number
    cmp #3
    bne @network
    lda #COLOR_RED
    sta VIC_BG1
    lda #COLOR_YELLOW
    sta VIC_BG2
    rts
@network:
    lda #COLOR_DARK_GREY
    sta VIC_BG1
    lda #COLOR_LIGHT_BLUE
    sta VIC_BG2
    rts

; Badge, slides and coffee complete the speaker kit. Up enters the far-right
; stage/section gate; the auditorium AV boss additionally guards Level 2.
level_exit_update:
    lda game_state
    bne @done
    lda object_persistence
    and #$0E
    cmp #$0E
    bne @done
    lda level_number
    cmp #2
    bne :+
    lda object_persistence
    and #$40
    beq @done               ; Level 2 portal stays sealed until boss defeat.
:
    lda player_x_hi
    cmp #$3B                ; world X >= 944 pixels
    bcc @done
    lda joy_held
    and #JOY_UP
    beq @done
    lda #GAME_LEVEL_CLEAR
    sta game_state
    lda #100
    sta level_clear_timer
    inc exit_entries
    lda #200
    jsr add_score
    jsr sfx_level_clear
@done:
    rts

; A = points to add to the 16-bit binary score.
add_score:
    clc
    adc score_lo
    sta score_lo
    bcc :+
    inc score_hi
:
    rts

player_damage:
    lda damage_cooldown
    bne @done
    jsr sfx_damage
    inc player_deaths
    lda lives
    beq @last_life
    dec lives
    beq @last_life
    lda #50
    sta damage_cooldown
    jmp @begin_death
@last_life:
    lda #9
    sta continue_seconds
    lda #50
    sta continue_tick
    inc game_over_count
    lda #0
    sta damage_cooldown
@begin_death:
    lda sprite_enable_shadow
    and #$01                ; keep only the player for the impact flicker
    sta sprite_enable_shadow
    lda sprite_msb_shadow
    and #$01
    sta sprite_msb_shadow
    lda #25                 ; half-second impact/flicker before camera travel
    sta death_timer
    lda #GAME_DEATH
    sta game_state
@done:
    rts
