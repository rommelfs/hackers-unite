.include "constants.inc"

.export finale_begin, finale_update, finale_render
.import game_state, finale_timer, finale_step, applause_events, joy_pressed
.import sprite_enable_shadow, sprite_msb_shadow, projectile_active, boss_shot_active
.import finale_script_pos, finale_terminal_row, finale_terminal_col, finale_script_done
.importzp screen_ptr
.import sfx_level_clear

TERM_LEFT = 5
TERM_INNER = 7
TERM_TOP = 4
TERM_FIRST_ROW = 8
TERM_WIDTH = 26
TERM_ROWS = 8

.segment "CODE3"
finale_begin:
    lda #0
    sta sprite_enable_shadow
    sta sprite_msb_shadow
    sta projectile_active
    sta boss_shot_active
    sta finale_step
    sta applause_events
    sta finale_script_pos
    sta finale_terminal_row
    sta finale_terminal_col
    sta finale_script_done
    lda #50
    sta finale_timer
    lda #GAME_FINALE_WALK
    sta game_state
    rts

finale_update:
    lda game_state
    cmp #GAME_FINALE_RESULT
    beq @result
    cmp #GAME_FINALE_DEMO
    bne :+
    jsr terminal_script_tick
:
    lda finale_timer
    beq @advance
    dec finale_timer
    rts
@advance:
    inc finale_step
    inc game_state
    lda game_state
    sec
    sbc #GAME_FINALE_WALK
    tax
    lda finale_durations,x
    sta finale_timer
    lda game_state
    cmp #GAME_FINALE_DEMO
    bne :+
    lda #0
    sta finale_script_pos
    sta finale_terminal_row
    sta finale_terminal_col
    sta finale_script_done
    jsr terminal_clear_text
:
    lda game_state
    cmp #GAME_FINALE_APPLAUSE
    bne :+
    inc applause_events
    jsr sfx_level_clear
:
    rts
@result:
    lda joy_pressed
    and #JOY_FIRE
    beq :+
    lda #GAME_COMPLETE
    sta game_state
:
    rts

; Render one monitor row per WALK frame. This bounds Screen A/B writes while the
; ending takes ownership from the scrolling playfield.
finale_render:
    lda game_state
    cmp #GAME_FINALE_WALK
    bne @screen
    lda finale_script_pos
    cmp #16
    bcs @walk_text
    jsr terminal_prepare_row
    inc finale_script_pos
    rts
@walk_text:
    ldx #0
@walk_copy:
    lda walk_line,x
    sta SCREEN_A+(12*40)+10,x
    sta SCREEN_B+(12*40)+10,x
    inx
    cpx #19
    bne @walk_copy
    rts

@screen:
    cmp #GAME_FINALE_SCREEN
    bne @demo
    ldx #0
@boot_copy:
    lda boot_title,x
    sta SCREEN_A+(7*40)+9,x
    sta SCREEN_B+(7*40)+9,x
    lda boot_kit,x
    sta SCREEN_A+(10*40)+9,x
    sta SCREEN_B+(10*40)+9,x
    inx
    cpx #19
    bne @boot_copy
    ldx #0
@entry_copy:
    lda boot_entry,x
    sta SCREEN_A+(13*40)+8,x
    sta SCREEN_B+(13*40)+8,x
    inx
    cpx #20
    bne @entry_copy
    ldx #0
@trigger_copy:
    lda boot_trigger,x
    sta SCREEN_A+(15*40)+15,x
    sta SCREEN_B+(15*40)+15,x
    inx
    cpx #10
    bne @trigger_copy
    rts

@demo:
    cmp #GAME_FINALE_DEMO
    bne @applause
    jsr terminal_cursor
    rts
@applause:
    cmp #GAME_FINALE_APPLAUSE
    bne @result_screen
    ldx #0
@open_copy:
    lda system_open,x
    sta SCREEN_A+(17*40)+14,x
    sta SCREEN_B+(17*40)+14,x
    inx
    cpx #11
    bne @open_copy
    lda finale_timer
    and #8
    lsr
    lsr
    lsr
    clc
    adc #69
    ldx #0
@audience:
    sta SCREEN_A+(18*40)+16,x
    sta SCREEN_B+(18*40)+16,x
    inx
    cpx #8
    bne @audience
    jsr terminal_cursor
    rts
@result_screen:
    ldx #0
@result_copy:
    lda result_line,x
    sta SCREEN_A+(11*40)+10,x
    sta SCREEN_B+(11*40)+10,x
    inx
    cpx #20
    bne @result_copy
    rts

terminal_prepare_row:
    tax
    lda terminal_row_lo,x
    sta screen_ptr
    lda terminal_row_hi,x
    sta screen_ptr+1
    txa
    beq @solid
    cmp #15
    beq @solid
    ldy #0
    lda #35
    sta (screen_ptr),y
    ldy #29
    sta (screen_ptr),y
    lda #0
    ldy #1
@inside:
    sta (screen_ptr),y
    iny
    cpy #29
    bne @inside
    jmp @copy_b
@solid:
    ldy #0
    lda #35
@solid_loop:
    sta (screen_ptr),y
    iny
    cpy #30
    bne @solid_loop
@copy_b:
    ; Copy the completed 30-character row from Screen A to Screen B.
    lda terminal_row_lo,x
    sta screen_ptr
    lda terminal_row_hi,x
    sta screen_ptr+1
    ldy #0
@mirror:
    lda (screen_ptr),y
    pha
    lda screen_ptr+1
    clc
    adc #4
    sta screen_ptr+1
    pla
    sta (screen_ptr),y
    lda screen_ptr+1
    sec
    sbc #4
    sta screen_ptr+1
    iny
    cpy #30
    bne @mirror
    rts

