.include "constants.inc"

.export input_update
.import joy_raw, joy_held, joy_previous, joy_pressed
.import cheat_held, cheat_previous, cheat_pressed

.segment "CODE"
input_update:
    lda joy_held
    sta joy_previous
    lda CIA1_PORT_A
    sta joy_raw
    eor #$FF
    and #$1F
    sta joy_held

    ; Opposing directions resolve to neutral deterministically.
    and #(JOY_LEFT | JOY_RIGHT)
    cmp #(JOY_LEFT | JOY_RIGHT)
    bne :+
    lda joy_held
    and #$F3
    sta joy_held
:
    lda joy_held
    and #(JOY_UP | JOY_DOWN)
    cmp #(JOY_UP | JOY_DOWN)
    bne :+
    lda joy_held
    and #$FC
    sta joy_held
:
    lda joy_previous
    eor #$FF
    and joy_held
    sta joy_pressed

    ; Direct matrix scan for the standalone Commodore-key development shortcut.
    ; Preserve both CIA directions and port A so joystick sampling and KERNAL
    ; assumptions remain unchanged outside this bounded scan.
    lda cheat_held
    sta cheat_previous
    lda CIA1_DDRA
    pha
    lda CIA1_DDRB
    pha
    lda CIA1_PORT_A
    pha
    lda #$FF
    sta CIA1_DDRA
    lda #0
    sta CIA1_DDRB
    lda #COMMODORE_COLUMN
    sta CIA1_PORT_A
    lda CIA1_PORT_B
    eor #$FF
    and #COMMODORE_MASK
    beq :+
    lda #1
:
    sta cheat_held
    pla
    sta CIA1_PORT_A
    pla
    sta CIA1_DDRB
    pla
    sta CIA1_DDRA
    lda cheat_previous
    eor #$FF
    and cheat_held
    sta cheat_pressed
    rts
