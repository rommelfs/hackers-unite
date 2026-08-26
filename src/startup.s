.include "constants.inc"

.export _start
.import vic_init, irq_init, frame_loop
.importzp screen_ptr, color_ptr
.import __BSS_RUN__, __BSS_SIZE__

.segment "LOADADDR"
    .word $0801

.segment "BASIC"
    .word basic_end
    .word 2026
    .byte $9E
    .byte "2061", 0
basic_end:
    .word 0

.segment "STARTUP"
_start:
    sei
    cld
    ldx #$FF
    txs
    lda #$36                ; BASIC ROM out; KERNAL and I/O remain visible
    sta CPU_PORT

    ; Deterministic 16-bit BSS initialization, safe beyond one page.
    lda #<__BSS_RUN__
    sta screen_ptr
    lda #>__BSS_RUN__
    sta screen_ptr+1
    lda #<__BSS_SIZE__
    sta color_ptr
    lda #>__BSS_SIZE__
    sta color_ptr+1
    ldx #0
@clear_bss:
    lda color_ptr
    ora color_ptr+1
    beq @bss_done
    txa
    ldy #0
    sta (screen_ptr),y
    inc screen_ptr
    bne :+
    inc screen_ptr+1
:
    lda color_ptr
    bne :+
    dec color_ptr+1
:
    dec color_ptr
    jmp @clear_bss
@bss_done:
    jsr vic_init
    jsr irq_init
    cli
    jmp frame_loop
