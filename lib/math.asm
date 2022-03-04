.macro ADD_8BIT_TO_16BIT_AAAA(pInLo, pInHi, value, pOutLo, pOutHi) {
    {
        lda pInHi
        sta pOutHi
        lda pInLo
        adc #value
        sta pOutLo
        lda pOutHi   
        adc #0 
        sta pOutHi
    }

}

/*********************************************************
Der Wert Iim Akku wird, wie der Name schon sagt invertiert.
Das bedeutet, dass aus einer 1 ($01) eine -1 ($FF) werden
würde und umgekehrt.
**********************************************************/
.macro INVERT_ACCU() {
    eor #$ff
    clc 
    adc #1      // Nun ist der invertierte Wert im Akku
}


.namespace MATH {

    .macro ADD_8BIT_TO_8BIT_AAAA(p1, p2, resultLo, resultHi) {
        clc
        lda #0
        sta resultLo
        sta resultHi
        lda p1
        adc p2
        sta resultLo
        rol resultHi
    }


    .macro ADD_8BIT_TO_8BIT_VAAA(p1, p2, resultLo, resultHi) {
        clc
        lda #0
        sta resultLo
        sta resultHi
        lda #p1
        adc p2
        sta resultLo
        rol resultHi
    }

    //------------------------
    // 8bit * 8bit = 16bit multiply
    // By White Flame
    // Multiplies "num1" by "num2" and stores result in .A (low byte, also in .X) and .Y (high byte)
    // uses extra zp var "num1Hi"

    // .X and .Y get clobbered.  Change the tax/txa and tay/tya to stack or zp storage if this is an issue.
    //  idea to store 16-bit accumulator in .X and .Y instead of zp from bogax

    // In this version, both inputs must be unsigned
    // Remove the noted line to turn this into a 16bit(either) * 8bit(unsigned) = 16bit multiply.
    multiply8x8:
        lda #$00
        tay
        sty ZP_num1Hi  // remove this line for 16*8=16bit multiply
        beq enterLoop

        doAdd:
        clc
        adc ZP_num1
        tax

        tya
        adc ZP_num1Hi
        tay
        txa

        loop:
        asl ZP_num1
        rol ZP_num1Hi
        enterLoop:  // accumulating multiply entry point (enter with .A=lo, .Y=hi)
        lsr ZP_num2
        bcs doAdd
        bne loop

        // 26 bytes
        rts

    hextable:
        .byte $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $01, $02, $03, $04, $05, $06


    /**
        Wandelt das Byte im Akku zu einem zweistelligen Hexcode um. Die
        zwei Hex Codes liegen als Screencode im Akku (High Nibble) und im
        X Register (Low Nibble)

        Clobbered Registers: 
            X, Y, A

        Clobered Zero Page Adresses:
            TempByte 
    */
    convert_to_hex:
        tay
        and #$0f
        tax
        lda hextable, x
        sta zpTemp00
        tya
        clc
        ror
        ror
        ror
        ror
        and #$0f
        tax
        lda hextable, x
        ldx zpTemp00
        rts
}
