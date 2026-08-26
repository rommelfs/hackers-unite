.include "constants.inc"

.export player_init, player_update, player_respawn, player_level_start, mutable_block_hit_test
.export projectile_collision_test, player_hazard_test
.export player_control_test, player_jump_test
.import joy_held, joy_pressed, frame_counter_lo
.import static_map, metatile_flags
.importzp source_ptr
.import player_x_lo, player_x_hi, player_y_lo, player_y_hi
.import player_vx, player_vy, player_grounded, player_frame, player_anim_timer
.import player_airborne_entry
.import player_stance, player_facing, crouch_frames, crawl_frames
.import test_x_lo, test_x_hi, test_y_lo, test_y_hi
.import collision_landings, player_respawns, running_jumps, high_landings, scroll_direction
.import mutable_block_state, mutable_blocks_hit, trap_hits, secret_found, damage_cooldown
.import mutable_patch_refresh
.import player_damage, add_score, lives
.import sfx_jump, sfx_pickup

SOLID_FLAG = $01
HAZARD_FLAG = $02
ACCEL      = 2
MAX_SPEED  = 24
CRAWL_SPEED = 8
GRAVITY    = 3
MAX_FALL   = 64
STAND_JUMP = $C8            ; -56: about 31 pixels of rise
RUN_JUMP   = $B8            ; -72: about 52 pixels of rise
RUN_JUMP_THRESHOLD = 16     ; 1.0 pixel/frame in signed 4.4

.segment "CODE"
player_init:
    lda #$00                ; x = 64 pixels in 12.4
    sta player_x_lo
    lda #$04
    sta player_x_hi
    lda #$B0                ; y = 139 pixels, floor top is 160
    sta player_y_lo
    lda #$08
    sta player_y_hi
    lda #0
    sta player_vx
    sta player_vy
    sta player_airborne_entry
    sta player_frame
    sta player_anim_timer
    sta player_stance
    sta crouch_frames
    sta crawl_frames
    sta collision_landings
    sta player_respawns
    sta running_jumps
    sta high_landings
    lda #1
    sta player_grounded
    sta player_facing
    rts

player_update:
    lda player_grounded
    eor #1
    and #1
    sta player_airborne_entry
.ifdef AUTOTEST
.ifdef SOAK_TEST
    lda player_x_hi
    cmp #$3E
    bcc :+
    lda #0
    sta scroll_direction
:
    lda player_x_hi
    cmp #$04
    bcs :+
    lda #1
    sta scroll_direction
:
    lda scroll_direction
    beq :+
    lda #JOY_RIGHT
    bne :++
:
    lda #JOY_LEFT
:
.else
    lda #JOY_RIGHT
.endif
    sta joy_held
    lda #0
    sta joy_pressed
    lda frame_counter_lo
    and #$3F
    cmp #1
    bne :+
    lda #JOY_UP
    sta joy_pressed
:
.endif
    jsr player_control_test
    jsr jump_input
    jsr move_horizontal
    jsr apply_gravity
    jsr move_vertical
    jsr hazard_update
    jsr animate_player
    rts

player_control_test:
    jsr stance_input
    jsr horizontal_input
    jmp crawl_limit

stance_input:
    lda player_grounded
    bne :+
    lda #0
    sta player_stance
    rts
:
    lda joy_held
    and #JOY_DOWN
    beq @try_stand
    lda #1
    sta player_stance
    inc crouch_frames
    lda joy_held
    and #(JOY_LEFT | JOY_RIGHT)
    beq @done
    inc crawl_frames
@done:
    rts
@try_stand:
    lda player_stance
    beq @done
    ; Both shoulders must clear the overhead metatile before standing.
    lda #$30
    ldx #0
    jsr set_test_x
    lda #$20
    ldx #0
    jsr set_test_y
    jsr collision_test
    bne @done
    lda #$C0
    ldx #0
    jsr set_test_x
    jsr collision_test
    bne @done
    lda #0
    sta player_stance
    rts

crawl_limit:
    lda player_stance
    beq @done
    lda player_vx
    bmi @left
    cmp #(CRAWL_SPEED+1)
    bcc @done
    lda #CRAWL_SPEED
    sta player_vx
    rts
@left:
    cmp #($100-CRAWL_SPEED)
    bcs @done
    lda #($100-CRAWL_SPEED)
    sta player_vx
@done:
    rts

horizontal_input:
    lda joy_held
    and #JOY_RIGHT
    beq @not_right
    lda player_vx
    bmi @right_add
    cmp #MAX_SPEED
    bcs @done
