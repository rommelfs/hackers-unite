.include "constants.inc"

.export charset_install, tilemap_render, level_layout_apply
.export level_layout_begin, level_layout_step
.import charset_data, metatile_chars, metatile_colors, static_map, world_chars
.import level_layout_patches
.importzp screen_ptr, color_ptr
.importzp source_ptr
.import tile_map_index, tile_row, tile_col, level_number

.segment "CODE"
charset_install:
    ldx #0
@copy:
    lda charset_data+$000,x
    sta CHARSET_RAM+$000,x
    lda charset_data+$100,x
    sta CHARSET_RAM+$100,x
    lda charset_data+$200,x
    sta CHARSET_RAM+$200,x
    lda charset_data+$300,x
    sta CHARSET_RAM+$300,x
    lda charset_data+$400,x
    sta CHARSET_RAM+$400,x
    lda charset_data+$500,x
    sta CHARSET_RAM+$500,x
    lda charset_data+$600,x
    sta CHARSET_RAM+$600,x
    lda charset_data+$700,x
    sta CHARSET_RAM+$700,x
    inx
    bne @copy
    rts

; Apply the compact reversible map delta for the selected level. Each record is
; map offset, expanded-world top-left offset, and Level-1/2/3 tile indices.
level_layout_apply:
    jsr level_layout_begin
@all:
    jsr level_layout_record
    lda tile_row
    bne @all
    rts

level_layout_begin:
    lda level_layout_patches
    sta tile_row
    lda #<(level_layout_patches+1)
    sta screen_ptr
    lda #>(level_layout_patches+1)
    sta screen_ptr+1
    rts

; Apply at most 16 records in one logical loading frame. Returns A=0 when the
; authoritative map/world pair is complete, A=1 while more records remain.
level_layout_step:
    lda tile_row
    beq @complete
    lda #16
    sta tile_map_index
@chunk:
    jsr level_layout_record
    lda tile_row
    beq @complete
    dec tile_map_index
    bne @chunk
    lda #1
    rts
@complete:
    lda #0
    rts

level_layout_record:
    lda level_number
    cmp #2
    bne @not_level_two
    ldy #5
    lda (screen_ptr),y
    jmp @tile_selected
@not_level_two:
    cmp #3
    bne @level_one
    ldy #6
    lda (screen_ptr),y
    jmp @tile_selected
@level_one:
    ldy #4
    lda (screen_ptr),y
@tile_selected:
    sta tile_col

    ldy #0
    lda (screen_ptr),y
    clc
    adc #<static_map
    sta source_ptr
    iny
    lda (screen_ptr),y
    adc #>static_map
    sta source_ptr+1
    ldy #0
    lda tile_col
    sta (source_ptr),y

    ldy #2
    lda (screen_ptr),y
    clc
    adc #<world_chars
    sta source_ptr
    iny
    lda (screen_ptr),y
    adc #>world_chars
    sta source_ptr+1
    lda tile_col
    asl
    asl
    tax
    ldy #0
    lda metatile_chars,x
    sta (source_ptr),y
    inx
    iny
    lda metatile_chars,x
    sta (source_ptr),y
    inx
    ldy #128
    lda metatile_chars,x
    sta (source_ptr),y
    inx
    iny
    lda metatile_chars,x
    sta (source_ptr),y

    lda screen_ptr
    clc
    adc #7
    sta screen_ptr
    bcc :+
    inc screen_ptr+1
:
    dec tile_row
    rts

; Render a 20x12 map of 2x2-character metatiles into 40x24 cells.
; Character and color data stay separate; behavior flags are never consulted here.
tilemap_render:
    lda #0
    sta tile_map_index
    sta tile_row
@row:
    lda tile_row
    asl
    tax
    lda screen_row_lo,x
    sta screen_ptr
    lda screen_row_hi,x
    sta screen_ptr+1
    lda color_row_lo,x
    sta color_ptr
    lda color_row_hi,x
    sta color_ptr+1
    lda #0
    sta tile_col
@column:
    ldx tile_map_index
    lda static_map,x
    asl
    asl
    tax

    ldy #0
    lda metatile_chars,x
    sta (screen_ptr),y
    lda metatile_colors,x
    sta (color_ptr),y
    inx
    iny
    lda metatile_chars,x
    sta (screen_ptr),y
    lda metatile_colors,x
    sta (color_ptr),y
    inx
    ldy #40
    lda metatile_chars,x
    sta (screen_ptr),y
    lda metatile_colors,x
    sta (color_ptr),y
    inx
    iny
    lda metatile_chars,x
    sta (screen_ptr),y
    lda metatile_colors,x
    sta (color_ptr),y

    inc screen_ptr
    inc screen_ptr
    inc color_ptr
    inc color_ptr
    inc tile_map_index
    inc tile_col
    lda tile_col
    cmp #20
    bne @column
    inc tile_row
    lda tile_row
    cmp #12
    bne @row
    rts

.segment "RODATA"
screen_row_lo:
    .repeat 24, row
        .byte <(SCREEN_A + row*40)
    .endrepeat
screen_row_hi:
    .repeat 24, row
        .byte >(SCREEN_A + row*40)
    .endrepeat
color_row_lo:
    .repeat 24, row
        .byte <(COLOR_RAM + row*40)
    .endrepeat
color_row_hi:
    .repeat 24, row
        .byte >(COLOR_RAM + row*40)
    .endrepeat
