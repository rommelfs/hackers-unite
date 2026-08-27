.include "constants.inc"

.export objects_init, objects_update, objects_sprite_init, objects_test_enemy_collision
.export objects_projectile_hit
.export objects_test_boss_update
.import object_sprite_data, boss_sprite_data
.import action_sprite_data
.import camera_pixel_lo, camera_pixel_hi, frame_counter_lo
.import player_x_lo, player_x_hi, player_y_lo, player_y_hi, player_vy
.import player_airborne_entry
.import object_x_lo, object_x_hi, object_y, object_active
.import object_persistence, object_ever_active, enemy_direction
.import object_temp_lo, object_temp_hi, object_index, object_enable_mask, object_msb_mask
.import objects_activated, objects_collected, enemy_defeats, enemies_present
.import score_lo, score_hi, lives, game_state
.import level_number
.import difficulty_rank_lo, difficulty_rank_hi
.import boss_hp, boss_invuln, boss_hits, boss_defeats
.import falling_drops, rolling_cycles, action_hits, damage_cooldown
.import falling_warning_timer
.import boss_attack_reset
.import player_damage, add_score
.import sprite_xy_shadow, sprite_enable_shadow, sprite_msb_shadow
.import sfx_pickup, sfx_enemy
.import projectile_x_lo, projectile_x_hi, projectile_y
.import powerup_collect
.import strong_timer

OBJECT_COUNT = 7
TYPE_ENEMY = 0
TYPE_KEY = 1
TYPE_BONUS = 2
TYPE_ONEUP = 3
TYPE_POWER = 4

.segment "CODE"
objects_sprite_init:
    ldx #0
@copy:
    lda object_sprite_data,x
    sta SPRITE_RAM+$100,x
    inx
    bne @copy
    lda #$FF
    sta VIC_SPR_MC
    ldx #0
@copy_boss:
    lda boss_sprite_data,x
    sta SPRITE_RAM+$400,x
    inx
    cpx #64
    bne @copy_boss
    ldx #0
@copy_actions:
    lda action_sprite_data,x
    sta SPRITE_RAM+$440,x
    lda action_sprite_data+$40,x
    sta SPRITE_RAM+$480,x
    inx
    cpx #64
    bne @copy_actions
    rts

objects_init:
    lda #0
    sta object_persistence
    sta object_ever_active
    sta objects_activated
    sta objects_collected
    sta enemy_defeats
    sta boss_hp
    sta boss_invuln
    jsr boss_attack_reset
    ldx #OBJECT_COUNT-1
@copy:
    lda level_number
    cmp #3
    beq @level_three
    cmp #2
    bne @level_one
    lda object_level2_x_lo,x
    sta object_x_lo,x
    lda object_level2_x_hi,x
    jmp @store_x_hi
@level_three:
    lda object_level3_x_lo,x
    sta object_x_lo,x
    lda object_level3_x_hi,x
    jmp @store_x_hi
@level_one:
    lda object_initial_x_lo,x
    sta object_x_lo,x
    lda object_initial_x_hi,x
@store_x_hi:
    sta object_x_hi,x
    lda level_number
    cmp #3
    beq @level_three_y
    cmp #2
    bne :+
    lda object_level2_y,x
    jmp @store_y
@level_three_y:
    lda object_level3_y,x
    jmp @store_y
:
    lda object_initial_y,x
@store_y:
    sta object_y,x
    lda #0
    sta object_active,x
    lda #1
    sta enemy_direction,x
    dex
    bpl @copy
    lda #50                 ; overhead warning before the first material drop
    sta falling_warning_timer
    lda level_number
    cmp #2
    bne @not_level_two_count
    lda difficulty_rank_hi
    bne @max_boss_hp
    lda difficulty_rank_lo
    clc
    adc #7
    bcc @store_boss_hp
@max_boss_hp:
    lda #$FF
@store_boss_hp:
    sta boss_hp
    lda #4
    bne @store_enemy_count
@not_level_two_count:
    cmp #3
    bne :+
    lda #4                  ; two enemies plus two action hazards
    bne @store_enemy_count
