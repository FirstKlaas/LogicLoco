.macro DISABLE_SOFT_SRPITE(idx) {
    lda #0 
    ldx #[idx]
    sta SOFTSPRITE.ID, x
}

.namespace SOFTSPRITE {

    .const NUMBER_OF_SPRITES = 8



    _DATA:
        .fill NUMBER_OF_SPRITES, $00  // ID
        .fill NUMBER_OF_SPRITES, $00  // XPOS
        .fill NUMBER_OF_SPRITES, $00  // YPOS

    _ID_CHAR:
        .byte $00, $1b

    .label ID               = _DATA
    .label XPOS             = _DATA + NUMBER_OF_SPRITES
    .label YPOS             = _DATA + [2 * NUMBER_OF_SPRITES]
    .label ID_CHAR_TABLE    = _ID_CHAR

    .label SCREEN_BUFFER_PTR    = $cc00
    .label SCREEN_RAM_PTR       = $c000

    _BUF_ROW:
        .lohifill 25, SCREEN_BUFFER_PTR + 40*i

    .label OFFSCREEN_ROW_LO = _BUF_ROW.lo 
    .label OFFSCREEN_ROW_HI = _BUF_ROW.hi 
    
    .print "Softsprite Data: " + toHexString(ID)

    CURRENT_SPRITE_INDEX: .byte $00 

    Initialize: {
            lda #0
            sta CURRENT_SPRITE_INDEX
            ldx #NUMBER_OF_SPRITES-1
        !loop:
            sta ID,x 
            sta XPOS,x 
            sta YPOS,x
            dex 
            bpl !loop-
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
        tay
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        lda OFFSCREEN_ROW_LO, y
        sta BUFFER_ROW_PTR
        lda OFFSCREEN_ROW_HI, y
        sta BUFFER_ROW_PTR+1 

        lda XPOS, x
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

    // Draws a sprite
    // REG X: Index of the sprite to draw
    DrawSingleSprite: {

        .label SCREEN_ROW_PTR   = ZP_num1

        lda YPOS, x
        tay
        lda SCREEN.ROW_ADR.lo, y
        sta SCREEN_ROW_PTR
        lda SCREEN.ROW_ADR.hi, y
        sta SCREEN_ROW_PTR+1 

        lda XPOS, x 
        tay 

        // Load the Character from the charset
        lda ID, x               // Load the sprite ID 
        bne !+                  // Only continue, if ID is not zero
        rts
    !:
        tax                     // Use the ID as the table offset
        lda ID_CHAR_TABLE, x    // Load the first of the four characters into accu
        tax                     // Save the character in x register

        // Top Left
        sta (SCREEN_ROW_PTR), y

        // Top Right
        iny 
        inx  
        txa
        sta (SCREEN_ROW_PTR), y

        // Bottom Left
        tya 
        clc 
        adc #$27 
        tay 
        inx
        txa
        sta (SCREEN_ROW_PTR), y

        // Bottom Right
        iny 
        inx
        txa
        sta (SCREEN_ROW_PTR), y
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
            sta XPOS,x
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

    
}
