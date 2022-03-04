.namespace UTIL {
    
    .const COLLISION_FLOOR  = %0001
    .const COLLISION_BLOCK  = %0010
    .const COLLISION_LADDER = %0100
    .const COLLISION_DEATH  = %1000
    
    /**

    Read a character from screen position and
    return it. The X position is in X Register,
    the Y position in Y register.
    The result is returned in Accumulator.
      
    */
    GetCharacterAt: {
        lda SCREEN.ROW_ADR.hi, y
        sta ZP_num1Hi
        lda SCREEN.ROW_ADR.lo ,y
        sta ZP_num1
        txa 
        tay
        lda (ZP_num1),y 
        rts
    }
}
