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
    stx label+3
    sty label+5    
    M_ACK_ANY_IRQ()
    lda REG_RASTERLINE
    sta ZP_CURRENT_RASTERLINE            
}

.macro M_IRQ_EXIT() {
    lda #0
    ldx #0
    ldy #0
    rti    
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
    lda #<function
    sta IRQ_VECTOR_LO 
    lda #>function
    sta IRQ_VECTOR_HI 
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

