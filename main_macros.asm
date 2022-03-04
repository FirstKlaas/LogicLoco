.label PROCESSOR_PORT = $01
.label VIC_MEMORY_BANK_SELECTION_REG = $dd00
.label CIA_INTERRUPT_CONTROL_REG = $dc0d 
.label IRQ_VECTOR_LO = $ffe 
.label IRQ_VECTOR_HI = $fff 


.macro M_ACK_ANY_IRQ() {
    asl INTERRUPT_REQUEST	                // Ack any previous raster interrupt
    bit CIA_INTERRUPT_CONTROL_REG           // reading the interrupt control registers 
    bit CIA2_INTERRUPT_CRTL 	            // clears them    
}

.macro M_IRQ_START_L(label) {
    sta label+1
    lda REG_RASTERLINE
    sta ZP_CURRENT_RASTERLINE            
    stx label+3
    sty label+5    
    //M_ACK_ANY_IRQ()
}

.macro M_IRQ_EXIT() {
    lda #0
    ldx #0
    ldy #0
    rti    
}

.macro M_RASTER_IRQ(func, line) {
        lda #<func
        ldy #>func
        ldx #[line]
        sta $fffe 
        sty $ffff 
        stx REG_RASTERLINE
        asl INTERRUPT_REQUEST	                // Ack any previous raster interrupt    
}

.macro M_SET_BACKGROUND_COLOR_V(color) {
    lda #color
    sta BACKGROUND_COLOR    
}

.macro M_SET_BORDER_COLOR_V(color) {
    lda #color
    sta BORDER_COLOR    
}

.macro M_BANKOUT_KERNAL_AND_BASIC() {
    lda PROCESSOR_PORT
    and #%11111000
    ora #%00000101
    sta PROCESSOR_PORT
}

.macro M_SET_VIC_BANK_3() {
    lda VIC_MEMORY_BANK_SELECTION_REG
    and #%11111100
    sta VIC_MEMORY_BANK_SELECTION_REG
}

.macro M_SET_SCREEN_AND_CHARACTER_MEM() {
    lda #%00001100
    sta SCREENMEMORYCTRL
}

.macro M_DISABLE_CIA_INTERRUPTS() {
    lda #%01111111	//Disable CIA IRQ's
    sta CIA_INTERRUPT_CONTROL_REG
}

.macro M_INSTALL_IRQ_VECTOR(function) {
    sei
    lda #<function
    sta IRQ_VECTOR_LO 
    lda #>function
    sta IRQ_VECTOR_HI 
    cli
}


.macro M_INSTALL_RASTER_IRQ(function, line) {
    sei 

    lda #$7f
    sta $dc0d 
    sta $dd0d 
    lda $dc0d 
    lda $dd0d

    lda #[line] 
    sta REG_RASTERLINE 

    lda CTRLREG1
    and #%01111111
    sta CTRLREG1
    
    lda INTERRUPTMASK 
    ora #%00000001
    sta INTERRUPTMASK

    lda #<function
    sta $fffe
    lda #>function
    sta $ffff

    cli
}

.macro M_SET_TEXT_MULTICOLORS(c1,c2) {
    lda #c1 
    sta TEXTMULTICOLOR1 
    lda #c2
    sta TEXTMULTICOLOR2

}
.macro M_VIC_ENABLE_MULTICOLOR_TEXTMODE() {
    lda CTRLREG2
    ora #%00010000      // Multicolor Text Mode
    sta CTRLREG2
    lda #COLOR_LIGHTGREEN 
    sta TEXTMULTICOLOR1 
    lda #COLOR_WHITE
    sta TEXTMULTICOLOR2
}

