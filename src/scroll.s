.include "constants.inc"

.export scroll_init, scroll_update, window_render_target, window_render_respawn_slice, mutable_patch_refresh
.import world_chars, row_colors
.import joy_held
.importzp screen_ptr, color_ptr, source_ptr
.import tile_map_index, tile_row, tile_col
.import camera_pixel_lo, camera_pixel_hi, camera_char
.import visible_buffer, rendered_camera_char, scroll_d016, visible_d018
.import screen_a_char, screen_b_char
.import scroll_direction, coarse_scroll_count
.import player_x_lo, player_x_hi, player_pixel_lo, player_pixel_hi
.import mutable_block_state
.import respawn_render_row, death_timer

.segment "CODE"
scroll_init:
    lda #0
    sta camera_pixel_lo
    sta camera_pixel_hi
    sta camera_char
    sta visible_buffer
    sta rendered_camera_char
    sta screen_a_char
    sta screen_b_char
    sta coarse_scroll_count
    lda #1
    sta scroll_direction
    lda #$17                ; MCM, 38 columns, fine position 7
    sta scroll_d016
    lda #$02                ; Screen A + charset $4800
    sta visible_d018

    lda #>SCREEN_A
    jsr window_render_target
    lda #>SCREEN_B
    jsr window_render_target
    jsr color_zones_init
    rts

scroll_update:
.ifdef PHASE4_BUILD
    jsr camera_follow
    jmp @publish
.else
.ifdef AUTOTEST
    lda scroll_direction
    beq @auto_left
    jsr camera_right
    lda camera_pixel_hi
    cmp #$02
    bne @publish
    lda camera_pixel_lo
    cmp #$C0
    bne @publish
    lda #0
    sta scroll_direction
    jmp @publish
@auto_left:
    jsr camera_left
    lda camera_pixel_lo
    ora camera_pixel_hi
    bne @publish
    lda #1
    sta scroll_direction
.else
    lda joy_held
    and #JOY_RIGHT
    beq :+
    jsr camera_right
:
    lda joy_held
    and #JOY_LEFT
    beq @publish
    jsr camera_left
.endif
.endif

@publish:
    lda camera_pixel_lo
    and #$07
    eor #$07
    ora #$10                ; MCM + 38 columns
    sta scroll_d016

    lda camera_pixel_lo
    lsr
    lsr
    lsr
    sta camera_char
    lda camera_pixel_hi
    asl
    asl
    asl
    asl
    asl
    ora camera_char
    sta camera_char
    cmp rendered_camera_char
    beq @done
    jsr coarse_rebuild
@done:
    rts

.ifdef PHASE4_BUILD
; Respawn/death recovery never enters camera_follow: game_state freezes world
; updates and respawn_pending drives the sliced camera-zero rebuild in CODE3.
; death_timer is retained as a zero-valued compatibility symbol for branches that
; briefly carried the abandoned pre-slice recovery implementation.
camera_follow:
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

    lda player_pixel_lo
    sec
    sbc camera_pixel_lo
    sta source_ptr
    lda player_pixel_hi
    sbc camera_pixel_hi
    sta source_ptr+1
    bmi @follow_left
    bne @follow_right
    lda source_ptr
    cmp #200
    bcs @follow_right
    cmp #112
    bcc @follow_left
    rts
@follow_right:
    lda source_ptr+1
    bne @right_two
    lda source_ptr
    sec
    sbc #199                ; move only the excess beyond the right edge
    cmp #2
    bcs @right_two
    jsr camera_right
    rts
@right_two:
    jsr camera_right
    jsr camera_right
    rts
@follow_left:
    lda source_ptr+1
    bmi @left_two
    lda #112
    sec
    sbc source_ptr          ; move only the deficit before the left edge
    cmp #2
    bcs @left_two
    jsr camera_left
    rts
@left_two:
    jsr camera_left
    jsr camera_left
    rts
.endif

camera_right:
    lda camera_pixel_hi
    cmp #$02
    bcc @increment
    bne @done
    lda camera_pixel_lo
    cmp #$C0
    bcs @done
@increment:
    inc camera_pixel_lo
    bne @done
    inc camera_pixel_hi
@done:
    rts

camera_left:
    lda camera_pixel_lo
    ora camera_pixel_hi
    beq @done
    lda camera_pixel_lo
    bne :+
    dec camera_pixel_hi
:
    dec camera_pixel_lo
@done:
    rts

coarse_rebuild:
.ifdef DEBUG_BUILD
    lda #COLOR_GREEN
    sta VIC_BORDER
.endif
    lda visible_buffer
    beq @target_b
    lda #>SCREEN_A
    sta tile_col
    lda screen_a_char
    jmp @prepare
