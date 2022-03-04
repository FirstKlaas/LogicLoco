.namespace PLAYER {

    .const PLAYER_BLOCK = $40

    JumpAndFallTable:
        .byte $06, $05, $04, $04
        .byte $04, $04, $02, $02
        .byte $01, $01, $01, $00    
        .byte $00
    __JumpAndFallTable:
        .byte 00
    WalkRightTable:
        .byte $40, $40, $40
        .byte $41, $41, $41
        .byte $42, $42, $42
        .byte $43, $43, $43
    __WalkRightTable:

    WalkLeftTable:
        .byte $44, $44, $44
        .byte $45, $45, $45
        .byte $46, $46, $46
        .byte $47, $47, $47

    __WalkLeftTable:

    ClimbingTable:
        .byte   $48, $48, $48, $48, $48, $48
        .byte   $49, $49, $49, $49, $49, $49
        .byte   $4A, $4A, $4A, $4A, $4A, $4A
        .byte   $49, $49, $49, $49, $49, $49
    __ClimbingTable:
    
    JumpTable:
        .byte $44, $40, $4b

    // Walk Animation Left Framecount
    .const WAL_FRAMECOUNT   = [__WalkLeftTable - WalkLeftTable]
    
    // Walk Animation Right Framecount
    .const WAR_FRAMECOUNT   = [__WalkRightTable - WalkRightTable]

    // Climbing Animation Framecount
    .const CLIMB_FRAMECOUNT = [__ClimbingTable - ClimbingTable]

    .const STATE_JUMP       = %00000001
    .const STATE_FALL       = %00000010
    .const STATE_WALK_RIGHT = %00000100
    .const STATE_WALK_LEFT  = %00001000
    .const STATE_CLIMB      = %00010000

    .const STATE_WALK       = STATE_WALK_LEFT + STATE_WALK_RIGHT
    .const STATE_MOVE       = STATE_WALK + STATE_CLIMB + STATE_FALL + STATE_JUMP

    .const COLLISION_NONE   = %00000000 // 0
    .const COLLISION_SOLID  = %00010000 // 1
    .const COLLISION_FLOOR  = %00100000 // 2
    .const COLLISION_LADDER = %01000000 // 4

    .const RESTFRAME_LEFT   = $46
    .const RESTFRAME_RIGHT  = $42
    .const RESTFRAME_CLIMB  = $4b
    .const JUMP_RIGHT_FRAME = $40 
    .const JUMP_LEFT_FRAME  = $44    
    

    .const JOY_UP           = %00001
    .const JOY_DN           = %00010
    .const JOY_LT           = %00100
    .const JOY_RT           = %01000

    .label PLAYER_SPRITE_PTR = SPRITEPOINTERS
    
    .const HEADING_RIGHT    =  1
    .const HEADING_LEFT     =  2
    .const HEADING_FRONT    =  4
    .const HEADING_UP       =  8
    .const HEADING_DOWN     = 16
    
    Init: {
            lda SPRITEACTIV
            ora #%00000001
            sta SPRITEACTIV
            lda #$16
            sta zpPlayerX
            lda #$46
            sta zpPlayerY
            lda #COLOR_GREEN
            lda #PLAYER_BLOCK
            sta SPRITEPOINTERS
            lda SPRITEMULTICOLOR
            ora #1
            sta SPRITEMULTICOLOR
            lda #COLOR_PINK
            sta SPRITEMULTICOLOR0
            lda #COLOR_WHITE
            sta SPRITEMULTICOLOR1
            lda #COLOR_PURPLE
            sta SPRITE0COLOR
            lda #0
            sta zpPlayerWalkIndex
            lda #$40
            sta zpPlayerRestFrame
            lda #0
            sta zpPlayerState
            lda #[HEADING_RIGHT]
            sta zpPlayerHeading
            
            rts
    }

    .label JOYSTICK_PORT2   = $dc00

    Control: {

        // Are we touching a ladder with our feet?
        // If not, clear the climb state
        lda zpPlayerFloorCollision
        and #[COLLISION_LADDER]
        bne !+

        // Clear the climb status (Just in case)
        lda zpPlayerState
        and #[255 - STATE_CLIMB]
        sta zpPlayerState

        !:
            lda JOYSTICK_PORT2  
            sta zpJoystick2State

        !JoyUp:
            and #[JOY_UP]
            bne !JoyDown+
            // Handle Up
            lda zpPlayerState
            and #[STATE_JUMP + STATE_FALL] // If we already fall or jump, we can skip 
            bne !JoyLeft+

            // Are we on a ladder
            lda zpPlayerFloorCollision
            and #[COLLISION_LADDER]
            bne !+
            jmp !InitiateJump+
        !:
            // Walking up the ladder 
            lda zpPlayerState
            and #[STATE_CLIMB]          // Are we already climbing?
            bne !+                      // Yes
            lda #0
            sta zpPlayerWalkIndex       // Set Animation to first Frame
            lda zpPlayerState           // Set the correct state
            and #[$ff - STATE_MOVE]
            ora #[STATE_CLIMB]
            sta zpPlayerState
            lda #RESTFRAME_CLIMB
            sta zpPlayerRestFrame

        !:
            ldx zpPlayerY
            dex
            dex 
            stx zpPlayerY
            jmp !JoyLeft+               // Now let's check left control 
        !InitiateJump:

            lda zpPlayerState
            ora #STATE_JUMP 
            sta zpPlayerState 
            lda #$00
            sta zpPlayerJumpIndex
            jmp !JoyLeft+               // If we move up, we cannot move down at the same time
        !JoyDown:
            lda zpJoystick2State
            and #[JOY_DN]
            bne !JoyLeft+

            // Fist Check, if we are on a ladder.
            // There are three cases:
            // 1. In the middle of a ladder
            //    Color Attrib = COLLISION_LADDER
            //    Going down is allowed
            // 2. On the top of a ladder
            //    Color Attrob = COLLISION_LADDER + COLLISION_FLOOR
            //    Going Down is allowed
            // 3. On the Bottom of a ladder
            //    Color Attrib = COLLISION_SOLID
            //    Going Down is not allowed.
            lda zpPlayerFloorCollision
            and #[COLLISION_LADDER]     // Are we on a ladder?            
            beq !JoyLeft+

            lda zpPlayerFloorCollision
            and #[COLLISION_SOLID]      // Are we on a floor?   
            bne !JoyLeft+               // Yes, so check joystick-left
            lda zpPlayerState
            and #[STATE_CLIMB]          // Are we already climbing?
            bne !+
            // --- CLIMBING ----------
            lda #0
            sta zpPlayerWalkIndex       // Set Animation to first Frame
            lda zpPlayerState
            and #[$ff - STATE_MOVE]
            ora #[STATE_CLIMB]
            sta zpPlayerState
        !:
            ldx zpPlayerY
            inx
            inx
            stx zpPlayerY

        !JoyLeft:
            lda zpJoystick2State
            and #[JOY_LT]
            beq !+                      // Joystick Left was pressed.
            // Joy left was not pressed. So we clear 
            // WALK LEFT STATE (It's no problem if the
            // state is not set before.)
            lda zpPlayerState
            and #[$ff - STATE_WALK_LEFT]
            sta zpPlayerState
            jmp !JoyRight+
        !:
            // Collision to the left?
            lda zpPlayerLeftCollision
            and #[COLLISION_SOLID]      // Running against an obsticle?
            beq !+                      // No
            jmp !Exit+                  // Yes. No Movement.
        !:
            // Are we falling or jumping?
            lda zpPlayerState
            and #[STATE_JUMP + STATE_FALL]
            bne !+                      // Yes. We still move to the left. But state stays the same.
            
            // Are we on a floor, solid ground or a ladder?
            lda zpPlayerFloorCollision
            and #[COLLISION_FLOOR + COLLISION_SOLID + COLLISION_LADDER]
            bne !Skip+                  // Yes
            jmp !Exit+                  // No, so no movement.

        !Skip:
            // Update State
            lda zpPlayerState 
            and #[STATE_WALK_LEFT]
            bne !+  // We are already walking left
            lda zpPlayerState
            and #[STATE_FALL + STATE_JUMP]
            bne !+ // We are falling, jumping ore climbing
            lda zpPlayerState
            // Clear fall, jump and climb state
            // Not shure, if this is really necessary
            and #[$ff - STATE_MOVE]
            // Set walk left state
            ora #[STATE_WALK_LEFT] 
            sta zpPlayerState
            // Update Restframe
            lda #RESTFRAME_LEFT
            sta zpPlayerRestFrame
        !:
            ldx zpPlayerX
            dex          
            stx zpPlayerX
            // We are heading to the left
            lda #[HEADING_LEFT]
            sta zpPlayerHeading
            jmp !Exit+              // If we move left, we cannot move right at the same time

        !JoyRight:
            lda zpJoystick2State
            and #[JOY_RT]
            beq !+
            // Joy right was not pressed. So we clear 
            // WALK RIGHT STATE (It's no problem if the
            // state is not set before.)
            lda zpPlayerState
            and #[$ff - STATE_WALK_RIGHT]
            sta zpPlayerState
            jmp !Exit+
        !:
            
            // Collision to the right?
            lda zpPlayerRightCollision
            and #[COLLISION_SOLID]      // Running against an obsticle?
            beq !+                  // No
            jmp !Exit+                  // Yes. No Movement.

        !:
            // Are we falling or jumping?
            lda zpPlayerState
            and #[STATE_JUMP + STATE_FALL]
            bne !+                      // Yes. We still move to the left. But state stays the same.
            

            // Are we on a floor, solid ground or a ladder?
            lda zpPlayerFloorCollision
            and #[COLLISION_FLOOR + COLLISION_SOLID + COLLISION_LADDER]
            bne !Skip+                  // Yes
            jmp !Exit+                  // No, so no movement.

        !Skip:
            
            // Update State
            lda zpPlayerState 
            and #[STATE_WALK_RIGHT]
            bne !+  // We are already walking right
            lda zpPlayerState
            and #[STATE_FALL + STATE_JUMP]
            bne !+ // We are falling, jumping or climbing. We may not climb.
            lda zpPlayerState
            // Clear fall, jump and climb state
            // Not shure, if this is really necessary
            and #[$ff - STATE_MOVE]
            // Set walk left state
            ora #[STATE_WALK_RIGHT] 
            sta zpPlayerState
            // Update Restframe
            lda #RESTFRAME_RIGHT
            sta zpPlayerRestFrame
        !:

            ldx zpPlayerX
            inx          
            stx zpPlayerX
            // We are heading to the right
            lda #[HEADING_RIGHT]
            sta zpPlayerHeading
            jmp !Exit+ 

        !Exit:
            rts
    }

    Draw: {
        !CheckClimbing:
            lda zpPlayerState
            and #[STATE_CLIMB]
            
            beq !CheckFalling+ 
            lda #$49
            jmp !SetSpriteBlock+
        !:

            ldx zpPlayerWalkIndex
            inx 
            cpx #CLIMB_FRAMECOUNT
            bne !+ 
            ldx #0
        !:
            stx zpPlayerWalkIndex
            lda ClimbingTable, x
            jmp !SetSpriteBlock+

        !CheckFalling:
            lda zpPlayerState
            and #[STATE_FALL]
            
            beq !CheckJumping+
            lda zpPlayerRestFrame
            jmp !SetSpriteBlock+ 

        !CheckJumping:
            lda zpPlayerState
            and #[STATE_JUMP]
            beq !CheckWalkRight+
            // Jumping to the right or to the left?
            lda zpPlayerHeading
            and #[HEADING_RIGHT]
            beq !+
            //Heading right
            lda #[JUMP_RIGHT_FRAME]
            jmp !SetSpriteBlock+ 
        !:  // Heading left
            lda #[JUMP_LEFT_FRAME]
            jmp !SetSpriteBlock+ 

        !CheckWalkRight:
            lda zpPlayerState
            and #[STATE_WALK_RIGHT]
            beq !CheckWalkLeft+
            
            ldx zpPlayerWalkIndex
            inx 
            cpx #WAR_FRAMECOUNT
            bne !+ 
            ldx #0
        !:
            stx zpPlayerWalkIndex
            lda WalkRightTable, x
            jmp !SetSpriteBlock+

        !CheckWalkLeft:
            lda zpPlayerState
            and #[STATE_WALK_LEFT]
            beq !DoNothing+ 

            ldx zpPlayerWalkIndex
            inx 
            cpx #WAL_FRAMECOUNT
            bne !+ 
            ldx #0
        !:
            stx zpPlayerWalkIndex
            lda WalkLeftTable, x
            jmp !SetSpriteBlock+

        !DoNothing:
            lda zpPlayerRestFrame
        !SetSpriteBlock:
            sta PLAYER_SPRITE_PTR    

        !SetXPosition:
            lda zpPlayerX
            clc
            rol
            sta SPRITE0X 
            bcc !+
            lda SPRITESMAXX
            ora #1
            sta SPRITESMAXX
            jmp !SetYPosition+
        !:
            lda SPRITESMAXX
            and #%11111110
            sta SPRITESMAXX
        !SetYPosition:
            lda zpPlayerY
            sta SPRITE0Y
            rts
    }

    .const PLAYER_SPRITE_BOTTOM_OFFSET      = 20
    .const PLAYER_SPRITE_LEFT_FOOT_OFFSET   = 1
    .const PLAYER_SPRITE_RIGHT_FOOT_OFFSET  = 5
    
    GetCollisions: {
            // Check left foot
            ldx #[PLAYER_SPRITE_LEFT_FOOT_OFFSET]
            ldy #[PLAYER_SPRITE_BOTTOM_OFFSET]
            jsr PLAYER.GetScreenPosition
            jsr UTIL.GetCharacterAt
            tax
            lda CHAR_COLORS,x
            sta zpPlayerFloorCollision

            // Check right foot
            ldx #[PLAYER_SPRITE_RIGHT_FOOT_OFFSET]
            ldy #[PLAYER_SPRITE_BOTTOM_OFFSET]
            jsr PLAYER.GetScreenPosition
            jsr UTIL.GetCharacterAt
            tax
            lda CHAR_COLORS,x
            ora zpPlayerFloorCollision
            and #$f0
            sta zpPlayerFloorCollision

            // Check left side
            ldx #0
            ldy #16
            jsr PLAYER.GetScreenPosition
            jsr UTIL.GetCharacterAt
            tax
            lda CHAR_COLORS,x
            and #$f0                    // Material information is in the high nibble
            sta zpPlayerLeftCollision

            //Check right side
            ldx #7
            ldy #16
            jsr PLAYER.GetScreenPosition
            jsr UTIL.GetCharacterAt
            tax
            lda CHAR_COLORS,x
            and #$f0                    // Material information is in the high nibble
            sta zpPlayerRightCollision
            rts
    }

    DrawCollision: {
            ldx #6
            ldy #16
            jsr PLAYER.GetScreenPosition

            lda SCREEN.ROW_COLOR_ADR.hi, y
            sta ZP_num1Hi
            lda SCREEN.ROW_COLOR_ADR.lo ,y
            sta ZP_num1
            txa 
            tay
            lda (ZP_num1),y
            clc
            adc #1
            and #15 
            sta (ZP_num1),y
            rts        
    }

    GetScreenPosition: {
        .const XBorderOffset = 10
        .const YBorderOffset = 50

        .label xPixelOffset = zpTemp00 
        .label yPixelOffset = zpTemp01
            
            stx xPixelOffset
            sty yPixelOffset
            
            lda zpPlayerX
            cmp #XBorderOffset
            bcs !+
            lda #XBorderOffset
        !:
            clc 
            adc xPixelOffset
            sec 
            sbc #XBorderOffset
            lsr 
            lsr
            tax

            lda zpPlayerY
            cmp #YBorderOffset
            bcs !+
            lda #YBorderOffset
        !:
            clc 
            adc yPixelOffset
            sec
            sbc #YBorderOffset
            lsr 
            lsr 
            lsr 
            tay
            rts
    }
    
    JumpAndFall: {
        !JumpStateCheck:                 // Are we jumping?
            lda zpPlayerState
            and #STATE_JUMP 
            bne !ExitFallingCheck+  // Yes, so we cannot fall.

        !CheckFalling:
            lda zpPlayerFloorCollision
            and #[COLLISION_FLOOR + COLLISION_LADDER]
            bne !NotFalling+
        !Falling:
            lda zpPlayerState
            and #STATE_FALL         // Are we already falling?
            bne !ExitJumpCheck+
            lda zpPlayerState
            ora #STATE_FALL
            sta zpPlayerState

            lda #[__JumpAndFallTable - JumpAndFallTable - 1 ]
            sta zpPlayerJumpIndex
            jmp !ExitJumpCheck+

        !NotFalling:
            lda zpPlayerState
            and #[STATE_FALL]
            beq !+ 
            lda zpPlayerY
            sec 
            sbc #$06
            and #%11111000
            ora #$06
            sta zpPlayerY
        !:
            lda zpPlayerState
            and #[$ff - STATE_FALL]
            sta zpPlayerState


        !ExitFallingCheck:

        !JumpCheck:
            lda zpPlayerState
            and #STATE_JUMP 
            beq !ExitJumpCheck+
            nop


        !ExitJumpCheck:

        !ApplyFallOrJump:

        !TestApplyFall:
            lda zpPlayerState
            and #[STATE_FALL]
            beq !Skip+

        !ApplyFall:
            ldx zpPlayerJumpIndex
            lda zpPlayerState
            and #STATE_FALL
            beq !Skip+
            lda JumpAndFallTable, x
            clc
            adc zpPlayerY
            sta zpPlayerY

            // Update JumpIndex
            dex 
            bpl !+
            ldx #0
        !:
            stx zpPlayerJumpIndex
        !Skip:

        !TestApplyJump:
            lda zpPlayerState
            and #[STATE_JUMP]
            beq !Skip+ 
        !ApplyJump:
            ldx zpPlayerJumpIndex
            lda zpPlayerY 
            sec
            sbc JumpAndFallTable, x
            sta zpPlayerY

            // Update JumpIndex
            inx
            cpx #[__JumpAndFallTable - JumpAndFallTable ]
            bne !+
            // When we reached the end of the jump animation, we 
            // change the state to falling.
            dex
            lda zpPlayerState
            and #[$ff - STATE_JUMP]
            ora #[STATE_FALL]
            sta zpPlayerState 
        !:
            stx zpPlayerJumpIndex

        !Skip:
            rts
    }
}
