.include "constants.inc"

.export input_update
.import joy_raw, joy_held, joy_previous, joy_pressed

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
    rts

