.include "constants.inc"

.export vic_init, ui_update
.import charset_install, scroll_init
.import player_init, sprites_init, objects_sprite_init, game_init
.import frame_counter_lo, dropped_frames, score_lo, score_hi, lives, game_state
.import object_persistence, objects_collected
.import level_number
.import difficulty_rank_lo, boss_hp
.import continue_seconds
.import scroll_d016, visible_d018
.import sound_init
.import projectile_init
.import boss_attack_init
.import window_render_target
.import camera_pixel_lo, camera_pixel_hi, camera_char, rendered_camera_char
.import screen_a_char, screen_b_char, player_x_lo, player_x_hi
.import player_stance

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
    sta VIC_SPR_X_EXPAND
    sta VIC_SPR_Y_EXPAND
    lda CIA2_PORT_A
    and #%11111100
    ora #%00000010
    sta CIA2_PORT_A

    jsr charset_install
    jsr scroll_init
    jsr status_init
    jsr player_init
    lda #0
    jsr game_init
.ifdef PHASE12_PREVIEW
    ; Place the visual-inspection build in the final stage-rig section.
    lda #$A0                ; camera = 672 pixels, character column 84
    sta camera_pixel_lo
    lda #$02
    sta camera_pixel_hi
    lda #84
    sta camera_char
    sta rendered_camera_char
    sta screen_a_char
    sta screen_b_char
    lda #$00                ; player = 784 pixels in 12.4
    sta player_x_lo
    lda #$31
    sta player_x_hi
    lda #0
    sta player_stance
    lda #>SCREEN_A
    jsr window_render_target
    lda #>SCREEN_B
    jsr window_render_target
.endif
    jsr sprites_init
    jsr objects_sprite_init
    jsr projectile_init
    jsr boss_attack_init
    jsr sound_init
    lda visible_d018
    sta VIC_MEMPTR
    lda scroll_d016
    sta VIC_CTRL2
    lda #$1B
    sta VIC_CTRL1
    rts

status_init:
    ldx #0
@copy:
    lda status_text,x
    sta SCREEN_A+(24*40),x
    sta SCREEN_B+(24*40),x
    lda #COLOR_CYAN
    sta COLOR_RAM+(24*40),x
    inx
    cpx #40
    bne @copy
    rts

ui_update:
    lda score_hi
    jsr put_hex_score_hi
    lda score_lo
    jsr put_hex_score_lo
    lda lives
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+13
    sta SCREEN_B+(24*40)+13
    lda #0
    ldx #0
@clear_state:
    sta SCREEN_A+(24*40)+25,x
    sta SCREEN_B+(24*40)+25,x
    inx
    cpx #15
    bne @clear_state
    lda game_state
    cmp #GAME_CONTINUE
    bne @normal_header
    ldx #0
@continue:
    lda continue_text,x
    sta SCREEN_A+(24*40)+25,x
    sta SCREEN_B+(24*40)+25,x
    inx
    cpx #10
    bne @continue
    ldx continue_seconds
    lda hex_chars,x
    sta SCREEN_A+(24*40)+35
    sta SCREEN_B+(24*40)+35
    jmp @state_done
@normal_header:
    lda #12                ; L
    sta SCREEN_A+(24*40)+25
    sta SCREEN_B+(24*40)+25
    ldx level_number
    lda hex_chars,x
    sta SCREEN_A+(24*40)+26
    sta SCREEN_B+(24*40)+26
    lda #18                ; R = persistent danger rank
    sta SCREEN_A+(24*40)+27
    sta SCREEN_B+(24*40)+27
    lda difficulty_rank_lo
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+28
    sta SCREEN_B+(24*40)+28
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+29
    sta SCREEN_B+(24*40)+29
    lda game_state
    beq @play_state
    cmp #GAME_OVER
    beq @game_over_state
    cmp #GAME_LEVEL_CLEAR
    beq @level_clear_state
    cmp #GAME_COMPLETE
    beq @complete_state
    ldx #0
@loading:
    lda loading_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @loading
    jmp @state_done
@game_over_state:
    ldx #0
@game_over:
    lda game_over_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @game_over
    jmp @state_done
@level_clear_state:
    ldx #0
@level_clear:
    lda level_clear_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @level_clear
    jmp @state_done
@complete_state:
    ldx #0
@complete:
    lda complete_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @complete
    jmp @state_done
@play_state:
    lda object_persistence
    and #$0E
    cmp #$0E
    beq @exit_ready
    ldx #0
@items:
    lda items_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @items
    ldx objects_collected
    lda hex_chars,x
    sta SCREEN_A+(24*40)+36
    sta SCREEN_B+(24*40)+36
    jmp @state_done
@exit_ready:
    lda level_number
    cmp #2
    bne @exit
    lda object_persistence
    and #$40
    bne @exit
    ldx #0
@boss:
    lda boss_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @boss
    lda boss_hp
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+35
    sta SCREEN_B+(24*40)+35
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+36
    sta SCREEN_B+(24*40)+36
    jmp @state_done
@exit:
    ldx #0
@exit_loop:
    lda exit_text,x
    sta SCREEN_A+(24*40)+30,x
    sta SCREEN_B+(24*40)+30,x
    inx
    cpx #9
    bne @exit_loop
@state_done:
    lda frame_counter_lo
    jsr put_hex_frame
    lda dropped_frames
    jsr put_hex_drop
    rts

put_hex_score_hi:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+6
    sta SCREEN_B+(24*40)+6
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+7
    sta SCREEN_B+(24*40)+7
    rts

put_hex_score_lo:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+8
    sta SCREEN_B+(24*40)+8
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+9
    sta SCREEN_B+(24*40)+9
    rts

put_hex_frame:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+17
    sta SCREEN_B+(24*40)+17
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+18
    sta SCREEN_B+(24*40)+18
    rts

put_hex_drop:
    pha
    lsr
    lsr
    lsr
    lsr
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+22
    sta SCREEN_B+(24*40)+22
    pla
    and #$0F
    tax
    lda hex_chars,x
    sta SCREEN_A+(24*40)+23
    sta SCREEN_B+(24*40)+23
    rts

.segment "RODATA"
status_text:
    .byte 19,3,15,18,5,0,27,27,27,27,0,12,0,30,0
    .byte 6,0,27,27,0,4,0,27,27,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0
game_over_text:
    .byte 7,1,13,5,0,15,22,5,18
continue_text:
    .byte 3,15,14,20,9,14,21,5,39,0
level_clear_text:
    .byte 1,9,19,12,5,0,15,11,0     ; AISLE OK
loading_text:
    .byte 14,5,24,20,0,18,15,23,0    ; NEXT ROW
complete_text:
    .byte 20,1,12,11,18,5,1,4,25     ; TALKREADY
items_text:
    .byte 11,9,20,0,0,0,27,39,30     ; KIT   0:3
exit_text:
    .byte 20,15,0,19,20,1,7,5,0      ; TO STAGE
boss_text:
    .byte 1,22,0,2,15,19,19,0,0      ; AV BOSS
hex_chars:
    .byte 27,28,29,30,31,32,33,34,35,36,1,2,3,4,5,6
