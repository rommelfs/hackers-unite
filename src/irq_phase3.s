.include "constants.inc"

.export irq_init, raster_irq
.importzp frame_pending
.import frame_counter_lo, frame_counter_hi, dropped_frames, main_busy
.import irq_phase, scroll_d016, visible_d018
.import sprite_xy_shadow, sprite_enable_shadow, sprite_msb_shadow

RASTER_PLAYFIELD = 48
RASTER_STATUS    = 240

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
    lda #0
    sta irq_phase
    lda #RASTER_PLAYFIELD
    sta VIC_RASTER
    lda VIC_CTRL1
    and #$7F
    sta VIC_CTRL1
    lda #$01
    sta VIC_IRQ_FLAGS
    sta VIC_IRQ_ENABLE
    rts

; Two deterministic splits: scrolling playfield and fixed status line.
raster_irq:
    lda #$01
    sta VIC_IRQ_FLAGS
    lda irq_phase
    bne @status

@playfield:
    lda visible_d018
    sta VIC_MEMPTR
    lda scroll_d016
    sta VIC_CTRL2
    ldx #0
@sprite_publish:
    lda sprite_xy_shadow,x
    sta VIC_SPR0_X,x
    inx
    cpx #16
    bne @sprite_publish
    lda sprite_msb_shadow
    sta VIC_SPR_X_MSB
    lda sprite_enable_shadow
    sta VIC_SPR_ENABLE
    lda #RASTER_STATUS
    sta VIC_RASTER
    lda #1
    sta irq_phase
    ; Publish one logical frame immediately after the coherent playfield state.
    ; Main-loop work now has a complete PAL frame before the next line-48 flip.
    inc frame_counter_lo
    bne :+
    inc frame_counter_hi
:
    lda main_busy
    bne @drop
    lda frame_pending
    beq @queue
@drop:
    inc dropped_frames
    jmp KERNAL_IRQ_EXIT
@queue:
    inc frame_pending
    jmp KERNAL_IRQ_EXIT

@status:
    lda #$18                ; MCM, 40 columns, fine position 0
    sta VIC_CTRL2
    lda #RASTER_PLAYFIELD
    sta VIC_RASTER
    lda #0
    sta irq_phase
    jmp KERNAL_IRQ_EXIT