:
    lda difficulty_rank_lo
    cmp #2
    bcc :+
    lda #3                  ; later Level-1 cycles add the flying patrol
    bne @store_enemy_count
:
    lda #2
@store_enemy_count:
    sta enemies_present
    rts

objects_update:
    lda boss_invuln
    beq :+
    dec boss_invuln
:
    lda VIC_SPR_X_EXPAND
    and #$7F
    sta VIC_SPR_X_EXPAND
    lda VIC_SPR_Y_EXPAND
    and #$7F
    sta VIC_SPR_Y_EXPAND
    lda game_state
    bne @hide_all
    lda #$01
    sta object_enable_mask
    lda sprite_msb_shadow
    and #$01
    sta object_msb_mask
    ldx #0
@object:
    stx object_index
    jsr object_activate
    lda object_active,x
    beq @next
    lda object_bits,x
    and object_persistence
    bne @sleep
    jsr object_type_for_level
    cmp #TYPE_ENEMY
    bne :+
    jsr enemy_update
:
    ldx object_index
    lda level_number
    cmp #3
    bne :+
    cpx #5
    bne :+
    lda object_y,x
    beq @next               ; warning phase has no sprite and no collision box
:
    jsr object_collide
    lda game_state
    bne @hide_all
    ldx object_index
    jsr object_render
    jmp @next
@sleep:
    lda #0
    sta object_active,x
@next:
    inx
    cpx #OBJECT_COUNT
    bne @object
    lda object_enable_mask
    sta sprite_enable_shadow
    lda object_msb_mask
    sta sprite_msb_shadow
    rts
@hide_all:
    lda game_state
    cmp #GAME_BRIEFING
    bne :+
    lda #0                  ; the title/briefing owns the complete playfield
    sta sprite_enable_shadow
    sta sprite_msb_shadow
    rts
:
    lda #$01
    sta sprite_enable_shadow
    lda sprite_msb_shadow
    and #$01
    sta sprite_msb_shadow
    rts

; Active range is camera -32 through camera +351 pixels.
object_activate:
    lda level_number
    cmp #3
    beq :+
    cmp #2
    beq :+
    lda difficulty_rank_lo
    cmp #2
    bcc @level1_base
    cpx #6                  ; harder cycles wake the drone, never the boss.
    bcc :+
    jmp @inactive
@level1_base:
    cpx #5
    bcc :+
    jmp @inactive
:
    lda object_x_lo,x
    sec
    sbc camera_pixel_lo
    sta object_temp_lo
    lda object_x_hi,x
    sbc camera_pixel_hi
    sta object_temp_hi
    beq @active
    cmp #1
    bne @negative
    lda object_temp_lo
    cmp #96
    bcs @inactive
    bcc @active
@negative:
    cmp #$FF
    bne @inactive
    lda object_temp_lo
    cmp #224
    bcc @inactive
@active:
    lda object_active,x
    bne enemy_update_done
    lda #1
    sta object_active,x
    lda object_bits,x
    and object_ever_active
    bne @done
    lda object_bits,x
    ora object_ever_active
    sta object_ever_active
    inc objects_activated
@done:
    rts
@inactive:
    lda #0
    sta object_active,x
    rts

enemy_update:
    lda level_number
    cmp #3
    bne @standard_enemy
    cpx #5
    beq falling_material_update
    cpx #6
    bne @standard_enemy
    jmp rolling_ball_update
@standard_enemy:
    cpx #5
    bne @not_drone
    lda frame_counter_lo
    and #3
    bne @move
    lda frame_counter_lo
    and #$10
    beq :+
    dec object_y,x
    bne @move
:
    inc object_y,x
@not_drone:
    cpx #6
    bne :+
    jmp boss_update
:
@normal_speed:
    cpx #5
    bcs @move               ; Drone always moves.
    lda difficulty_rank_lo
    cmp #2
    bcs @move               ; Later cycles wake every patrol each frame.
    lda frame_counter_lo
    and #1
    bne enemy_update_done
