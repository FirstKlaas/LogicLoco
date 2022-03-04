    .import source "lib/constants.asm"
    .import source "main_macros.asm"
     
BasicUpstart2(main)

/***********************************************
    MAIN PROGRAM LOOP
************************************************/
main:

    M_DISABLE_CIA_INTERRUPTS()
    M_INSTALL_IRQ_VECTOR(main_irq)
    M_SET_BACKGROUND_COLOR_V(COLOR_DARKGREY)
    M_SET_BORDER_COLOR_V(COLOR_GREY)

    M_BANKOUT_KERNAL_AND_BASIC()
    M_SET_VIC_BANK_3()
    M_SET_SCREEN_AND_CHARACTER_MEM()

    M_VIC_ENABLE_MULTICOLOR_TEXTMODE()

    jsr SCREEN.clear
    jsr MAPLOADER.load_map  
    jsr PLAYER.Init

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

    M_INSTALL_RASTER_IRQ(raster_irq_gameloop, 0)
    
    jmp *

main_irq:
        nop
        rti 

raster_irq_gameloop: {
        M_IRQ_START_L(irq_exit)
        //inc BORDER_COLOR
        inc ZP_FrameCounter
        
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
        //dec BORDER_COLOR
        M_RASTER_IRQ(raster_irq_gameloop, 0)
        jmp irq_exit
}

irq_exit:
        M_IRQ_EXIT()

    .import source "player/player.asm"   
    .import source "util.asm" 
    
    .import source "lib/maploader.asm"
    
    .import source "lib/screen.asm"
    .import source "lib/math.asm"
    .import source "animations.asm"

    .import source "zeropage.asm"
    .import source "assets.asm"
    
