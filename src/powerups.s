.include "constants.inc"

.export powerups_update, powerups_reset, powerup_collect
.import game_state, object_index, lives
.import power_weapon, rapid_timer, strong_timer, speed_timer, power_flash
.import powerups_collected, extra_lives_collected, powerups_expired
.import add_score

.segment "CODE3"
powerups_reset:
    lda #0
    sta power_weapon
    sta rapid_timer
    sta strong_timer
    sta speed_timer
    sta power_flash
    rts

powerups_update:
    lda game_state
    beq :+
    rts
:
    lda power_flash
    beq :+
    dec power_flash
:
    ldx #0
    lda rapid_timer
    beq @strong
    dec rapid_timer
    bne @strong
    inc powerups_expired
@strong:
    lda strong_timer
    beq @speed
    dec strong_timer
    bne @speed
    inc powerups_expired
@speed:
    lda speed_timer
    beq @weapon
    dec speed_timer
    bne @weapon
    inc powerups_expired
@weapon:
    lda strong_timer
    beq :+
    lda #POWER_STRONG
    bne @store
:
    lda rapid_timer
    beq :+
    lda #POWER_RAPID
    bne @store
:
    lda #POWER_NONE
@store:
    sta power_weapon
    rts

; Stable IDs are the definition: 1 rapid, 2 strong, 3 speed, 4 extra life.
; Layout tables decide which of these bounded objects exist in each section.
powerup_collect:
    inc powerups_collected
    lda #12
    sta power_flash
    ldx object_index
    dex
    tax
    lda powerup_types,x
    cmp #POWER_EXTRA_LIFE
    beq @life
    cmp #POWER_RAPID
    beq @rapid
    cmp #POWER_STRONG
    beq @strong
    lda #POWER_DURATION
    sta speed_timer
    lda #25
    jmp add_score
@rapid:
    sta power_weapon
    lda #POWER_DURATION
    sta rapid_timer
    lda #25
    jmp add_score
@strong:
    sta power_weapon
    lda #POWER_DURATION
    sta strong_timer
    lda #25
    jmp add_score
@life:
    inc lives
    inc extra_lives_collected
    lda #100
    jmp add_score

.segment "RODATA"
powerup_types:
    .byte POWER_RAPID, POWER_STRONG, POWER_SPEED, POWER_EXTRA_LIFE