@move:
    jsr enemy_patrol_step
    lda difficulty_rank_lo
    cmp #4
    bcc enemy_update_done
    jsr enemy_patrol_step
    lda difficulty_rank_lo
    cmp #8
    bcc enemy_update_done
    jmp enemy_patrol_step

enemy_update_done:
    rts

falling_material_update:
    lda falling_warning_timer
    beq @drop_active
    dec falling_warning_timer
    lda #0
    sta object_y,x
    rts
@drop_active:
    lda object_y,x
    bne :+
    lda #16
    sta object_y,x
    rts
:
    clc
    adc #3
    cmp #140
    bcc :+
    lda #50
    sta falling_warning_timer
    lda #0
    inc falling_drops
    inc enemy_direction,x
    pha
    lda enemy_direction,x
    cmp #3
    bcc @fall_lane_ready
    lda #0
    sta enemy_direction,x
@fall_lane_ready:
    tay
    lda falling_lane_x_lo,y
    sta object_x_lo,x
    lda falling_lane_x_hi,y
    sta object_x_hi,x
    pla
:
    sta object_y,x
    rts

rolling_ball_update:
    lda object_x_lo,x
    sec
    sbc #2
    sta object_x_lo,x
    bcs :+
    dec object_x_hi,x
:
    lda difficulty_rank_lo
    cmp #4
    bcc @rolling_bounds
    lda object_x_lo,x
    bne :+
    dec object_x_hi,x
:
    dec object_x_lo,x
@rolling_bounds:
    lda object_x_hi,x
    bne @rolling_done
    lda object_x_lo,x
    cmp #64
    bcs @rolling_done
    lda #<900
    sta object_x_lo,x
    lda #>900
    sta object_x_hi,x
    inc rolling_cycles
@rolling_done:
    rts

enemy_patrol_step:
    lda enemy_direction,x
    bmi @left
    inc object_x_lo,x
    bne :+
    inc object_x_hi,x
:
    jsr load_enemy_right_bound
    lda object_x_hi,x
    cmp object_temp_hi
    bcc @done
    bne @turn_left
    lda object_x_lo,x
    cmp object_temp_lo
    bcc @done
@turn_left:
    lda #$FF
    sta enemy_direction,x
    rts
@left:
    lda object_x_lo,x
    bne :+
    dec object_x_hi,x
:
    dec object_x_lo,x
    jsr load_enemy_left_bound
    lda object_x_hi,x
    cmp object_temp_hi
    bcc @turn_right
    bne @done
    lda object_x_lo,x
    cmp object_temp_lo
    bcc @turn_right
    bne @done
@turn_right:
    lda #1
    sta enemy_direction,x
@done:
    rts

; Level-2 ID 6 is a large, persistent boss. It patrols its authored arena
; independently instead of magnetically replacing its direction from the
; player's position every frame. Rank and rage only change the bounded pace.
boss_update:
objects_test_boss_update = boss_update
    lda difficulty_rank_lo
    cmp #4
    bcs @choose_steps
    lda boss_hp
    cmp #4
    bcc @choose_steps
    lda frame_counter_lo
    and #1
    bne @boss_done          ; readable half-speed patrol in early encounters
@choose_steps:
    ldy #1
    lda difficulty_rank_lo
    cmp #10
    bcc :+
    iny
:
    lda boss_hp
    cmp #4
    bcs @step
    iny                     ; Rage phase below four hit points.
@step:
    jsr enemy_patrol_step
    dey
    bne @step
@boss_done:
    rts

load_enemy_right_bound:
    lda level_number
    cmp #3
    bne :+
    lda enemy_right_l3_lo,x
    sta object_temp_lo
    lda enemy_right_l3_hi,x
    sta object_temp_hi
    rts
:
    cmp #2
    bne :+
    lda enemy_right_l2_lo,x
    sta object_temp_lo
    lda enemy_right_l2_hi,x
    sta object_temp_hi
    rts
:
    lda enemy_right_l1_lo,x
    sta object_temp_lo
    lda enemy_right_l1_hi,x
    sta object_temp_hi
    rts