@target_b:
    lda #>SCREEN_B
    sta tile_col
    lda screen_b_char
@prepare:
    cmp camera_char
    beq @updated
    cmp #$FF
    beq @full
    sta tile_map_index
    lda camera_char
    sec
    sbc tile_map_index
    cmp #1
    beq @left
    cmp #2
    beq @left
    cmp #$FF
    beq @right_one
    cmp #$FE
    beq @right_two
@full:
    lda tile_col
    jsr window_render_target
    jmp @updated
@left:
    sta tile_map_index
    jsr shift_window_left
    jmp @updated
@right_one:
    lda #1
    bne @right
@right_two:
    lda #2
@right:
    sta tile_map_index
    jsr shift_window_right
@updated:
    lda visible_buffer
    beq @publish_b
    lda camera_char
    sta screen_a_char
    lda #0
    sta visible_buffer
    lda #$02
    sta visible_d018
    jmp @commit
@publish_b:
    lda camera_char
    sta screen_b_char
    lda #1
    sta visible_buffer
    lda #$12
    sta visible_d018
@commit:
    lda camera_char
    sta rendered_camera_char
    inc coarse_scroll_count
    rts

; Update a lagging hidden buffer by one or two columns. Alternating buffers are
; normally two views apart; on reversal the target may already be exact.
shift_window_left:
    lda tile_col
    cmp #>SCREEN_A
    bne @screen_b
    lda tile_map_index
    cmp #1
    bne :+
    jsr shift_a_left_1
    jmp @fill
:
    jsr shift_a_left_2
    jmp @fill
@screen_b:
    lda tile_map_index
    cmp #1
    bne :+
    jsr shift_b_left_1
    jmp @fill
:
    jsr shift_b_left_2
@fill:
    jsr init_fill_rows
@row:
    lda #40
    sec
    sbc tile_map_index
    tay
@column:
    lda (color_ptr),y
    sta (screen_ptr),y
    iny
    cpy #40
    bne @column
    jsr advance_fill_rows
    dec tile_row
    bne @row
    jmp finish_shift

shift_window_right:
    lda tile_col
    cmp #>SCREEN_A
    bne @screen_b
    lda tile_map_index
    cmp #1
    bne :+
    jsr shift_a_right_1
    jmp @fill
:
    jsr shift_a_right_2
    jmp @fill
@screen_b:
    lda tile_map_index
    cmp #1
    bne :+
    jsr shift_b_right_1
    jmp @fill
:
    jsr shift_b_right_2
@fill:
    jsr init_fill_rows
@row:
    ldy #0
@column:
    lda (color_ptr),y
    sta (screen_ptr),y
    iny
    cpy tile_map_index
    bne @column
    jsr advance_fill_rows
    dec tile_row
    bne @row
    jmp finish_shift

init_fill_rows:
    lda #0
    sta screen_ptr
    lda tile_col
    sta screen_ptr+1
    lda #<world_chars
    clc
    adc camera_char
    sta color_ptr
    lda #>world_chars
    adc #0
    sta color_ptr+1
    lda #24
    sta tile_row
    rts

advance_fill_rows:
    lda screen_ptr
    clc
    adc #40
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    lda color_ptr
    clc
    adc #128
    sta color_ptr
    bcc :+
    inc color_ptr+1
:
    rts

finish_shift:
    lda camera_char
    sta tile_map_index
    jsr render_mutable_block
    rts

.macro DEFINE_LEFT_SHIFT name, base, amount
.proc name
    ldx #0
copy:
    .repeat 24, row
        lda base + row*40 + amount,x
        sta base + row*40,x
    .endrepeat
    inx
    cpx #(40-amount)
    beq done
    jmp copy
done:
    rts
.endproc
.endmacro

.macro DEFINE_RIGHT_SHIFT name, base, amount
.proc name
    ldx #(39-amount)
copy:
    .repeat 24, row
        lda base + row*40,x
        sta base + row*40 + amount,x
    .endrepeat
    dex
    bmi done
    jmp copy
done:
    rts
.endproc
.endmacro

DEFINE_LEFT_SHIFT  shift_a_left_1,  SCREEN_A, 1
DEFINE_LEFT_SHIFT  shift_a_left_2,  SCREEN_A, 2
DEFINE_LEFT_SHIFT  shift_b_left_1,  SCREEN_B, 1
DEFINE_LEFT_SHIFT  shift_b_left_2,  SCREEN_B, 2
DEFINE_RIGHT_SHIFT shift_a_right_1, SCREEN_A, 1
DEFINE_RIGHT_SHIFT shift_a_right_2, SCREEN_A, 2
DEFINE_RIGHT_SHIFT shift_b_right_1, SCREEN_B, 1
DEFINE_RIGHT_SHIFT shift_b_right_2, SCREEN_B, 2

