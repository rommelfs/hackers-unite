.include "constants.inc"

.export projectile_init, projectile_update
.import projectile_sprite_data, bomb_sprite_data
.import joy_held, joy_pressed, game_state, player_stance, player_facing
.import player_x_lo, player_x_hi, player_y_lo, player_y_hi
.import projectile_active, projectile_x_lo, projectile_x_hi, projectile_y
.import projectile_direction, projectile_lifetime, projectile_cooldown
.import projectiles_fired, projectile_hits
.import projectile_mode, projectile_vy, bombs_thrown, frame_counter_lo
.import camera_pixel_lo, camera_pixel_hi
.import sprite_xy_shadow, sprite_enable_shadow, sprite_msb_shadow
.import test_x_hi, test_y_hi, projectile_collision_test
.import objects_projectile_hit

.segment "CODE2"
projectile_init:
    ldx #0
@copy:
    lda projectile_sprite_data,x
    sta $5200,x
    lda bomb_sprite_data,x
    sta $5240,x
    inx
    cpx #64
    bne @copy
    lda #0
    sta projectile_active
    sta projectile_cooldown
    sta projectiles_fired
    sta projectile_hits
    sta projectile_mode
    sta projectile_vy
    sta bombs_thrown
    rts

projectile_update:
    lda projectile_cooldown
    beq :+
    dec projectile_cooldown
:
    lda game_state
    beq :+
    lda #0
    sta projectile_active
    rts
:
    lda projectile_active
    bne @move
    lda joy_pressed
    and #JOY_FIRE
    bne :+
    rts
:
    lda projectile_cooldown
    beq :+
    rts
:
    jsr projectile_spawn
    jmp @render

@move:
    lda projectile_mode
    beq @straight_speed
    ; Bombs follow a signed integer arc. Up throws start at -4 px/frame;
    ; Down throws descend at +2. Gravity adds one every four PAL frames.
    lda projectile_y
    clc
    adc projectile_vy
    sta projectile_y
    lda projectile_vy
    bmi @bomb_rising
    bcc :+
    jmp @remove
:
    lda projectile_y
    cmp #192
    bcc @bomb_gravity
    jmp @remove
@bomb_rising:
    bcs @bomb_gravity
    jmp @remove
@bomb_gravity:
    lda frame_counter_lo
    and #3
    bne :+
    lda projectile_vy
    cmp #5
    bcs :+
    inc projectile_vy
:
    lda #2
    bne @horizontal_speed
@straight_speed:
    lda #4
@horizontal_speed:
    sta test_y_hi
    lda projectile_direction
    bmi @move_left
    lda projectile_x_lo
    clc
    adc test_y_hi
    sta projectile_x_lo
    bcc :+
    inc projectile_x_hi
:
    jmp @moved
@move_left:
    lda projectile_x_lo
    sec
    sbc test_y_hi
    sta projectile_x_lo
    bcs :+
    dec projectile_x_hi
:
@moved:
    dec projectile_lifetime
    beq @remove
    lda projectile_x_hi
    cmp #4
    bcs @remove
    jsr objects_projectile_hit
    beq :+
    inc projectile_hits
    bne @remove
:
    ; Convert the integer projectile center into metatile coordinates.
    lda projectile_x_lo
    lsr
    lsr
    lsr
    lsr
    sta test_x_hi
    lda projectile_x_hi
    asl
    asl
    asl
    asl
    ora test_x_hi
    sta test_x_hi
    lda projectile_y
    lsr
    lsr
    lsr
    lsr
    sta test_y_hi
    jsr projectile_collision_test
    bne @remove
@render:
    jsr projectile_render
@done:
    rts
@remove:
    lda #0
    sta projectile_active
    rts

projectile_spawn:
    ; Convert the player's 12.4 coordinates to integer pixels.
    lda player_x_lo
    lsr
    lsr
    lsr
    lsr
    sta projectile_x_lo
    lda player_x_hi
    asl
    asl
    asl
    asl
    ora projectile_x_lo
    sta projectile_x_lo
    lda player_x_hi
    lsr
    lsr
    lsr
    lsr
    sta projectile_x_hi
    lda player_facing
    sta projectile_direction
    lda #0
    sta projectile_mode
    sta projectile_vy
    lda joy_held
    and #JOY_UP
    beq @not_high_bomb
    lda #1
    sta projectile_mode
    lda #$FC                ; -4 px/frame high arc
    sta projectile_vy
    inc bombs_thrown
    jmp @mode_ready
@not_high_bomb:
    lda joy_held
    and #JOY_DOWN
    beq @mode_ready
    lda #2
    sta projectile_mode
    sta projectile_vy       ; +2 px/frame descending throw
    inc bombs_thrown
@mode_ready:
    lda projectile_direction
    bmi @left_spawn
    lda projectile_x_lo
    clc
    adc #16
    sta projectile_x_lo
    bcc @spawn_y
    inc projectile_x_hi
    bne @spawn_y
@left_spawn:
    lda projectile_x_lo
    sec
    sbc #4
    sta projectile_x_lo
    bcs @spawn_y
    dec projectile_x_hi
@spawn_y:
    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta projectile_y
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora projectile_y
    clc
    adc #8
    ldx player_stance
    beq :+
    adc #5
:
    sta projectile_y
    lda projectile_mode
    beq :+
    lda #64
    bne @store_lifetime
:
    lda #48
@store_lifetime:
    sta projectile_lifetime
    lda #10
    sta projectile_cooldown
    lda #1
    sta projectile_active
    inc projectiles_fired
    rts

projectile_render:
    ; The projectile borrows the highest currently unused hardware sprite.
    ldx #7
@find_slot:
    lda sprite_enable_shadow
    and sprite_bits,x
    beq @slot
    dex
    bne @find_slot
    rts
@slot:
    lda projectile_x_lo
    sec
    sbc camera_pixel_lo
    sta test_x_hi
    lda projectile_x_hi
    sbc camera_pixel_hi
    sta test_y_hi
    beq @visible
    cmp #1
    bne @left_edge
    lda test_x_hi
    cmp #64
    bcs @done
    bcc @visible
@left_edge:
    cmp #$FF
    bne @done
    lda test_x_hi
    cmp #233
    bcc @done
@visible:
    txa
    asl
    tay
    lda test_x_hi
    clc
    adc #24
    sta sprite_xy_shadow,y
    lda test_y_hi
    adc #0
    beq @low_x
    lda sprite_msb_shadow
    ora sprite_bits,x
    sta sprite_msb_shadow
    jmp @store_y
@low_x:
    lda sprite_bits,x
    eor #$FF
    and sprite_msb_shadow
    sta sprite_msb_shadow
@store_y:
    iny
    lda projectile_y
    clc
    adc #50
    sta sprite_xy_shadow,y
    lda sprite_bits,x
    ora sprite_enable_shadow
    sta sprite_enable_shadow
    lda projectile_mode
    beq @shot_art
    lda #$49
    bne @store_art
@shot_art:
    lda #$48
@store_art:
    sta SCREEN_A+$3F8,x
    sta SCREEN_B+$3F8,x
    lda projectile_mode
    beq :+
    lda #COLOR_WHITE
    bne @store_color
:
    lda #COLOR_YELLOW
@store_color:
    sta VIC_SPR0_COLOR,x
@done:
    rts

.segment "RODATA"
sprite_bits: .byte $01,$02,$04,$08,$10,$20,$40,$80
