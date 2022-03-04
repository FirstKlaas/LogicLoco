.namespace MAPLOADER {
    
    SCREEN_ROWS: .lohifill 25, SCREENRAM + 40*(i) 
    COLOR_ROWS: .lohifill 25, COLORRAM + 40*(i)

    TILE_OFFSET: .byte $00, $01, $28, $29
    

    load_map:
        ldx #0
        stx ZP_TILE_ITERATOR       // 3 cycles (zeropage)  // 4 cycles absolute
        inx
        stx ZP_MAP_ROW_ITERATOR    // Save current Row Iterator

    !loop:
        // Storing the address of screen row
        // in num1 (Zeropage) 
        lda SCREEN_ROWS.lo, x 
        sta ZP_num1 
        lda SCREEN_ROWS.hi, x 
        sta ZP_num1Hi

        // Storing the address of color row
        // in num2 (Zeropage) 
        lda COLOR_ROWS.lo, x 
        sta ZP_num2 
        lda COLOR_ROWS.hi, x 
        sta ZP_num2Hi 
        DrawRow()
    !x:
        ldx ZP_MAP_ROW_ITERATOR
        inx
        inx
        txa
        cmp #25
        beq !done+ 
        stx ZP_MAP_ROW_ITERATOR
        jmp !loop-
    !done: 
        rts


.macro DrawRow() {
            ldx #20          // Dies ist der Column Counter. Es gibt 20 Tiles / Reihe
            stx [!rs_x+]+1
        !row_start:    
            ldx ZP_TILE_ITERATOR
            lda MAP_1,x     // Hier ist der Index des Tiles innerhalb der Map gemeint.
            inx
            stx ZP_TILE_ITERATOR
            asl
            asl
            tax
            DrawTile()

            // Update the base for indirect adressing
            lda ZP_num1 
            clc 
            adc #2
            sta ZP_num1
            bcc !skip+
            inc ZP_num1Hi
            inc ZP_num2Hi
        !skip:
            inc ZP_num2
            inc ZP_num2
        !rs_x:
            ldx #00
            dex
            beq !rs_end+
            stx [!rs_x-]+1
            jmp !row_start-
        !rs_end:

    
}

.macro DrawTile() {

    // Draws a tile to the screen
    // num1(Hi) contains the correct top left address
    // in screen space
    // num2(Hi) contains the correct top left address
    // in color space
    // x has the correct offset in MAP_TILES
    
    drawTile: {
            stx [!x+]+1       // Safe x register
            ldy #0
            sty [!next_char+]+1
        !loop_chars:
            lda TILE_OFFSET, y
            tay
            lda MAP_TILES, x        // Read the character
            sta (ZP_num1), y        // Write character to screen
            tax                     // Screencode as index in color map
            lda CHAR_COLORS, x
            sta (ZP_num2), y
        !next_char:
            ldy #00
            iny
            tya
            cmp #4
            beq !end+
            sty [!next_char-]+1
        !x:    
            ldx #00 
            inx
            stx [!x-]+1 
            jmp !loop_chars-
        !end:
    }
    
}

}


