.include "constants.inc"

.export sprites_init, player_sprite_update
.import player_sprite_data, stance_sprite_data
.import player_x_lo, player_x_hi, player_y_lo, player_y_hi, player_frame
.import player_pixel_lo, player_pixel_hi
.import camera_pixel_lo, camera_pixel_hi
.import sprite_xy_shadow, sprite_enable_shadow, sprite_msb_shadow
.import player_stance, player_vx
.import game_state, death_timer

.segment "CODE"
sprites_init:
    ldx #0
@copy:
    lda player_sprite_data+$000,x
    sta SPRITE_RAM+$000,x
    inx
    bne @copy
    lda #$40
    sta SCREEN_A+$3F8
    sta SCREEN_B+$3F8
    ldx #0
@stance_copy:
    lda stance_sprite_data,x
    sta $5300,x
    inx
    cpx #128
    bne @stance_copy
    lda #COLOR_DARK_GREY
    sta VIC_SPR_MC0
    lda #COLOR_CYAN
    sta VIC_SPR_MC1
    lda #COLOR_GREEN
    sta VIC_SPR0_COLOR
    lda #$01
    sta VIC_SPR_MC
    sta VIC_SPR_ENABLE
    sta sprite_enable_shadow
    lda #0
    sta sprite_msb_shadow
    lda #88                ; initial world X 64 + VIC border 24
    sta sprite_xy_shadow
    lda #189               ; initial world Y 139 + playfield offset 50
    sta sprite_xy_shadow+1
    rts

player_sprite_update:
    lda game_state
    cmp #GAME_DEATH
    bne @player_visible
    lda death_timer
    beq @player_hidden
    and #$04                ; impact flicker while the camera is still fixed
    beq @player_visible
@player_hidden:
    lda sprite_enable_shadow
    and #$FE
    sta sprite_enable_shadow
@player_visible:
    ; Convert player X from 12.4 to integer pixels.
    lda player_x_lo
    lsr
    lsr
    lsr
    lsr
    sta player_pixel_lo
    lda player_x_hi
    asl
    asl
    asl
    asl
    ora player_pixel_lo
    sta player_pixel_lo
    lda player_x_hi
    lsr
    lsr
    lsr
    lsr
    sta player_pixel_hi

    ; Preserve the 16-bit subtraction before applying the VIC left-border offset.
    lda player_pixel_lo
    sec
    sbc camera_pixel_lo
    sta player_pixel_lo
    lda player_pixel_hi
    sbc camera_pixel_hi
    sta player_pixel_hi
    lda player_pixel_lo
    clc
    adc #24
    sta sprite_xy_shadow
    lda player_pixel_hi
    adc #0
    beq @x_low
    lda sprite_msb_shadow
    ora #$01
    sta sprite_msb_shadow
    jmp @y
@x_low:
    lda sprite_msb_shadow
    and #$FE
    sta sprite_msb_shadow

@y:
    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta player_pixel_lo
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora player_pixel_lo
    clc
    adc #50
    sta sprite_xy_shadow+1
    lda player_stance
    beq @standing_pointer
    lda player_vx
    beq :+
    lda #$4D
    bne @store_pointer
:
    lda #$4C
    bne @store_pointer
@standing_pointer:
    lda player_frame
    clc
    adc #$40
@store_pointer:
    sta SCREEN_A+$3F8
    sta SCREEN_B+$3F8
    rts
