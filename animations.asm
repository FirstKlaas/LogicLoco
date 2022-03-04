.namespace ANIMATION {

    .label DOOR_CHAR = $f000 + ($58*8)

    animate_door: {

            lda ZP_FrameCounter
            and #03
            beq !+
            rts
        !:
            ldx #7
            
        !loop:
            lda DOOR_CHAR,x
            clc
            rol 
            bcc !+ 
            ora #1
        !:
            clc
            rol 
            bcc !+ 
            ora #1
        !:
            sta DOOR_CHAR,x
            dex
            bpl !loop-
            rts
    }
}
