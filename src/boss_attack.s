.include "constants.inc"

.export boss_attack_init, boss_attack_reset, boss_attack_update
.export boss_attack_test_spawn
.import action_sprite_data
.import game_state, level_number, object_persistence, object_active, boss_hp
.import object_x_lo, object_x_hi, player_x_lo, player_x_hi, player_y_lo, player_y_hi
.import camera_pixel_lo, camera_pixel_hi, sprite_xy_shadow
.import sprite_enable_shadow, sprite_msb_shadow
.import boss_shot_active, boss_shot_x_lo, boss_shot_x_hi, boss_shot_y
.import boss_shot_direction, boss_shot_cooldown, boss_shot_lifetime
.import boss_shots_fired, boss_shot_hits, difficulty_rank_lo
.import test_x_lo, test_x_hi, test_y_lo
.import player_damage

BOSS_SHOT_BIT = $10        ; hardware sprite 4, freed by collected 1-Up

.segment "CODE"
boss_attack_init:
    ldx #0
@copy:
    lda action_sprite_data+$80,x
    sta SPRITE_RAM+$4C0,x
    inx
    cpx #64
    bne @copy
    lda #0
    sta boss_shots_fired
    sta boss_shot_hits

boss_attack_reset:
    lda #0
    sta boss_shot_active
    lda #48
    sta boss_shot_cooldown
    rts

boss_attack_update:
    lda game_state
    bne @disable
    lda level_number
    cmp #2
    bne @disable
    lda object_persistence
    and #$0E
    cmp #$0E
    bne @disable             ; sprite slot 4 is not guaranteed free yet
    lda object_persistence
    and #$40
    bne @disable
    lda boss_hp
    beq @disable
    lda object_active+6
    beq @disable
    lda boss_shot_cooldown
    beq :+
    dec boss_shot_cooldown
:
    lda boss_shot_active
    bne @move
    lda boss_shot_cooldown
    bne @done
    jsr boss_shot_spawn
    jmp @render

@move:
    lda boss_shot_direction
    bmi @left
    lda boss_shot_x_lo
    clc
    adc #4
    sta boss_shot_x_lo
    bcc @moved
    inc boss_shot_x_hi
    bne @moved
@left:
    lda boss_shot_x_lo
    sec
    sbc #4
    sta boss_shot_x_lo
    bcs @moved
    dec boss_shot_x_hi
@moved:
    dec boss_shot_lifetime
    beq @remove
    lda boss_shot_x_hi
    cmp #4
    bcs @remove
    jsr boss_shot_collide
    lda boss_shot_active
    beq @done
@render:
    jsr boss_shot_render
@done:
    rts
@remove:
    lda #0
    sta boss_shot_active
    jsr boss_shot_reload
    rts
@disable:
    lda #0
    sta boss_shot_active
    rts

boss_shot_spawn:
boss_attack_test_spawn = boss_shot_spawn
    lda object_x_lo+6
    sta boss_shot_x_lo
    lda object_x_hi+6
    sta boss_shot_x_hi
    lda boss_shots_fired
    and #1
    bne :+
    lda #132                ; alternating body-height orb
    bne @store_y
:
    lda #112                ; then a high orb that favors ducking
@store_y:
    sta boss_shot_y
    lda player_x_hi
    lsr
    lsr
    lsr
    lsr
    cmp boss_shot_x_hi
    bcc @face_left
    bne @face_right
    lda player_x_hi
    asl
    asl
    asl
    asl
    sta test_x_lo
    lda player_x_lo
    lsr
    lsr
    lsr
    lsr
    ora test_x_lo
    cmp boss_shot_x_lo
    bcc @face_left
@face_right:
    lda #1
    bne @direction
@face_left:
    lda #$FF
@direction:
    sta boss_shot_direction
    lda #96
    sta boss_shot_lifetime
    lda #1
    sta boss_shot_active
    inc boss_shots_fired
    rts

boss_shot_collide:
    ; Convert player 12.4 X to integer and compare two fixed AABBs.
    lda player_x_lo
    lsr
    lsr
    lsr
    lsr
    sta test_x_lo
    lda player_x_hi
    asl
    asl
    asl
    asl
    ora test_x_lo
    sec
    sbc boss_shot_x_lo
    sta test_x_lo
    lda player_x_hi
    lsr
    lsr
    lsr
    lsr
    sbc boss_shot_x_hi
    beq @x_positive
    cmp #$FF
    bne @clear
    lda test_x_lo
    eor #$FF
    clc
    adc #1
    bne @x_distance
@x_positive:
    lda test_x_lo
@x_distance:
    cmp #16
    bcs @clear
    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta test_y_lo
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora test_y_lo
    sec
    sbc boss_shot_y
    bcs :+
    eor #$FF
    clc
    adc #1
:
    cmp #20
    bcs @clear
    inc boss_shot_hits
    lda #0
    sta boss_shot_active
    jsr boss_shot_reload
    jsr player_damage
@clear:
    rts

boss_shot_render:
    lda boss_shot_x_lo
    sec
    sbc camera_pixel_lo
    sta test_x_lo
    lda boss_shot_x_hi
    sbc camera_pixel_hi
    sta test_x_hi
    beq @visible
    cmp #1
    bne @left_edge
    lda test_x_lo
    cmp #64
    bcs @offscreen
    bcc @visible
@left_edge:
    cmp #$FF
    bne @offscreen
    lda test_x_lo
    cmp #233
    bcc @offscreen
@visible:
    lda test_x_lo
    clc
    adc #24
    sta sprite_xy_shadow+8
    lda test_x_hi
    adc #0
    beq @low_x
    lda sprite_msb_shadow
    ora #BOSS_SHOT_BIT
    bne @store_msb
@low_x:
    lda sprite_msb_shadow
    and #$EF
@store_msb:
    sta sprite_msb_shadow
    lda boss_shot_y
    clc
    adc #50
    sta sprite_xy_shadow+9
    lda sprite_enable_shadow
    ora #BOSS_SHOT_BIT
    sta sprite_enable_shadow
    lda #$53
    sta SCREEN_A+$3FC
    sta SCREEN_B+$3FC
    lda #COLOR_YELLOW
    sta VIC_SPR0_COLOR+4
    rts
@offscreen:
    lda #0
    sta boss_shot_active
    jsr boss_shot_reload
    rts

boss_shot_reload:
    lda boss_hp
    cmp #4
    bcc @rage
    lda difficulty_rank_lo
    cmp #8
    bcs @hard
    lda #56
    bne @store
@hard:
    lda #40
    bne @store
@rage:
    lda #28
@store:
    sta boss_shot_cooldown
    rts
