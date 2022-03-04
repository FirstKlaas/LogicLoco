.macro PRINT_CHR_VVV(xpos,ypos,chr) {
    lda #chr
    ldx #xpos 
    ldy #ypos
    jsr SCREEN.print_char
}

.macro PRINT_HEX_VVV(xpos, ypos, value) {
    ldx #xpos
    ldy #ypos
    lda #value
    jsr SCREEN.print_hex
}

.macro PRINT_HEX_VVA(xpos, ypos, value_addr) {
    ldx #xpos
    ldy #ypos
    lda value_addr
    jsr SCREEN.print_hex
}

.macro PRINT_HEX_VVACC(xpos, ypos) {
    ldx #xpos
    ldy #ypos
    jsr SCREEN.print_hex
}

.macro PRINT_STR_ZERO(xpos, ypos, msg) {
    lda #<msg 
    sta ZP_num2 
    lda #>msg  
    sta ZP_num2Hi 
    ldx #xpos
    ldy #ypos
    jsr SCREEN.print_zero_str 
}

.macro PRINT_FAST_CHAR_AAV(xpos, ypos, char) {
    ldx ypos 
    ldy xpos
    lda SCREEN.ROW_ADR.hi, x
    sta ZP_num1Hi
    lda SCREEN.ROW_ADR.lo ,x
    sta ZP_num1
    lda #char
    sta (ZP_num1),y 
}

.macro PRINT_FAST_CHAR_AAA(xpos, ypos, char) {
    ldx ypos 
    ldy xpos
    lda SCREEN.ROW_ADR.hi, x
    sta ZP_num1Hi
    lda SCREEN.ROW_ADR.lo ,x
    sta ZP_num1
    lda char
    sta (ZP_num1),y 
}

.macro PRINT_FAST_CHAR_AAACC(xpos, ypos) {
    pha
    ldx ypos 
    ldy xpos
    lda SCREEN.ROW_ADR.hi, x
    sta ZP_num1Hi
    lda SCREEN.ROW_ADR.lo ,x
    sta ZP_num1
    pla
    sta (ZP_num1),y 
}

.macro PRINT_FAST_CHAR_VVACC(xpos, ypos) {
    pha
    ldx #ypos 
    ldy #xpos
    lda SCREEN.ROW_ADR.hi, x
    sta ZP_num1Hi
    lda SCREEN.ROW_ADR.lo ,x
    sta ZP_num1
    pla
    sta (ZP_num1),y 
}


.macro SUB_COLOR_ROW(color, row_idx) {
    lda #color
    ldy #row_idx
    jsr SCREEN.color_row
}

.namespace SCREEN {

    ROW_ADR:
        .lohifill 25, SCREENRAM + 40*i

    ROW_COLOR_ADR:
        .lohifill 25, COLORRAM + 40*i

    clear:
        ldx #250
        lda #$04                // "Empty" Character 
    !:
        sta SCREENRAM-1,x 
        sta SCREENRAM+249,x 
        sta SCREENRAM+499,x
        sta SCREENRAM+749,x
        dex
        bne !-
    rts 
     
    colorize:
        ldx #250
        lda #COLOR_YELLOW
    !:
        sta COLORRAM-1,x
        sta COLORRAM+249,x 
        sta COLORRAM+499,x
        sta COLORRAM+749,x
        dex
        bne !-
        rts

    print_char:                 // Offset = (ypos*40+xpos) + SCREENRAM
        pha                     // Das zu druckende Zeichen sichern
        lda ROW_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_ADR.lo , y
        sta ZP_num1
        txa
        tay
        pla
        sta (ZP_num1),y 
        rts

    print_char_row:                 
        pha                     
        lda ROW_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_ADR.lo , y
        sta ZP_num1
        ldy #39 
        pla
    !:
        sta (ZP_num1),y
        dey 
        bne !- 
        sta (ZP_num1),y
        rts

    print_zero_str:
        // Bildschiradresse der Zeile
        // in num1 und num1Hi ablegen
        lda ROW_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_ADR.lo ,y
        sta ZP_num1
        txa
        clc
        adc ZP_num1
        sta ZP_num1
        // Nun ist y wieder frei
        ldy #0
    !:
        lda (ZP_num2),y 
        cmp #0
        beq print_zero_str_end
        sta (ZP_num1), y
        iny 
        jmp !- 

    print_zero_str_end:
        rts
        
    print_hex:
        pha
        lda ROW_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_ADR.lo , y
        sta ZP_num1
        stx ZP_num2
        pla
        jsr MATH.convert_to_hex
        ldy ZP_num2
        sta (ZP_num1),y 
        txa
        iny
        sta (ZP_num1), y
        rts

    /**
        Input:
            X Register = X-Position
            Y Register = Y-Position
        Output:
            A Register = Char Code
            num1       = LSB ScreenAddress
            num1Hi     = MSB ScreenAddress
    */
    read_char:
        lda ROW_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_ADR.lo , y
        sta ZP_num1
        txa
        tay
        lda (ZP_num1), y 
        rts

    color_row:
        pha 
        lda ROW_COLOR_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_COLOR_ADR.lo , y
        sta ZP_num1
        ldy #39
        pla
    !loop:
        sta (ZP_num1), y 
        dey 
        bne !loop- 
        sta (ZP_num1), y 
        rts       
         
    color_char:
        pha
        lda ROW_COLOR_ADR.hi, y
        sta ZP_num1Hi
        lda ROW_COLOR_ADR.lo , y
        sta ZP_num1
        txa
        tay
        pla
        sta (ZP_num1), y 
        rts

}