@right_add:
    clc
    adc #ACCEL
    cmp #(MAX_SPEED+1)
    bcc :+
    lda #MAX_SPEED
:
    sta player_vx
    lda #1
    sta player_facing
    rts
@not_right:
    lda joy_held
    and #JOY_LEFT
    beq @friction
    lda player_vx
    bpl @left_sub
    cmp #($100-MAX_SPEED)
    bcc @done
@left_sub:
    sec
    sbc #ACCEL
    cmp #($100-MAX_SPEED)
    bcs :+
    lda #($100-MAX_SPEED)
:
    sta player_vx
    lda #$FF
    sta player_facing
    rts
@friction:
    lda player_vx
    beq @done
    bmi @friction_left
    sec
    sbc #ACCEL
    bcs :+
    lda #0
:
    sta player_vx
    rts
@friction_left:
    clc
    adc #ACCEL
    bcc :+
    lda #0
:
    sta player_vx
@done:
    rts

jump_input:
player_jump_test = jump_input
    lda player_grounded
    beq @done
    lda joy_held
    and #JOY_FIRE
    bne @done               ; Fire+Up is the high bomb throw, not a jump.
    lda joy_pressed
    and #JOY_UP
    beq @done
    lda player_stance
    bne @done
    lda player_vx
    bpl @jump_magnitude
    eor #$FF
    clc
    adc #1
@jump_magnitude:
    cmp #RUN_JUMP_THRESHOLD
    bcc @standing_jump
    lda #RUN_JUMP
    inc running_jumps
    jmp @launch
@standing_jump:
    lda #STAND_JUMP
@launch:
    sta player_vy
    jsr sfx_jump
    lda #0
    sta player_grounded
    lda #3
    sta player_frame
@done:
    rts

move_horizontal:
    lda player_x_lo
    clc
    adc player_vx
    sta player_x_lo
    lda player_x_hi
    ldx player_vx
    bpl :+
    adc #$FF
    jmp :++
:
    adc #0
:
    sta player_x_hi

    lda player_vx
    beq @bounds
    bmi @left
@right:
    lda #$E0
    ldx #0
    jsr set_test_x
    lda player_stance
    bne @right_lower
    lda #$20
    ldx #0
    jsr set_test_y
    jsr collision_test
    bne @hit_right
@right_lower:
    lda #$20
    ldx #1
    jsr set_test_y
    jsr collision_test
    beq @bounds
@hit_right:
    lda test_x_hi
    sec
    sbc #1
    sta player_x_hi
    lda #$20
    sta player_x_lo
    lda #0
    sta player_vx
    jmp @bounds
@left:
    lda player_stance
    bne @left_lower
    lda #$20
    ldx #0
    jsr set_test_x
    lda #$20
    ldx #0
    jsr set_test_y
    jsr collision_test
    bne @hit_left
@left_lower:
    lda #$20
    ldx #1
    jsr set_test_y
    jsr collision_test
    beq @bounds
@hit_left:
    lda test_x_hi
    sta player_x_hi
    lda #$E0
    sta player_x_lo
    lda #0
    sta player_vx

@bounds:
    lda player_x_hi
    bpl @max
    lda #0
    sta player_x_lo
    sta player_x_hi
    sta player_vx
@max:
    lda player_x_hi
    cmp #$3F
    bcc @done
    bne @clamp_max
    lda player_x_lo
    cmp #$20
    bcc @done
@clamp_max:
    lda #$20
    sta player_x_lo
    lda #$3F
    sta player_x_hi
    lda #0
    sta player_vx
@done:
    rts

apply_gravity:
    lda player_vy
    bmi @add
    cmp #MAX_FALL
    bcs @done
@add:
    clc
    adc #GRAVITY
    bpl :+
    sta player_vy
    rts
:
    cmp #(MAX_FALL+1)
    bcc :+
    lda #MAX_FALL
:
    sta player_vy
@done:
    rts

move_vertical:
    lda player_y_lo
    clc
    adc player_vy
    sta player_y_lo
    lda player_y_hi
    ldx player_vy
    bpl :+
    adc #$FF
    jmp :++
:
    adc #0
:
    sta player_y_hi
    lda #0
    sta player_grounded
    lda player_vy
    bmi @ascending

@descending:
    lda #$30
    ldx #0
    jsr set_test_x
    lda #$50
    ldx #1
    jsr set_test_y
    jsr collision_test
    bne @land
    lda #$C0
    ldx #0
    jsr set_test_x
    jsr collision_test
    beq @fall_check
@land:
    lda test_y_hi
    cmp #10
    bcs :+
    inc high_landings
