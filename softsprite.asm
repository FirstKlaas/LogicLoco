.macro DISABLE_SOFT_SRPITE(idx) {
    lda #0 
    ldx #[idx]
    sta SOFTSPRITE.ID, x
}

.namespace SOFTSPRITE {

    .const NUMBER_OF_SPRITES = 8
    .const SPRITE_CHARSET_START = $5a

    _TEMPLATE_CHARS:
        .byte $00, $4e
    __TEMPLATE_CHARS:

    .label TEMPLATE_CHARS = _TEMPLATE_CHARS
    .const NUMBER_OF_TEMPLATE_CHARS = [__TEMPLATE_CHARS - _TEMPLATE_CHARS]

    _TEMPLATE_CHAR_PTR_LSB:
        .fill NUMBER_OF_TEMPLATE_CHARS, $00 

    _TEMPLATE_CHAR_PTR_MSB:
        .fill NUMBER_OF_TEMPLATE_CHARS, $00

    SPRITE_MASK_TABLE:
        .fill 256, $00

    .label TEMPLATE_CHAR_MEM_LSB = _TEMPLATE_CHAR_PTR_LSB
    .label TEMPLATE_CHAR_MEM_MSB = _TEMPLATE_CHAR_PTR_MSB

    .print "Template Char MEM LSB " + toHexString(TEMPLATE_CHAR_MEM_LSB)
    .print "Template Char MEM MSB " + toHexString(TEMPLATE_CHAR_MEM_MSB)
    .print "SpriteMask Table      " + toHexString(SPRITE_MASK_TABLE)

    _DATA:
        .fill NUMBER_OF_SPRITES, $00  // ID
        .fill NUMBER_OF_SPRITES, $00  // XPOS_LSB
        .fill NUMBER_OF_SPRITES, $00  // XPOS_MSB
        .fill NUMBER_OF_SPRITES, $00  // YPOS
        .fill NUMBER_OF_SPRITES, $00  // Char Index. First character of four in a row.

    .label ID                   = _DATA
    .label XPOS_LSB             = _DATA + NUMBER_OF_SPRITES
    .label XPOS_MSB             = _DATA + [2 * NUMBER_OF_SPRITES]
    .label YPOS                 = _DATA + [3 * NUMBER_OF_SPRITES]
    .label CHAR_INDEX           = _DATA + [4 * NUMBER_OF_SPRITES]

    .label SCREEN_BUFFER_PTR    = $cc00
    .label SCREEN_RAM_PTR       = $c000
    .label CHARSET              = $f000
    .label SPRITE_RAM_PTR       = CHARSET + [SPRITE_CHARSET_START * 8]

    _SPRITE_DATA_TILE_START:
        .lohifill NUMBER_OF_SPRITES, SPRITE_RAM_PTR + [i * 32]

    .label SPRITE_DATA_TILE_LSB =  _SPRITE_DATA_TILE_START.lo
    .label SPRITE_DATA_TILE_MSB =  _SPRITE_DATA_TILE_START.hi

    _BUF_ROW:
        .lohifill 25, SCREEN_BUFFER_PTR + 40*i

    .label OFFSCREEN_ROW_LO = _BUF_ROW.lo 
    .label OFFSCREEN_ROW_HI = _BUF_ROW.hi 

    CURRENT_SPRITE_INDEX: .byte $00 

    TEMPLATE_CHAR:
        .fill 8, $00

    Initialize: {
            lda #0
            sta CURRENT_SPRITE_INDEX
            ldx #NUMBER_OF_SPRITES-1
        !loop:
            sta ID,x 
            sta XPOS_LSB,x 
            sta XPOS_MSB,x 
            sta YPOS,x
            dex 
            bpl !loop-

        jsr CreateSpriteMaskTable
        rts
    }

    // Precalculates the 16 bit address of an template
    // character.
    //
    // address = charset + 8 * template_character
    //
    PrecalculateTemplateCharAdresses: {
            ldx #[NUMBER_OF_TEMPLATE_CHARS-1] 
            !loop:
                lda TEMPLATE_CHARS,x    // Load the character into accu
                sta TEMPLATE_CHAR_MEM_LSB, x
                lda #00 
                sta TEMPLATE_CHAR_MEM_MSB, x
                // Multiply by eight
                asl TEMPLATE_CHAR_MEM_LSB, x
                rol TEMPLATE_CHAR_MEM_MSB, x
                asl TEMPLATE_CHAR_MEM_LSB, x
                rol TEMPLATE_CHAR_MEM_MSB, x
                asl TEMPLATE_CHAR_MEM_LSB, x
                rol TEMPLATE_CHAR_MEM_MSB, x
                // Add the base address of the charset
                clc 
                lda #<CHARSET 
                adc TEMPLATE_CHAR_MEM_LSB, x
                sta TEMPLATE_CHAR_MEM_LSB, x
                lda #>CHARSET 
                adc TEMPLATE_CHAR_MEM_MSB, x
                sta TEMPLATE_CHAR_MEM_MSB, x
            dex 
            bne !loop-  // For id 0, we do not need to calculate, as 0 indicates
                        // an inactive sprite
        rts
    } 

    // REG X: Delta x
    // REG Y: Delta y 
    // REG A: SpriteIndex
    //
    // Attention: As we use multicolor chars, the x value
    // is multiplied by two, as two pixels are used per color
    // So moving sprite by one in x means two screen pixels
    // In multicolor mode each character pixel is two pixel
    // wide.
    MoveSprite: {
        .label DX = zpTemp00 
        .label DY = zpTemp01 
            
            stx DX  // Save dx, so we can use x register 
            sty DY
            tax     // index to accu 

            // Chech the ID.
            lda ID,x 
            bne !+
            rts         // Ignore the sprite, if the ID is zero, as zero
                        // indicates an inactive sprite
        !:
            lda YPOS, x
            clc 
            adc DY 
            sta YPOS, x
            clc  
            lda DX
            asl
             
            adc XPOS_LSB,x
            sta XPOS_LSB,x
            lda XPOS_MSB,x
            adc #00
            sta XPOS_MSB,x
            
        rts
    }

    // Clears a single sprite
    // REG X: Index of the sprite to be cleared
    ClearSingleSprite: {

        
        .label SCREEN_ROW_PTR   = ZP_num1
        .label BUFFER_ROW_PTR   = ZP_num2

        lda ID, x 
        bne !+ 
        rts         // Ignoring "disabled" sprites
    !:
        // Store the screen row pointer in zeropage        
        lda YPOS, x
        lsr                 // Converting from pixel space to 
        lsr                 // character space, by dividing by eight
        lsr
        tay
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        lda OFFSCREEN_ROW_LO, y
        sta BUFFER_ROW_PTR
        lda OFFSCREEN_ROW_HI, y
        sta BUFFER_ROW_PTR+1 

        lda XPOS_MSB, x     // Dividing xpos by eight.
        lsr                 // Dividing High Byte, updating carry bit
        lda XPOS_LSB, x 
        ror                 // Dividing by two, taking carry into account
        lsr 
        lsr

        tay

        // Top Left
        lda (BUFFER_ROW_PTR), y
        sta (SCREEN_ROW_PTR), y

        // Top Right
        iny 
        lda (BUFFER_ROW_PTR), y
        sta (SCREEN_ROW_PTR), y

        // Bottom Left
        tya 
        clc 
        adc #$27 
        tay 
        lda (BUFFER_ROW_PTR), y
        sta (SCREEN_ROW_PTR), y

        // Bottom Right
        iny 
        lda (BUFFER_ROW_PTR), y
        sta (SCREEN_ROW_PTR), y
        rts

    }

    UpdateSingleSprite: {
        .label XOffset  = zpTemp00 
        .label YOffset  = zpTemp01
        .label TMP      = zpTemp02
        .label CharDataPtr = ZP_num1
        .label CharDataPtrRight = zpTempVector01
        .label CharTemplatePtr = ZP_num2

            lda ID,x 
            bne !+
            rts     // If ID is zero, igore sprite.
        !: 
            // Calculate X Offset
            lda XPOS_LSB, x 
            and #7              // Only the least significant three bits are relevant. 
            sta XOffset         // Offset is between 0 and 7
            
            // Calculate Y Offset
            lda YPOS,x 
            and #7
            sta YOffset
            
            // Setup pointer to the char memory for this sprite/tile
            // This is the target mem
            lda SPRITE_DATA_TILE_LSB, x
            sta CharDataPtr 
            clc 
            adc #16
            sta CharDataPtrRight
            lda SPRITE_DATA_TILE_MSB, x
            sta CharDataPtr+1 
            sta CharDataPtrRight+1


            // Setup the pointer to the char template
            // This is the source mem
            lda ID, x // Load the sprite id and use it as the index
            tay
            lda TEMPLATE_CHAR_MEM_LSB, y
            sta CharTemplatePtr 
            lda TEMPLATE_CHAR_MEM_MSB, y
            sta CharTemplatePtr+1 

/*   I comented i out, as this part of the routine is too expensive, and we 
     may not need it anyway, when we merge the tile with the background.

            // Clear the complete tile
            ldy #0
            lda #0 
        !LoopClearTile:
            sta (CharDataPtr), y        
            iny 
            cpy #32
            bne !LoopClearTile-

*/

            // Copy the template char, so we can
            // use x as an index
            ldy #7 
        !LoopCopyTemplateChar:
            lda (CharTemplatePtr), y
            sta TEMPLATE_CHAR, y
            dey 
            bpl !LoopCopyTemplateChar- 

        
            // Now update vertical shift
            ldy #0
            ldx #0
        !:
            lda #00
            cpy YOffset
            bcc !Next+
            cpx #8 
            beq !Next+              // If we have copied the complete char already
                                    // skip. We continue to fill with blank lines
            lda TEMPLATE_CHAR,x
            inx
        !Next:
            sta (CharDataPtr), y        
            iny 
            cpy #16 
            bne !- 

        // ---------------------------
        // Now update horizontal shift
        // ---------------------------
        !HorizontalShift:
            ldy #15 // WE need to shift 16 rows [0-15] 
        !LoopShiftX:
            lda #0 
            sta TMP                 // Right Byte of line 
            ldx XOffset
            beq !XShiftEnd+
            lda (CharDataPtr), y
        !:
            lsr                     // Lowest bit in carry flag
            ror TMP
            dex
            bne !- 
            sta (CharDataPtr), y
            lda TMP
            sta (CharDataPtrRight), y
            
            dey 
            bpl !LoopShiftX- 
        !XShiftEnd:
        rts
    }

    DrawSprites: {
            ldx #NUMBER_OF_SPRITES
            dex
        !loop:
            jsr DrawSingleSprite
            dex 
            bpl !loop-
        rts
    }

    // Draws a sprite
    // REG X: Index of the sprite to draw
    DrawSingleSprite: {

        .label SCREEN_ROW_PTR   = ZP_num1
        .label TEMP_X           = zpTemp00

        stx TEMP_X
        lda YPOS, x
        lsr 
        lsr 
        lsr 
        tay
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        lda XPOS_MSB, x
        lsr 
        lda XPOS_LSB, x
        ror  
        lsr 
        lsr  
        tay 

        // Load the Character from the charset
        lda ID, x               // Load the sprite ID 
        bne !+                  // Only continue, if ID is not zero
        rts
    !:
        lda CHAR_INDEX, x       // Load the first of the four characters into accu
        tax                     // Save the character in x register

        // Top Left
        sta (SCREEN_ROW_PTR), y

        // Top Right
        iny 
        inx
        inx   
        txa
        sta (SCREEN_ROW_PTR), y

        // Bottom Left
        tya 
        clc 
        adc #$27 
        tay 
        dex
        txa
        sta (SCREEN_ROW_PTR), y

        // Bottom Right
        iny 
        inx
        inx
        txa
        sta (SCREEN_ROW_PTR), y
        ldx TEMP_X
        rts
    }


    // Creates a copy of the current screen. Only screen
    // ram is copied.
    CopyScreenBuffer: {
            ldx #250
        !loop:
            lda SCREEN_RAM_PTR-1,x 
            sta SCREEN_BUFFER_PTR-1,x
            lda SCREEN_RAM_PTR+249,x 
            sta SCREEN_BUFFER_PTR+249,x
            lda SCREEN_RAM_PTR+499,x 
            sta SCREEN_BUFFER_PTR+499,x
            lda SCREEN_RAM_PTR+749,x 
            sta SCREEN_BUFFER_PTR+749,x
            dex 
            bne !loop- 
            rts 
    }

    // Sets the character to be used for the sprite
    // The provided character plus the following
    // three are reserved for the sprite.
    //
    // REG X: Index of the sprite
    // REG A: Number of the character
    SetSpriteChar: {
        sta CHAR_INDEX, x
        rts
    }

    // Adds a sprite at the current index and increments
    // the index by one. If current index equals number
    // of sprites, the index will be set to zero again.
    // Any existing sprite will be overwritten.
    //
    // An id of zero marks an inactive sprite
    //
    // REG A: ID of the sprite
    // REG X: Xpos of the sprite
    // REG Y: Ypos of the sprite
    //
    // The index of the newly created sprite is returned in
    // the x register.
    //
    AddSprite: {

            .label TMP_SPRITE_XPOS  = zpTemp00 
            .label TMP_SPRITE_INDEX = zpTemp01 
            
            stx TMP_SPRITE_XPOS
            ldx CURRENT_SPRITE_INDEX
            stx TMP_SPRITE_INDEX
            sta ID,x 
            tya
            sta YPOS,x 
            lda TMP_SPRITE_XPOS
            asl // Multiply xposition by two, because we are in multi color mode.
                // Each pixel takes two bits (and is diesplayd in double width)
            sta XPOS_LSB,x
            lda #0 
            rol 
            sta XPOS_MSB,x
            inx
            txa
            cmp #NUMBER_OF_SPRITES 
            bne !+ 
            lda #00 
        !:
            sta CURRENT_SPRITE_INDEX 
            ldx TMP_SPRITE_INDEX

            rts
    }


    CreateSpriteMaskTable: {

            ldx #00
        !loop:
            txa 
            and #%10101010
            sta zpTemp00 
            lsr 
            ora zpTemp00
            sta zpTemp00

            txa
            and #%01010101
            sta zpTemp01 
            asl 
            ora zpTemp01 
            ora zpTemp00
            eor #$ff 
            sta SPRITE_MASK_TABLE, x
            inx
            bne !loop- 
        rts
    }

    
}