; A = target screen high byte. Rebuild 40x24 from the expanded 128x24 world.
window_render_target:
    sta tile_col
    sta screen_ptr+1
    lda #0
    sta screen_ptr
    lda #<world_chars
    clc
    adc camera_char
    sta source_ptr
    lda #>world_chars
    adc #0
    sta source_ptr+1
    lda #24
    sta tile_row
@row:
    ldy #0
@copy:
    lda (source_ptr),y
    sta (screen_ptr),y
    iny
    cpy #40
    bne @copy

    lda source_ptr
    clc
    adc #128
    sta source_ptr
    bcc :+
    inc source_ptr+1
:
    lda screen_ptr
    clc
    adc #40
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    dec tile_row
    bne @row
    lda camera_char
    sta tile_map_index
    jsr render_mutable_block
    rts

; A = target screen high byte. Rebuild eight rows at camera zero per frozen
; respawn frame. Three calls complete one buffer without approaching the PAL
; deadline that a full 960-cell rebuild plus SID/UI work can exceed.
.segment "CODE3"
window_render_respawn_slice:
    sta tile_col
    sta screen_ptr+1
    lda #0
    sta screen_ptr
    lda #<world_chars
    sta source_ptr
    lda #>world_chars
    sta source_ptr+1
    lda respawn_render_row
    beq @slice_ready
    cmp #8
    bne @slice_16
    lda #$40                ; screen row 8 = offset $0140
    sta screen_ptr
    inc screen_ptr+1
    lda source_ptr+1        ; world row 8 = offset $0400
    clc
    adc #4
    sta source_ptr+1
    jmp @slice_ready
@slice_16:
    lda #$80                ; screen row 16 = offset $0280
    sta screen_ptr
    inc screen_ptr+1
    inc screen_ptr+1
    lda source_ptr+1        ; world row 16 = offset $0800
    clc
    adc #8
    sta source_ptr+1
@slice_ready:
    lda #8
    sta tile_row
@slice_row:
    ldy #0
@slice_copy:
    lda (source_ptr),y
    sta (screen_ptr),y
    iny
    cpy #40
    bne @slice_copy
    lda source_ptr
    clc
    adc #128
    sta source_ptr
    bcc :+
    inc source_ptr+1
:
    lda screen_ptr
    clc
    adc #40
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    dec tile_row
    bne @slice_row
    lda respawn_render_row
    clc
    adc #8
    cmp #24
    bcc @store_row
    lda #0
    sta respawn_render_row
    sta tile_map_index       ; camera character column zero
    jsr render_mutable_block
    rts
@store_row:
    sta respawn_render_row
    rts

.segment "CODE"

; Overlay the authoritative Phase-5 map patch at metatile (10,8).
; The immutable expanded world below it is empty. A state change refreshes these
; four cells in both buffers immediately, without forcing a full rebuild.
render_mutable_block:
    lda tile_map_index
    cmp #21
    bcs @done
    eor #$FF
    clc
    adc #21                 ; screen column = 20 - camera_char
    tax
    lda #$80                ; row 16: base + 16*40 = base + $280
    sta screen_ptr
    lda tile_col
    clc
    adc #2
    sta screen_ptr+1
    txa
    clc
    adc screen_ptr
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    ldy #0
    lda mutable_block_state
    beq :+
    lda #0
    beq :++
:
    lda #67
:
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    lda screen_ptr
    clc
    adc #40
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    ldy #0
    lda mutable_block_state
    beq :+
    lda #0
    beq :++
:
    lda #68
:
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
@done:
    rts

; Refresh the four patch cells in both buffers without a 960-byte rebuild.
mutable_patch_refresh:
    lda screen_a_char
    cmp #$FF
    beq :+
    sta tile_map_index
    lda #>SCREEN_A
    sta tile_col
    jsr render_mutable_block
:
    lda screen_b_char
    cmp #$FF
    beq :+
    sta tile_map_index
    lda #>SCREEN_B
    sta tile_col
    jsr render_mutable_block
:
    rts

color_zones_init:
    lda #<COLOR_RAM
    sta color_ptr
    lda #>COLOR_RAM
    sta color_ptr+1
    ldx #0
@row:
    lda row_colors,x
    ldy #0
@fill:
    sta (color_ptr),y
    iny
    cpy #40
    bne @fill
    lda color_ptr
    clc
    adc #40
    sta color_ptr
    bcc :+
    inc color_ptr+1
:
    inx
    cpx #24
    bne @row
    rts