load_enemy_left_bound:
    lda level_number
    cmp #3
    bne :+
    lda enemy_left_l3_lo,x
    sta object_temp_lo
    lda enemy_left_l3_hi,x
    sta object_temp_hi
    rts
:
    cmp #2
    bne :+
    lda enemy_left_l2_lo,x
    sta object_temp_lo
    lda enemy_left_l2_hi,x
    sta object_temp_hi
    rts
:
    lda enemy_left_l1_lo,x
    sta object_temp_lo
    lda enemy_left_l1_hi,x
    sta object_temp_hi
    rts

; Software AABB test. Player and objects keep fixed boxes independent of art.
object_collide:
    ; Convert player 12.4 X to integer and subtract object X.
    lda player_x_lo
    lsr
    lsr
    lsr
    lsr
    sta object_temp_lo
    lda player_x_hi
    asl
    asl
    asl
    asl
    ora object_temp_lo
    sec
    sbc object_x_lo,x
    sta object_temp_lo
    lda player_x_hi
    lsr
    lsr
    lsr
    lsr
    sbc object_x_hi,x
    beq @x_positive
    cmp #$FF
    beq :+
    rts
:
    lda object_temp_lo
    eor #$FF
    clc
    adc #1
    jmp @x_distance
@x_positive:
    lda object_temp_lo
@x_distance:
    sta object_temp_lo
    cpx #6
    bne @normal_x_box
    lda level_number
    cmp #2
    bne @normal_x_box
    lda object_temp_lo
    cmp #36
    bcc @x_hit
    rts
@normal_x_box:
    lda object_temp_lo
    cmp #18
    bcc :+
    rts
:
@x_hit:
    ; The expanded Level-2 boss needs a real vertical body intersection.
    ; A broad absolute distance lets a player standing on the platform above
    ; damage it despite the clear gap between both software boxes.
    cpx #6
    bne @normal_y_box
    lda level_number
    cmp #2
    beq @boss_player_y_box
@normal_y_box:

    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta object_temp_lo
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora object_temp_lo
    sec
    sbc object_y,x
    bcs :+
    eor #$FF
    clc
    adc #1
:
    sta object_temp_lo
    jsr object_type_for_level
    tay
    cpy #TYPE_ENEMY
    bne @item_y
    lda object_temp_lo
    cmp #30
    bcs :+
    jmp @enemy
:
    rts
@item_y:
    cmp #21
    bcc :+
    rts
:

    lda object_bits,x
    ora object_persistence
    sta object_persistence
    inc objects_collected
    jsr sfx_pickup
    jsr object_type_for_level
    cmp #TYPE_KEY
    bne @bonus
    lda #10
    jsr add_score
    rts
@bonus:
    cmp #TYPE_BONUS
    bne @oneup
    lda #50
    jsr add_score
    rts
@oneup:
    jsr powerup_collect
    rts

@boss_player_y_box:
    ; Player body is 21 pixels high; the expanded boss body is 42 pixels high.
    ; Touching the top edge is enough for a landing, but a visible gap is not.
    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta object_temp_lo
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora object_temp_lo
    sta object_temp_lo      ; integer player top
    clc
    adc #21
    cmp object_y,x
    bcs :+
    rts                     ; player feet are still above the boss
:
    lda object_y,x
    clc
    adc #42
    sta object_temp_hi
    lda object_temp_lo
    cmp object_temp_hi
    bcc :+
    rts                     ; player is at or below the boss body
:

    ; A stomp must enter the upper eight pixels while descending. Everything
    ; else is body contact and damages the player.
    lda player_vy
    bmi @boss_damage
    lda player_airborne_entry
    beq @boss_damage
    lda object_temp_lo
    cmp object_y,x
    bcs @boss_damage
    clc
    adc #21
    sec
    sbc object_y,x
    cmp #9
    bcs @boss_damage
    jsr boss_take_hit
    lda #$D0
    sta player_vy
    rts
@boss_damage:
    jmp @damage

