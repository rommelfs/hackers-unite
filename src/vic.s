; Archived Phase-1 VIC/UI module. Phase 2 builds src/vic_phase2.s instead.
.include "constants.inc"

.export vic_init, ui_update
.import joy_held, joy_pressed, frame_counter_lo, dropped_frames

.segment "CODE"
vic_init:
    sei
    lda #COLOR_BLACK
    sta VIC_BORDER
    sta VIC_BG0
    lda #COLOR_DARK_GREY
    sta VIC_BG1
    lda #COLOR_LIGHT_BLUE
    sta VIC_BG2
    lda #0
    sta VIC_SPR_ENABLE

    ; VIC bank 1: $4000-$7FFF. CIA bits are inverted.
    lda CIA2_PORT_A
    and #%11111100
    ora #%00000010
    sta CIA2_PORT_A

    ; Copy the machine character ROM to private RAM at $4800.
    ; The finished PRG contains no copyrighted character data.
    lda CPU_PORT
    pha
    lda #$33
    sta CPU_PORT
    ldx #0
@copy_chars:
    lda $D000,x
    sta CHARSET_RAM,x
    lda $D100,x
    sta CHARSET_RAM+$100,x
    lda $D200,x
    sta CHARSET_RAM+$200,x
    lda $D300,x
    sta CHARSET_RAM+$300,x
    lda $D400,x
    sta CHARSET_RAM+$400,x
    lda $D500,x
    sta CHARSET_RAM+$500,x
    lda $D600,x
    sta CHARSET_RAM+$600,x
    lda $D700,x
    sta CHARSET_RAM+$700,x
    inx
    bne @copy_chars
    pla
    sta CPU_PORT

    lda #$20
    ldx #0
@clear_screen:
    sta SCREEN_A,x
    sta SCREEN_A+$100,x
    sta SCREEN_A+$200,x
    sta SCREEN_A+$300,x
    inx
    bne @clear_screen

    lda #COLOR_CYAN
    ldx #0
@clear_color:
    sta COLOR_RAM,x
    sta COLOR_RAM+$100,x
    sta COLOR_RAM+$200,x
    sta COLOR_RAM+$300,x
    inx
    bne @clear_color

    ; Screen A at $4000, character set at $4800.
    lda #$02
    sta VIC_MEMPTR
    lda #$1B
    sta VIC_CTRL1
    lda #$18                ; 40 columns + multicolor character mode
    sta VIC_CTRL2

    ldx #0
@title:
    lda title_text,x
    beq @title_done
    sta SCREEN_A+(3*40)+12,x
    lda #COLOR_WHITE
    sta COLOR_RAM+(3*40)+12,x
    inx
    bne @title
@title_done:
    ldx #0
@phase:
    lda phase_text,x
    beq @phase_done
    sta SCREEN_A+(6*40)+8,x
    inx
    bne @phase
@phase_done:
    ldx #0
@joy_label:
    lda joy_text,x
    beq @joy_done
    sta SCREEN_A+(11*40)+7,x
    inx
    bne @joy_label
@joy_done:
    ldx #0
@frame_label:
    lda frame_text,x
    beq @frame_done
    sta SCREEN_A+(16*40)+7,x
    inx
    bne @frame_label
@frame_done:
    rts

; Frame UI deliberately touches only a few fixed cells. No full-screen redraw.
ui_update:
    lda #46
    ldx #0
@clear_joy:
    sta SCREEN_A+(13*40)+10,x
    inx
    cpx #13
    bne @clear_joy

    lda joy_held
    and #JOY_UP
    beq :+
    lda #21
    sta SCREEN_A+(13*40)+10
:
    lda joy_held
    and #JOY_DOWN
    beq :+
    lda #4
    sta SCREEN_A+(13*40)+13
:
    lda joy_held
    and #JOY_LEFT
    beq :+
    lda #12
    sta SCREEN_A+(13*40)+16
:
    lda joy_held
    and #JOY_RIGHT
    beq :+
    lda #18
    sta SCREEN_A+(13*40)+19
:
    lda joy_held
    and #JOY_FIRE
    beq :+
    lda #6
    sta SCREEN_A+(13*40)+22
:
    lda frame_counter_lo
    jsr put_hex_frame
    lda dropped_frames
    jsr put_hex_drop
    rts

put_hex_frame:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(16*40)+14
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(16*40)+15
    rts

put_hex_drop:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(16*40)+24
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(16*40)+25
    rts

.segment "RODATA"
; Screen codes, not PETSCII.
title_text: .byte 8,1,3,11,5,18,19,32,21,14,9,20,5,0
phase_text: .byte 16,8,1,19,5,32,49,32,47,47,32,19,25,19,20,5,13,32,12,9,14,11,0
joy_text:   .byte 16,15,18,20,32,50,58,32,21,32,4,32,12,32,18,32,6,0
frame_text: .byte 6,18,1,13,5,58,32,48,48,32,32,4,18,15,16,58,32,48,48,0
hex_chars:  .byte 48,49,50,51,52,53,54,55,56,57,1,2,3,4,5,6
