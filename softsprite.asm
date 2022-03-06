.namespace SOFTSPRITE {

    .const NUMBER_OF_SPRITES = 8


    _DATA:
        .fill NUMBER_OF_SPRITES, $00  // ID
        .fill NUMBER_OF_SPRITES, $00  // XPOS
        .fill NUMBER_OF_SPRITES, $00  // YPOS


    .label ID   = _DATA
    .label XPOS = _DATA + NUMBER_OF_SPRITES
    .label YPOS = _DATA + [2 * NUMBER_OF_SPRITES]

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
    AddSprite: {
            stx zpTemp00 
            ldx CURRENT_SPRITE_INDEX
            sta ID,x 
            tya
            sta YPOS,x 
            lda zpTemp00
            sta XPOS,x
            inx
            txa
            cmp #NUMBER_OF_SPRITES 
            bne !+ 
            lda #00 
        !:
            sta CURRENT_SPRITE_INDEX 
            rts
    }

    
}