@enemy:
    lda level_number
    cmp #3
    bne @stompable_enemy
    cpx #5
    bcc @stompable_enemy
    lda damage_cooldown
    bne :+
    inc action_hits
:
    jsr player_damage       ; falling material and balls are never stompable
    rts
@stompable_enemy:
    lda player_vy
    bmi @damage
    ; A descending player whose top is clearly above the enemy stomps it.
    lda player_y_lo
    lsr
    lsr
    lsr
    lsr
    sta object_temp_lo
    lda player_y_hi
    asl
    asl
    asl
    asl
    ora object_temp_lo
    cmp object_y,x
    bcc @stomp
    bne @damage
    ; Tile landing may already have snapped Y to the floor this frame. Equality
    ; is a stomp only when the player entered the frame airborne.
    lda player_airborne_entry
    beq @damage
@stomp:
    cpx #6
    bne @normal_stomp
    jsr boss_take_hit
    lda #$D0                ; stronger rebound clears the expanded boss
    sta player_vy
    rts
@normal_stomp:
    lda object_bits,x
    ora object_persistence
    sta object_persistence
    inc enemy_defeats
    jsr sfx_enemy
    lda #$D8                ; bounce at -2.5 pixels/frame
    sta player_vy
    lda #25
    jsr add_score
    rts
@damage:
    jsr player_damage
@no_hit:
    rts

; X is stable object ID. Each layout selects pickup meaning from one compact
; table, keeping collision, artwork and effect policy synchronized. Keep this
; helper outside object_collide: ca65 cheap-local labels belong to the preceding
; non-local scope, so placing it inside that routine hides later @enemy labels.
object_type_for_level:
    lda level_number
    cmp #2
    beq @level_two_type
    cmp #3
    beq @level_three_type
    txa
    tay
    lda object_type_table,y
    rts
@level_two_type:
    txa
    clc
    adc #OBJECT_COUNT
    tay
    lda object_type_table,y
    rts
@level_three_type:
    txa
    clc
    adc #(OBJECT_COUNT*2)
    tay
    lda object_type_table,y
    rts

; Deterministic harness entry. X selects any enemy ID and production behavior
; still uses the same AABB path.
objects_test_enemy_collision:
    stx object_index
    jmp object_collide

; Test one active projectile against the fixed boxes of active enemies.
; Returns A=1 on defeat, A=0 otherwise.
objects_projectile_hit:
    ldx #6
@enemy_loop:
    cpx #3
    bne :+
    jmp @skip
:
    cpx #2
    bne :+
    jmp @skip
:
    cpx #1
    bne :+
    jmp @skip
:
    lda level_number
    cmp #3
    bne :+
    cpx #5
    bcc :+
    jmp @skip               ; action hazards cannot be shot away
:
    lda object_active,x
    bne :+
    jmp @skip
:
    lda object_bits,x
    and object_persistence
    beq :+
    jmp @skip
:
    cpx #6
    bne @regular_projectile_x
    lda level_number
    cmp #2
    bne @regular_projectile_x
    ; The expanded boss weak core begins 10 pixels inside its left edge and is
    ; 28 pixels wide. Preserve the unsigned 16-bit offset; firing merely in the
    ; boss's direction is insufficient unless the projectile crosses this box.
    lda projectile_x_lo
    sec
    sbc object_x_lo,x
    sta object_temp_lo
    lda projectile_x_hi
    sbc object_x_hi,x
    bne @skip
    lda object_temp_lo
    cmp #10
    bcc @skip
    cmp #38
    bcs @skip
    jmp @projectile_x_hit
@regular_projectile_x:
    ; Regular enemy coordinates are the top-left corner of a fixed 24x21 box.
    ; Use a directed point-in-box test: the previous absolute-distance test
    ; accepted empty space to the left but cut off six pixels on the right.
    lda projectile_x_lo
    sec
    sbc object_x_lo,x
    sta object_temp_lo
    lda projectile_x_hi
    sbc object_x_hi,x
    bne @skip
    lda object_temp_lo
    cmp #24
    bcs @skip
