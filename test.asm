.import source "lib\constants.asm"
.import source "main_macros.asm"

BasicUpstart2(main)

/***********************************************
    MAIN PROGRAM LOOP
************************************************/
main:
    M_DISABLE_CIA_INTERRUPTS()
    M_BANKOUT_KERNAL_AND_BASIC()
    
    sei 
    lda #<raster_irq_gameloop
    sta IRQVECTOR
    lda #>raster_irq_gameloop
    sta IRQVECTOR+1

    lda #[00]
    sta REG_RASTERLINE 

    lda CTRLREG1
    and #%01111111
    sta CTRLREG1
    
    lda INTERRUPTMASK 
    ora #%00000001
    sta INTERRUPTMASK
    cli

the_end:
    jmp the_end


raster_irq_gameloop:

.break

        pla                 // Y vom Stack
        tay
        pla                 // X vom Stack
        tax
        pla                 // Akku vom Stack

        rti

    .import source "zeropage.asm"
