.include "constants.inc"

.export irq_init
.export raster_irq
.importzp frame_pending
.import frame_counter_lo, frame_counter_hi, dropped_frames

.segment "CODE"
irq_init:
    sei
    lda #$7F
    sta CIA1_ICR
    sta CIA2_ICR
    lda CIA1_ICR
    lda CIA2_ICR

    lda #<raster_irq
    sta KERNAL_IRQ_VEC
    lda #>raster_irq
    sta KERNAL_IRQ_VEC+1

    lda #250
    sta VIC_RASTER
    lda VIC_CTRL1
    and #$7F
    sta VIC_CTRL1
    lda #$01
    sta VIC_IRQ_FLAGS
    sta VIC_IRQ_ENABLE
    rts

; KERNAL has already saved A/X/Y before dispatching through $0314.
raster_irq:
    lda #$01
    sta VIC_IRQ_FLAGS
    inc frame_counter_lo
    bne :+
    inc frame_counter_hi
:
    lda frame_pending
    beq @queue
    inc dropped_frames
    jmp KERNAL_IRQ_EXIT
@queue:
    inc frame_pending
    jmp KERNAL_IRQ_EXIT