:
    lda test_y_hi
    sec
    sbc #2
    sta player_y_hi
    lda #$B0
    sta player_y_lo
    lda #0
    sta player_vy
    lda #1
    sta player_grounded
    inc collision_landings
    jmp @done

@ascending:
    lda #$30
    ldx #0
    jsr set_test_x
    lda #$10
    ldx #0
    jsr set_test_y
    jsr collision_test
    bne @head_hit
    lda #$C0
    ldx #0
    jsr set_test_x
    jsr collision_test
    beq @done
@head_hit:
    jsr mutate_block_if_hit
    lda test_y_hi
    sta player_y_hi
    lda #$F0
    sta player_y_lo
    lda #0
    sta player_vy
    jmp @done

@fall_check:
    lda player_y_hi
    cmp #$0C
    bcc @done
    jsr player_respawn
@done:
    rts

; A = fixed low offset, X = fixed high offset.
set_test_x:
    clc
    adc player_x_lo
    sta test_x_lo
    txa
    adc player_x_hi
    sta test_x_hi
    rts

set_test_y:
    clc
    adc player_y_lo
    sta test_y_lo
    txa
    adc player_y_hi
    sta test_y_hi
    rts

; Returns Z clear for SOLID. Fixed 12.4 test coordinates map directly via high byte.
collision_test:
projectile_collision_test = collision_test
    lda mutable_block_state
    bne :+
    lda test_y_hi
    cmp #8
    bne :+
    lda test_x_hi
    cmp #10
    beq @solid
:
    lda test_y_hi
    cmp #12
    bcs @solid
    tax
    lda map_row_lo,x
    sta source_ptr
    lda map_row_hi,x
    sta source_ptr+1
    ldy test_x_hi
    cpy #64
    bcs @solid
    lda (source_ptr),y
    tax
    lda metatile_flags,x
    and #SOLID_FLAG
    rts
@solid:
    lda #SOLID_FLAG
    rts

mutate_block_if_hit:
mutable_block_hit_test = mutate_block_if_hit
    lda mutable_block_state
    bne @done
    lda test_y_hi
    cmp #8
    bne @done
    lda test_x_hi
    cmp #10
    bne @done
    lda #1
    sta mutable_block_state
    inc mutable_blocks_hit
    jsr mutable_patch_refresh
    inc lives
    inc secret_found
    lda #100
    jsr add_score
    jsr sfx_pickup
@done:
    rts

; The fixed player foot box, not the sprite pixels, triggers map hazards.
hazard_update:
player_hazard_test = hazard_update
    lda #$30
    ldx #0
    jsr set_test_x
    lda #$40
    ldx #1
    jsr set_test_y
    jsr hazard_test
    bne @hit
    lda #$C0
    ldx #0
    jsr set_test_x
    jsr hazard_test
    beq @done
@hit:
    lda damage_cooldown
    bne @done
    inc trap_hits
    jsr player_damage
@done:
    rts

hazard_test:
    lda test_y_hi
    cmp #12
    bcs @clear
    tax
    lda map_row_lo,x
    sta source_ptr
    lda map_row_hi,x
    sta source_ptr+1
    ldy test_x_hi
    cpy #64
    bcs @clear
    lda (source_ptr),y
    tax
    lda metatile_flags,x
    and #HAZARD_FLAG
    rts
@clear:
    lda #0
    rts

player_respawn:
    inc player_respawns
    jmp player_init_position

player_init_position:
player_level_start = player_init_position
    lda #$00
    sta player_x_lo
    lda #$04
    sta player_x_hi
    lda #$B0
    sta player_y_lo
    lda #$08
    sta player_y_hi
    lda #0
    sta player_vx
    sta player_vy
    sta player_grounded
    sta player_airborne_entry
    sta player_stance
    rts

animate_player:
    lda player_stance
    beq :+
    lda #0
    sta player_frame
    rts
:
    lda player_grounded
    beq @jump
    lda player_vx
    beq @idle
    inc player_anim_timer
    lda player_anim_timer
    and #$07
    bne @done
    lda player_frame
    eor #$03
    and #$03
    bne :+
    lda #1
:
    sta player_frame
    rts
@idle:
    lda #0
    sta player_frame
    rts
@jump:
    lda #3
    sta player_frame
@done:
    rts

.segment "RODATA"
map_row_lo:
    .repeat 12, row
        .byte <(static_map + row*64)
    .endrepeat
map_row_hi:
    .repeat 12, row
        .byte >(static_map + row*64)
    .endrepeat
