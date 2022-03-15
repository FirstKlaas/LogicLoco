.macro DISABLE_SOFT_SRPITE(idx) {
    lda #0 
    ldx #[idx]
    sta SOFTSPRITE.ID, x
}

.namespace SOFTSPRITE {

    .const NUMBER_OF_SPRITES = 8
    .const SPRITE_CHARSET_START = $e0   
    .const SPRITE_BULLET_CHAR =  $5a   

    SPRITE_CHAR_INDEX_TABLE:
        .fill 8, SPRITE_CHARSET_START + i*4

    _TEMPLATE_CHARS:
        .byte $00, SPRITE_BULLET_CHAR
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


    CHARSET_MEM_LSB: .fill 256, $00 
    CHARSET_MEM_MSB: .fill 256, $00
    
    _DATA:
        .fill NUMBER_OF_SPRITES, $00  // ID
        .fill NUMBER_OF_SPRITES, $00  // XPOS_LSB
        .fill NUMBER_OF_SPRITES, $00  // XPOS_MSB
        .fill NUMBER_OF_SPRITES, $00  // YPOS
        .fill NUMBER_OF_SPRITES, $00  // Char Index. First character of four in a row.
        .fill NUMBER_OF_SPRITES, $00  // CharXPOS
        .fill NUMBER_OF_SPRITES, $00  // CharYPOS
        

    .label ID                   = _DATA
    .label XPOS_LSB             = _DATA + NUMBER_OF_SPRITES
    .label XPOS_MSB             = _DATA + [2 * NUMBER_OF_SPRITES]
    .label YPOS                 = _DATA + [3 * NUMBER_OF_SPRITES]
    .label CHAR_INDEX           = _DATA + [4 * NUMBER_OF_SPRITES]
    .label CHAR_XPOS            = _DATA + [5 * NUMBER_OF_SPRITES]
    .label CHAR_YPOS            = _DATA + [6 * NUMBER_OF_SPRITES]
    

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
        jsr CalculateFontPtrTable
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
            
            sty [!SMC_DY+]+1
            stx [!SMC_DX+]+1

            cpx #00 
            // beq !UpdateYpos+    // If we don't move vertically, we do not need
                                // to recalculate y position
            tax     // index to accu 

            // Check the ID.
            lda ID,x 
            bne !UpdateYpos+
            rts         // Ignore the sprite, if the ID is zero, as zero
                        // indicates an inactive sprite
        !UpdateYpos:
            lda YPOS, x
            clc 
        !SMC_DY:    // Self modified code
            adc #$EE 
            sta YPOS, x
            // Now calculate the ypos in char space
            lsr 
            lsr 
            lsr 
            sta CHAR_YPOS, x

        !UpdateXpos:
            clc  
        !SMC_DX:
            lda #$EE  // Self modified code
            //beq !Exit+  // if dx = 0, we do not need to recalculate position
            asl
             
            adc XPOS_LSB,x
            sta XPOS_LSB,x
            lda XPOS_MSB,x
            adc #00
            sta XPOS_MSB,x

            // Now calculate x position in char space
            lsr 
            lda XPOS_LSB,x
            ror 
            lsr 
            lsr 
            sta CHAR_XPOS, x
        !Exit:
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
        lda CHAR_YPOS, x
        tay
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        lda OFFSCREEN_ROW_LO, y
        sta BUFFER_ROW_PTR
        lda OFFSCREEN_ROW_HI, y
        sta BUFFER_ROW_PTR+1 

        lda CHAR_XPOS, x
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
        .label SpriteDataPtr = zpTempVector03
        .label SpriteDataPtrRight = zpTempVector01
        .label CharTemplatePtr = ZP_num2
        .label ScreenPointer = ZP_num1 
        .label ScreenChars = zpTemp04

            stx [!MaskTile+]+1
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
            sta SpriteDataPtr 
            clc 
            adc #16
            sta SpriteDataPtrRight
            lda SPRITE_DATA_TILE_MSB, x
            sta SpriteDataPtr+1 
            sta SpriteDataPtrRight+1


            // Setup the pointer to the char template
            // This is the source mem
            lda ID, x // Load the sprite id and use it as the index
            tay
            lda TEMPLATE_CHAR_MEM_LSB, y
            //sta CharTemplatePtr
            sta [!SelfModTemplateRead+]+1 
            lda TEMPLATE_CHAR_MEM_MSB, y
            //sta CharTemplatePtr+1 
            sta [!SelfModTemplateRead+]+2

            // Now update vertical shift
            ldy #0
            ldx #0
        !:
            lda #00                 // Im Default gehen wir davon aus eine transparente
                                    // Zeile (Byte) im Zeichen zu schreiben
            cpy YOffset
            bcc !Next+
            cpx #8 
            beq !Next+              // If we have copied the complete char already
                                    // skip. We continue to fill with blank lines
        !SelfModTemplateRead:
            lda $BEEF,x             // Hier ein byte aus dem Template character kopieren.

            inx
        !Next:
            sta (SpriteDataPtr), y
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
            sta (SpriteDataPtrRight), y
            ldx XOffset
            beq !NextRow+
            lda (SpriteDataPtr), y
        !:
            lsr                     // Lowest bit in carry flag
            ror TMP
            dex
            bne !- 
            sta (SpriteDataPtr), y
            lda TMP
            sta (SpriteDataPtrRight), y
        !NextRow:
            dey 
            bpl !LoopShiftX- 
        !XShiftEnd:

        // Nun das Masking
        // CharDataPointer zeigt auf das erste byte des ersten zeichens aus dem
        // Tile. SpriteDataPtrRight zeigt auf das erste byte der letzen beiden
        // Zeichen des Tiles.

    !MaskTile:

        ldx #$EE  // Self modified. Index of the sprite. 
        
        // Get the Character on the screen at the top left
        // position of the tile
        ldy CHAR_YPOS, x
        lda CHAR_XPOS, x
        tax 
        lda SCREEN.ROW_ADR.hi, y
        sta ScreenPointer+1
        lda SCREEN.ROW_ADR.lo , y
        sta ScreenPointer
        txa
        tay
        lda (ScreenPointer), y
        sta ScreenChars
        iny 
        lda (ScreenPointer), y
        sta ScreenChars+1 
        tya 
        clc
        adc #39 
        tay 
        lda (ScreenPointer), y
        sta ScreenChars+2
        iny 
        lda (ScreenPointer), y
        sta ScreenChars+3
        lda ScreenChars
        // The Screencharacter has to be in y
        // Spritedata pointer needs to point the
        // the right location in the sprite
        tay
        jsr MaskCharacter   
        clc
        lda SpriteDataPtr 
        adc #8 
        sta SpriteDataPtr
        lda SpriteDataPtr+1
        adc #00
        sta SpriteDataPtr+1
        ldy ScreenChars+2
        jsr MaskCharacter   
        lda SpriteDataPtrRight
        sta SpriteDataPtr
        lda SpriteDataPtrRight+1
        sta SpriteDataPtr+1
        ldy ScreenChars+1
        jsr MaskCharacter   
        clc
        lda SpriteDataPtr 
        adc #8 
        sta SpriteDataPtr
        lda SpriteDataPtr+1
        adc #00
        sta SpriteDataPtr+1
        ldy ScreenChars+3
        jsr MaskCharacter   
        
                
        rts
    }

    MaskCharacter: {
        .label SpriteDataPtr = zpTempVector03
        .label SpriteDataPtrRight = zpTempVector01
        .label TMP      = zpTemp02

        // Store the Byte Adress of the screen
        // space to code. This is the Source of
        // Blending
        lda CHARSET_MEM_LSB, y
        sta [!BackgroundDataPtr+]+1
        lda CHARSET_MEM_MSB, y
        sta [!BackgroundDataPtr+]+2

        ldy #7
    !Loop:

        // Load background
    !BackgroundDataPtr:
        lda $BEEF,y // Self mod adress to the fontspace
        sta TMP
        lda (SpriteDataPtr), y
        tax
        lda SPRITE_MASK_TABLE, x
        and TMP
        ora (SpriteDataPtr), y
        sta (SpriteDataPtr), y

        dey 
        bpl !Loop-  

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
        ldy CHAR_YPOS, x
        // Check, if the sprite exceeds the bottom
        cpy #25 
        bcc !+ // if y position > 25
        rts 
    !:  
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        ldy CHAR_XPOS,x   
        // Check, if the sprite exceeds the right border
        cpy #40 
        bcc !+  // If x position < 40, continue
        rts
    !:
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
            // Accu contains still the ID
            lda SPRITE_CHAR_INDEX_TABLE,x  // Load the char index of the first char of the sprite 
            sta CHAR_INDEX,x 

            tya
            sta YPOS,x
            // Calculate char ypos by dividing by 8
            lsr 
            lsr 
            lsr 
            sta CHAR_YPOS,x  
            lda TMP_SPRITE_XPOS
            asl // Multiply xposition by two, because we are in multi color mode.
                // Each pixel takes two bits (and is diesplayd in double width)
            sta XPOS_LSB,x
            lda #0 
            rol 
            sta XPOS_MSB,x

            // Now calculate the xpos in char space
            lsr 
            lda XPOS_LSB,x
            ror 
            lsr 
            lsr 
            sta CHAR_XPOS,x 
            
            // Update next sprite index
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

    CalculateFontPtrTable: {
            ldx #0
            lda #<CHARSET 
            sta CHARSET_MEM_LSB
            lda #>CHARSET 
            sta CHARSET_MEM_MSB
             
        !Loop:
            lda CHARSET_MEM_MSB, x 
            sta CHARSET_MEM_MSB+1, x
            lda CHARSET_MEM_LSB, x
            inx
            clc 
            adc #8 
            sta CHARSET_MEM_LSB, x
            lda CHARSET_MEM_MSB, x
            adc #0 
            sta CHARSET_MEM_MSB, x
            cpx #$ff 
            bne !Loop- 

        rts             
    }
}
