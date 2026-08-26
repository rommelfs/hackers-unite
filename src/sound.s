.include "constants.inc"

.export sound_init, sound_update
.export sfx_jump, sfx_pickup, sfx_enemy, sfx_damage, sfx_block, sfx_level_clear
.import sfx_timer, sfx_events, sfx_priority, sfx_suppressed, sfx_freq
.import music_timer, music_step, music_ticks, game_state, level_number

.segment "CODE"
sound_init:
    lda #0
    sta sfx_timer
    sta sfx_events
    sta sfx_priority
    sta sfx_suppressed
    sta sfx_freq
    sta music_step
    sta music_ticks
    lda #1
    sta music_timer
    ; PSID song 1 uses zero-based A=0 and a VBI/50 Hz play routine.
    lda #0
    tax
    tay
    jmp $1800

sound_update:
    ; The imported player advances exactly once per logical PAL frame.
    jsr $1806
    dec music_timer
    bne :+
    lda #12
    sta music_timer
    inc music_ticks
:
    lda sfx_timer
    beq @done
    jsr apply_sfx
    dec sfx_timer
    bne @done
    lda #0
    sta sfx_priority
@done:
    rts

sfx_jump:
    lda #$16
    ldx #6
    ldy #1
    bne play_tone
sfx_pickup:
    lda #$24
    ldx #10
    ldy #2
    bne play_tone
sfx_enemy:
    lda #$12
    ldx #12
    ldy #2
    bne play_tone
sfx_damage:
    lda #$08
    ldx #18
    ldy #3
    bne play_tone
sfx_block:
    lda #$1C
    ldx #8
    ldy #2
    bne play_tone
sfx_level_clear:
    lda #$32
    ldx #32
    ldy #4

; A = high frequency byte, X = PAL-frame duration, Y = priority.
play_tone:
    pha
    lda sfx_timer
    beq @accept
    tya
    cmp sfx_priority
    bcs @accept
    pla
    inc sfx_suppressed
    rts
@accept:
    pla
    sta sfx_freq
    stx sfx_timer
    sty sfx_priority
    inc sfx_events
    ; Events occur after sound_update in the frame, so make them audible now;
    ; following frames reassert voice 1 after the tune player has run.
apply_sfx:
    lda #$10
    sta SID_V1_CONTROL
    lda #0
    sta SID_V1_FREQ_LO
    lda sfx_freq
    sta SID_V1_FREQ_HI
    lda #$09
    sta SID_V1_AD
    lda #$F8
    sta SID_V1_SR
    lda #$11                ; triangle + gate
    sta SID_V1_CONTROL
    rts