terminal_script_tick:
    lda finale_script_done
    bne @done
    ldx finale_script_pos
    lda terminal_script,x
    cmp #$FE
    beq @finish
    cmp #$FF
    beq @newline
    jsr terminal_put_char
    inc finale_terminal_col
    inc finale_script_pos
    lda finale_terminal_col
    cmp #TERM_WIDTH
    bcc @done
@newline:
    inc finale_script_pos
    lda #0
    sta finale_terminal_col
    inc finale_terminal_row
    lda finale_terminal_row
    cmp #TERM_ROWS
    bcc @done
    jsr terminal_scroll
    lda #(TERM_ROWS-1)
    sta finale_terminal_row
    rts
@finish:
    lda #1
    sta finale_script_done
@done:
    rts

terminal_put_char:
    pha
    ldx finale_terminal_row
    lda terminal_text_lo,x
    sta screen_ptr
    lda terminal_text_hi,x
    sta screen_ptr+1
    ldy finale_terminal_col
    pla
    sta (screen_ptr),y
    pha
    lda screen_ptr+1
    clc
    adc #4
    sta screen_ptr+1
    pla
    sta (screen_ptr),y
    rts

terminal_cursor:
    ldx finale_terminal_row
    lda terminal_text_lo,x
    sta screen_ptr
    lda terminal_text_hi,x
    sta screen_ptr+1
    ldy finale_terminal_col
    lda finale_timer
    and #8
    beq :+
    lda #100               ; filled cursor glyph
    bne :++
:
    lda #0
:
    sta (screen_ptr),y
    pha
    lda screen_ptr+1
    clc
    adc #4
    sta screen_ptr+1
    pla
    sta (screen_ptr),y
    rts

terminal_scroll:
    ldx #0
@column:
    .repeat 7, row
        lda SCREEN_A+((TERM_FIRST_ROW+row+1)*40)+TERM_INNER,x
        sta SCREEN_A+((TERM_FIRST_ROW+row)*40)+TERM_INNER,x
        lda SCREEN_B+((TERM_FIRST_ROW+row+1)*40)+TERM_INNER,x
        sta SCREEN_B+((TERM_FIRST_ROW+row)*40)+TERM_INNER,x
    .endrepeat
    lda #0
    sta SCREEN_A+((TERM_FIRST_ROW+7)*40)+TERM_INNER,x
    sta SCREEN_B+((TERM_FIRST_ROW+7)*40)+TERM_INNER,x
    inx
    cpx #TERM_WIDTH
    bne @column
    rts

terminal_clear_text:
    ldx #0
@column:
    lda #0
    .repeat TERM_ROWS, row
        sta SCREEN_A+((TERM_FIRST_ROW+row)*40)+TERM_INNER,x
        sta SCREEN_B+((TERM_FIRST_ROW+row)*40)+TERM_INNER,x
    .endrepeat
    inx
    cpx #TERM_WIDTH
    bne @column
    rts

.segment "RODATA"
finale_durations: .byte 50, 100, 250, 100, 0
walk_line:    .byte 1,16,16,18,15,1,3,8,9,14,7,0,12,5,3,20,5,18,14
boot_title:   .byte 8,1,3,11,46,12,21,0,19,20,1,7,5,0,19,8,5,12,12
boot_kit:     .byte 12,9,14,11,9,14,7,0,19,16,5,1,11,5,18,0,11,9,20
boot_entry:   .byte 5,14,20,18,25,0,15,11,0,0,16,1,25,12,15,1,4,0,15,11
boot_trigger: .byte 20,18,9,7,7,5,18,0,15,11
system_open:  .byte 19,25,19,20,5,13,0,15,16,5,14
result_line:  .byte 20,1,12,11,0,3,15,13,16,12,5,20,5,0,0,6,9,18,5,0
terminal_script:
    ; Fictional ROOT@STAGE prompt only: no real target, exploit or command.
    .byte 36,0,16,15,3,45,18,21,14,0,16,18,15,4,21,3,20,45,24,$FF
    .byte 15,11,0,15,16,5,14,9,14,7,0,4,5,13,15,0,12,9,14,11,$FF
    .byte 15,11,0,19,20,1,7,9,14,7,0,5,14,20,18,25,$FF
    .byte 15,11,0,13,1,16,16,9,14,7,0,16,1,25,12,15,1,4,$FF
    .byte 55,5,0,50,48,0,50,54,0,48,48,0,19,9,7,14,1,12,$FF
    .byte 1,57,0,48,50,0,56,4,0,50,49,0,19,25,19,20,5,13,$FF
    .byte 15,11,0,1,18,13,9,14,7,0,20,18,9,7,7,5,18,$FF
    .byte 18,21,14,0,5,24,5,3,21,20,9,14,7,46,46,46,$FF
    .byte 15,11,0,6,9,3,20,9,15,14,1,12,0,19,8,5,12,12,0,15,16,5,14,$FF
    .byte 18,15,15,20,64,19,20,1,7,5,58,35,0,$FE

terminal_row_lo:
    .repeat 16, row
        .byte <(SCREEN_A+((TERM_TOP+row)*40)+TERM_LEFT)
    .endrepeat
terminal_row_hi:
    .repeat 16, row
        .byte >(SCREEN_A+((TERM_TOP+row)*40)+TERM_LEFT)
    .endrepeat
terminal_text_lo:
    .repeat TERM_ROWS, row
        .byte <(SCREEN_A+((TERM_FIRST_ROW+row)*40)+TERM_INNER)
    .endrepeat
terminal_text_hi:
    .repeat TERM_ROWS, row
        .byte >(SCREEN_A+((TERM_FIRST_ROW+row)*40)+TERM_INNER)
    .endrepeat
