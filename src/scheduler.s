.include "constants.inc"

.export frame_loop
.importzp frame_pending
.import input_update, ui_update

.ifdef AUTOTEST
.import frame_counter_lo
.endif

.segment "CODE"
frame_loop:
@wait:
    sei
    lda frame_pending
    beq @not_ready
    dec frame_pending
    cli

.ifdef DEBUG_BUILD
    lda #COLOR_PURPLE
    sta VIC_BORDER
.endif
    jsr input_update
.ifdef DEBUG_BUILD
    lda #COLOR_BLUE
    sta VIC_BORDER
.endif
    jsr ui_update
.ifdef DEBUG_BUILD
    lda #COLOR_BLACK
    sta VIC_BORDER
.endif

.ifdef AUTOTEST
    lda frame_counter_lo
    cmp #64
    bcc @wait
    lda #0
    sta $D7FF
@autotest_halt:
    jmp @autotest_halt
.endif
    jmp @wait

@not_ready:
    cli
    jmp @wait
