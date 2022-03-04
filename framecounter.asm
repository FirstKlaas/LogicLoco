.namespace FRAMECOUNTER {

    increment: {
        lda ZP_FrameCounter_Lo
        clc 
        adc #1 
        sta ZP_FrameCounter_Lo
        bcc !+
        inc ZP_FrameCounter_Hi
    !:
        rts
    }
    
}
