.include "constants.inc"

.export vic_init, ui_update
.import charset_install, tilemap_render
.import joy_held, frame_counter_lo, dropped_frames

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

    ; VIC bank 1: $4000-$7FFF. CIA bank bits are inverted.
    lda CIA2_PORT_A
    and #%11111100
    ora #%00000010
    sta CIA2_PORT_A

    ; Screen A at $4000, project-owned charset at $4800.
    lda #$02
    sta VIC_MEMPTR
    lda #$1B
    sta VIC_CTRL1
    lda #$18                ; 40 columns + multicolor character mode
    sta VIC_CTRL2

    jsr charset_install
    jsr tilemap_render
    jsr status_init
    rts

status_init:
    ldx #0
@copy:
    lda status_text,x
    sta SCREEN_A+(24*40),x
    lda #COLOR_CYAN
    sta COLOR_RAM+(24*40),x
    inx
    cpx #40
    bne @copy
    rts

; Preserve the static tilemap. Only the dedicated status row changes per frame.
ui_update:
    lda #40                 ; custom period glyph
    ldx #0
@clear_joy:
    sta SCREEN_A+(24*40)+21,x
    inx
    cpx #5
    bne @clear_joy

    lda joy_held
    and #JOY_UP
    beq :+
    lda #21                 ; U
    sta SCREEN_A+(24*40)+21
:
    lda joy_held
    and #JOY_DOWN
    beq :+
    lda #4                  ; D
    sta SCREEN_A+(24*40)+22
:
    lda joy_held
    and #JOY_LEFT
    beq :+
    lda #12                 ; L
    sta SCREEN_A+(24*40)+23
:
    lda joy_held
    and #JOY_RIGHT
    beq :+
    lda #18                 ; R
    sta SCREEN_A+(24*40)+24
:
    lda joy_held
    and #JOY_FIRE
    beq :+
    lda #6                  ; F
    sta SCREEN_A+(24*40)+25
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
    sta SCREEN_A+(24*40)+29
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+30
    rts

put_hex_drop:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+34
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+35
    rts

.segment "RODATA"
; Custom screen codes. A-Z are 1-26, digits are 27-36.
status_text:
    .byte 8,1,3,11,5,18,19,0,21,14,9,20,5,0
    .byte 16,29,0,10,15,25,0,40,40,40,40,40,0
    .byte 6,39,27,27,0,4,39,27,27,0,0,0,0,0
hex_chars:
    .byte 27,28,29,30,31,32,33,34,35,36,1,2,3,4,5,6

