.include "constants.inc"

.export finale_begin, finale_update, finale_render
.import game_state, finale_timer, finale_step, applause_events, joy_pressed
.import sprite_enable_shadow, sprite_msb_shadow, projectile_active, boss_shot_active
.import sfx_level_clear

.segment "CODE3"
finale_begin:
    lda #0
    sta sprite_enable_shadow
    sta sprite_msb_shadow
    sta projectile_active
    sta boss_shot_active
    sta finale_step
    lda #50
    sta finale_timer
    lda #GAME_FINALE_WALK
    sta game_state
    rts

finale_update:
    lda game_state
    cmp #GAME_FINALE_RESULT
    beq @result
    lda finale_timer
    beq @advance
    dec finale_timer
    rts
@advance:
    inc finale_step
    inc game_state
    lda #75
    sta finale_timer
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

; The ending owns a terminal-shaped region in both cached screens. Gameplay is
; frozen, so these bounded writes cannot race the scrolling renderer.
finale_render:
    lda game_state
    sec
    sbc #GAME_FINALE_WALK
    asl
    asl
    asl
    tax
    ldy #0
@line:
    lda finale_lines,x
    sta SCREEN_A+(10*40)+12,y
    sta SCREEN_B+(10*40)+12,y
    inx
    iny
    cpy #8
    bne @line
    lda game_state
    cmp #GAME_FINALE_APPLAUSE
    bcc @result_check
    lda finale_timer
    and #8
    lsr
    lsr
    lsr
    clc
    adc #69                 ; audience heads alternate between both owned glyphs
    ldx #0
@audience:
    sta SCREEN_A+(17*40)+16,x
    sta SCREEN_B+(17*40)+16,x
    inx
    cpx #8
    bne @audience
@result_check:
    lda game_state
    cmp #GAME_FINALE_RESULT
    bne :+
    ldx #0
@result_line:
    lda result_line,x
    sta SCREEN_A+(14*40)+10,x
    sta SCREEN_B+(14*40)+10,x
    inx
    cpx #20
    bne @result_line
:
    rts

.segment "RODATA"
finale_lines:
    .byte 20,15,0,12,5,3,20,18       ; TO LECTR
    .byte 16,18,15,10,0,15,14,0      ; PROJ ON
    .byte 5,14,20,18,25,30,30,30     ; ENTRY...
    .byte 1,3,3,5,19,19,0,7          ; ACCESS G
    .byte 1,16,16,12,1,21,19,5       ; APPLAUSE
result_line:
    .byte 20,1,12,11,0,3,15,13,16,12,5,20,5,0,0,6,9,18,5,0