@projectile_x_hit:
    lda projectile_y
    sec
    sbc object_y,x
    sta object_temp_lo
    cpx #6
    bne @regular_projectile_y
    lda level_number
    cmp #2
    beq @boss_y_window
@regular_projectile_y:
    lda object_temp_lo
    cmp #21
    bcs @skip
    lda object_bits,x
    ora object_persistence
    sta object_persistence
    inc enemy_defeats
    jsr sfx_enemy
    lda #15
    jsr add_score
    lda #1
    rts
@boss_y_window:
    ; Only the bright central core is vulnerable. A projectile above the boss
    ; wraps here and fails the unsigned range test; floor-height blind fire is
    ; below the 17-pixel window. Bomb arcs can be aimed through it.
    lda object_temp_lo
    cmp #8
    bcc @skip
    cmp #25
    bcs @skip
    lda strong_timer
    beq :+
    lda boss_hp             ; power shot deals two core damage in one hit event
    cmp #2
    bcc :+
    dec boss_hp
:
    jsr boss_take_hit
    rts
@skip:
    dex
    bmi :+
    jmp @enemy_loop
:
    lda #0
    rts

; One attack is consumed even during the short invulnerability flash.
; X must be boss object ID 6. Returns A=1.
boss_take_hit:
    lda boss_invuln
    bne @consumed
    lda #6
    sta boss_invuln
    inc boss_hits
    lda boss_hp
    beq @consumed
    dec boss_hp
    beq @defeated
    jsr sfx_enemy
    lda #10
    jsr add_score
@consumed:
    lda #1
    rts
@defeated:
    lda #$40
    ora object_persistence
    sta object_persistence
    inc enemy_defeats
    inc boss_defeats
    jsr sfx_enemy
    lda #150
    jsr add_score
    lda #1
    rts

object_render:
    lda object_x_lo,x
    sec
    sbc camera_pixel_lo
    sta object_temp_lo
    lda object_x_hi,x
    sbc camera_pixel_hi
    sta object_temp_hi
    ; Activation margin is wider than the drawable range.
    lda object_temp_hi
    beq @visible
    cmp #1
    bne @left_edge
    lda object_temp_lo
    cmp #64
    bcc @visible
    rts
@left_edge:
    cmp #$FF
    beq :+
    rts
:
    lda object_temp_lo
    cmp #233
    bcs @visible
    rts
@visible:
    ; X register offset is (stable object id + 1) * 2.
    txa
    clc
    adc #1
    asl
    tay
    lda object_temp_lo
    clc
    adc #24
    sta sprite_xy_shadow,y
    lda object_temp_hi
    adc #0
    beq @low_x
    lda object_bits_plus_one,x
    ora object_msb_mask
    sta object_msb_mask
@low_x:
    lda object_y,x
    clc
    adc #50
    iny
    sta sprite_xy_shadow,y
    cpx #6
    bne :+
    lda level_number
    cmp #2
    bne :+
    lda #$80
    ora VIC_SPR_X_EXPAND
    sta VIC_SPR_X_EXPAND
    lda #$80
    ora VIC_SPR_Y_EXPAND
    sta VIC_SPR_Y_EXPAND
:
    lda object_bits_plus_one,x
    ora object_enable_mask
    sta object_enable_mask
    cpx #6
    bne @normal_color
    lda level_number
    cmp #2
    bne @normal_color
    lda boss_invuln
    bne @boss_white
    lda boss_hp
    cmp #4
    bcs @normal_color
    lda frame_counter_lo
    and #8
    beq :+
@boss_white:
    lda #COLOR_WHITE
    bne @store_color
:
@normal_color:
    jsr object_type_for_level
    cmp #TYPE_ENEMY
    beq :+
    lda frame_counter_lo    ; every pickup pulses white without relying on hue
    and #8
    bne @pickup_white
:
    lda level_number
    cmp #3
    bne :+
    cpx #5
    bne @level3_ball_color
    lda #COLOR_DARK_GREY
    bne @store_color
@level3_ball_color:
    cpx #6
    bne :+
    lda #COLOR_YELLOW
    bne @store_color
:
    lda object_colors,x
