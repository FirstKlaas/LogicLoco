    .import source "lib/constants.asm"
    .import source "main_macros.asm"

    .const ID_PLAYER_BULLET = $01

    .label FRAME_COUNTER = ZP_FrameCounter


.macro M_ADD_BULLET_SPRITE_VV(xpos, ypos) {
    lda #[ID_PLAYER_BULLET]
    clc 
    ldx #[xpos]
    ldy #[ypos]
    jsr SOFTSPRITE.AddSprite
}

.macro M_MOVE_SPRITE_VVV(id, dx, dy) {
    lda #[id] 
    ldx #[dx] 
    ldy #[dy]
    jsr SOFTSPRITE.MoveSprite     
}

.macro M_CLEAR_SPRITE_V(id) {
    ldx #[id]
    jsr SOFTSPRITE.ClearSingleSprite 
}

.macro M_UPDATE_SPRITE_V(id) {
    ldx #[id]     
    jsr SOFTSPRITE.UpdateSingleSprite    
}

.macro M_DRAW_SPRITE_V(id) {
    ldx #[id]
    jsr SOFTSPRITE.DrawSingleSprite
}


BasicUpstart2(main)

/***********************************************
    MAIN PROGRAM LOOP
************************************************/
* = $1000 "Main Program"
main:

    M_DISABLE_CIA_INTERRUPTS()
    M_INSTALL_IRQ_VECTOR(main_irq)
    M_SET_BACKGROUND_COLOR_V(COLOR_DARKGREY)
    M_SET_BORDER_COLOR_V(COLOR_GREY)

    M_BANKOUT_KERNAL_AND_BASIC()
    M_SET_VIC_BANK_3()
    M_SET_SCREEN_AND_CHARACTER_MEM()

    M_VIC_ENABLE_MULTICOLOR_TEXTMODE()

    jsr PLAYER.Init
    jsr SOFTSPRITE.Initialize
    jsr SOFTSPRITE.PrecalculateTemplateCharAdresses

    jsr SCREEN.clear
    jsr MAPLOADER.load_map  
    jsr SOFTSPRITE.CopyScreenBuffer

    
    M_ADD_BULLET_SPRITE_VV(3,8)
    //M_ADD_BULLET_SPRITE_VV(20,40)
    
    // Print blanks in the first line
    lda #0
    ldx #40
!:
    dex
    sta SCREENRAM,x
    bne !-

    // Color first row
    lda #COLOR_CYAN
    ldy #0
    jsr SCREEN.color_row

    M_INSTALL_RASTER_IRQ(raster_irq_gameloop, $FF)
!:
    M_WAIT_FOR_RASTERLINE_V(255)
    inc FRAME_COUNTER
    jmp !-

main_irq:
        nop
        rti 


COLOR_RAMP_01:
    .byte $01, $0d, $03, $0e, $04, $0b, $06
    .byte $06, $0b, $04, $0e, $03, $0d, $01
__COLOR_RAMP_01:

.const COLOR_RAMP_01_SIZE = __COLOR_RAMP_01 - COLOR_RAMP_01

raster_irq_gameloop: {
        M_IRQ_START_L(irq_exit)
        inc BORDER_COLOR
        
        M_SET_TEXT_MULTICOLORS(COLOR_LIGHTGREEN, COLOR_WHITE)

        lda zpPlayerState
        PRINT_HEX_VVACC(1,0)

        lda zpPlayerX
        PRINT_HEX_VVACC(4,0)

        lda zpPlayerY
        PRINT_HEX_VVACC(7,0)

        lda zpJoystick2State
        PRINT_HEX_VVACC(10,0)

        lda zpPlayerRestFrame
        PRINT_HEX_VVACC(13,0)

        jsr PLAYER.GetCollisions
        jsr PLAYER.Control
        jsr PLAYER.JumpAndFall
        jsr PLAYER.Draw
        jsr ANIMATION.animate_door

        M_CLEAR_SPRITE_V(0)
        M_MOVE_SPRITE_VVV(0,4,0)
        M_UPDATE_SPRITE_V(0)
        M_DRAW_SPRITE_V(0)
        
        //M_UPDATE_SPRITE_V(1)
        //M_DRAW_SPRITE_V(1)
        dec BORDER_COLOR
        
        // -------------------------------------
        // BG Color Animation
        // -------------------------------------
        /*
        ldx #100
        ldy #COLOR_RAMP_01_SIZE
    !:
        cpx REG_RASTERLINE
        bne *-3
        lda COLOR_RAMP_01-1, y
        sta BORDER_COLOR
        inx
        dey
        bpl !-
        M_SET_BORDER_COLOR_V(COLOR_BLACK)
        M_RASTER_IRQ(raster_irq_gameloop, 0)
        */
        //M_RASTER_IRQ(raster_irq_gameloop, $FE)
        M_ACK_ANY_IRQ()
        jmp irq_exit
}

irq_exit:
        M_IRQ_EXIT()

    .import source "player/player.asm"   
    .import source "util.asm" 
    
    .import source "lib/maploader.asm"
    .import source "softsprite.asm"
    
    
    .import source "lib/screen.asm"
    .import source "lib/math.asm"
    .import source "animations.asm"

    .import source "zeropage.asm"
    .import source "assets.asm"
    