@store_color:
    sta VIC_SPR1_COLOR,x
    lda level_number
    cmp #3
    bne @normal_pointer
    cpx #5
    bne :+
    lda #$51
    bne @store_pointer
:
    cpx #6
    bne @normal_pointer
    lda #$52
    bne @store_pointer
@normal_pointer:
    lda object_pointers,x
@store_pointer:
    sta SCREEN_A+$3F9,x
    sta SCREEN_B+$3F9,x
@done:
    rts
@pickup_white:
    lda #COLOR_WHITE
    bne @store_color

.segment "RODATA"
; IDs 1-3 are the speaker kit: conference badge, slide deck and emergency
; coffee/1-Up. The foyer teaches the kit along the main aisle; the later
; sections move it onto elevated chair rows. IDs 0/4 are conference bugs.
object_initial_x_lo: .byte <340, <100, <190, <270, <600, <820, <0
object_initial_x_hi: .byte >340, >100, >190, >270, >600, >820, >0
object_level2_x_lo:  .byte <220, <140, <470, <760, <390, <620, <860
object_level2_x_hi:  .byte >220, >140, >470, >760, >390, >620, >860
object_level3_x_lo:  .byte <180, <280, <520, <760, <650, <656, <900
object_level3_x_hi:  .byte >180, >280, >520, >760, >650, >656, >900
object_initial_y:    .byte 139, 139, 139, 139, 139, 105, 139
object_level2_y:     .byte 139, 91, 91, 91, 139, 105, 118
object_level3_y:     .byte 139, 91, 91, 75, 139, 16, 139
; One contiguous table avoids ca65 symbol/debug-size collisions between three
; similarly named RODATA labels. Rows are L1, L2 and L3, seven stable IDs each.
object_type_table:
    .byte TYPE_ENEMY, TYPE_POWER, TYPE_POWER, TYPE_POWER
    .byte TYPE_ENEMY, TYPE_ENEMY, TYPE_ENEMY
    .byte TYPE_ENEMY, TYPE_POWER, TYPE_POWER, TYPE_ONEUP
    .byte TYPE_ENEMY, TYPE_ENEMY, TYPE_ENEMY
    .byte TYPE_ENEMY, TYPE_POWER, TYPE_POWER, TYPE_ONEUP
    .byte TYPE_ENEMY, TYPE_ENEMY, TYPE_ENEMY
object_bits:         .byte $01, $02, $04, $08, $10, $20, $40
object_bits_plus_one: .byte $02, $04, $08, $10, $20, $40, $80
object_pointers:     .byte $44, $45, $46, $47, $44, $44, $50
object_colors:       .byte COLOR_RED, COLOR_CYAN, COLOR_YELLOW, COLOR_GREEN
                     .byte COLOR_RED, COLOR_PURPLE, COLOR_LIGHT_BLUE

enemy_left_l1_lo:  .byte <328, 0, 0, 0, <584, <804, 0
enemy_left_l1_hi:  .byte >328, 0, 0, 0, >584, >804, 0
enemy_right_l1_lo: .byte <360, 0, 0, 0, <616, <836, 0
enemy_right_l1_hi: .byte >360, 0, 0, 0, >616, >836, 0
enemy_left_l2_lo:  .byte <204, 0, 0, 0, <374, <604, <800
enemy_left_l2_hi:  .byte >204, 0, 0, 0, >374, >604, >800
enemy_right_l2_lo: .byte <236, 0, 0, 0, <406, <636, <900
enemy_right_l2_hi: .byte >236, 0, 0, 0, >406, >636, >900
enemy_left_l3_lo:  .byte <164, 0, 0, 0, <634, 0, 0
enemy_left_l3_hi:  .byte >164, 0, 0, 0, >634, 0, 0
enemy_right_l3_lo: .byte <206, 0, 0, 0, <676, 0, 0
enemy_right_l3_hi: .byte >206, 0, 0, 0, >676, 0, 0
falling_lane_x_lo: .byte <416, <656, <848
falling_lane_x_hi: .byte >416, >656, >848
