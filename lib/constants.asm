//*******************************************************************************
//*** Farben                                                                  ***
//*******************************************************************************
    .const COLOR_BLACK         = $00           //schwarz
    .const COLOR_WHITE         = $01           //weiß
    .const COLOR_RED           = $02           ////rot
    .const COLOR_CYAN          = $03           //türkis
    .const COLOR_PURPLE        = $04           //lila
    .const COLOR_GREEN         = $05           //grün
    .const COLOR_BLUE          = $06           //blau
    .const COLOR_YELLOW        = $07           //gelb
    .const COLOR_ORANGE        = $08           //orange
    .const COLOR_BROWN         = $09           //braun
    .const COLOR_PINK          = $0a           //rosa
    .const COLOR_DARKGREY      = $0b           //dunkelgrau
    .const COLOR_GREY          = $0c           //grau
    .const COLOR_LIGHTGREEN    = $0d           //hellgrün
    .const COLOR_LIGHTBLUE     = $0e           //hellblau
    .const COLOR_LIGHTGREY     = $0f           //hellgrau

    .const MULTICOLOR_BLACK    = $08           //orange
    .const MULTICOLOR_WHITE    = $09           //braun
    .const MULTICOLOR_RED      = $0a           //rosa
    .const MULTICOLOR_CYAN     = $0b           //dunkelgrau
    .const MULTICOLOR_PINK     = $0c           //grau
    .const MULTICOLOR_GREEN    = $0d           //hellgrün
    .const MULTICOLOR_BLUE     = $0e           //hellblau
    .const MULTICOLOR_YELLOW   = $0f           //hellgrau


    .const SPRITE_MIN_X        = $18           // Mindestabstand links (Rahmen)
    .const SPRITE_MIN_Y        = $32           // Mindestabstand oben (Rahmen)
    

//*******************************************************************************
//*** Die VIC II Register  -  ANFANG                                          ***
//*******************************************************************************
    .label VICBASE             = $d000         //(RG) = Register-Nr.
    .label SPRITE0X            = $d000         //(00) X-Position von Sprite 0
    .label SPRITE0Y            = $d001         //(01) Y-Position von Sprite 0
    .label SPRITE1X            = $d002         //(02) X-Position von Sprite 1
    .label SPRITE1Y            = $d003         //(03) Y-Position von Sprite 1
    .label SPRITE2X            = $d004         //(04) X-Position von Sprite 2
    .label SPRITE2Y            = $d005         //(05) Y-Position von Sprite 2
    .label SPRITE3X            = $d006         //(06) X-Position von Sprite 3
    .label SPRITE3Y            = $d007         //(07) Y-Position von Sprite 3
    .label SPRITE4X            = $d008         //(08) X-Position von Sprite 4
    .label SPRITE4Y            = $d009         //(09) Y-Position von Sprite 4
    .label SPRITE5X            = $d00a         //(10) X-Position von Sprite 5
    .label SPRITE5Y            = $d00b         //(11) Y-Position von Sprite 5
    .label SPRITE6X            = $d00c         //(12) X-Position von Sprite 6
    .label SPRITE6Y            = $d00d         //(13) Y-Position von Sprite 6
    .label SPRITE7X            = $d00e         //(14) X-Position von Sprite 7
    .label SPRITE7Y            = $d00f         //(15) Y-Position von Sprite 7
    .label SPRITESMAXX         = $d010         //(16) Höhstes BIT der jeweiligen X-Position
                                               //        da der BS 320 Punkte breit ist reicht
                                               //        ein BYTE für die X-Position nicht aus!
                                               //        Daher wird hier das 9. Bit der X-Pos
                                               //        gespeichert. BIT-Nr. (0-7) = Sprite-Nr.
    .label CTRLREG1            = $d011         // Controlregister 1. Each Bit has a different function
                                               // Bit 7: Bit 9 of RASTERLINE
    .label REG_RASTERLINE      = $d012         // Current raster line (read) or to trigger IRQ (write)
    .label SPRITEACTIV         = $d015         //(21) Bestimmt welche Sprites sichtbar sind
                                               //        Bit-Nr. = Sprite-Nr.
    .label CTRLREG2            = $d016
    .label SPRITEDOUBLEHEIGHT  = $d017         //(23) Doppelte Höhe der Sprites
                                               //        Bit-Nr. = Sprite-Nr.
    .label SCREENMEMORYCTRL    = $d018         // Wo liegt der Zeichensatz und der Screen memory  
    .label IRQSTATUS           = $d019         // Status Register für den Interrupt
    .label INTERRUPTMASK       = $d01a
    .label SPRITEDEEP          = $d01b         //(27) Legt fest ob ein Sprite vor oder hinter
                                               //        dem Hintergrund erscheinen soll.
                                               //        Bit = 1: Hintergrund vor dem Sprite
                                               //        Bit-Nr. = Sprite-Nr.
    .label SPRITEMULTICOLOR    = $d01c         //(28) Bit = 1: Multicolor Sprite 
                                               //        Bit-Nr. = Sprite-Nr.
    .label SPRITEDOUBLEWIDTH   = $d01d         //(29) Bit = 1: Doppelte Breite des Sprites
                                               //        Bit-Nr. = Sprite-Nr.
    .label SPRITESPRITECOLL    = $d01e         //(30) Bit = 1: Kollision zweier Sprites
                                               //        Bit-Nr. = Sprite-Nr.
                                               //        Der Inhalt wird beim Lesen gelöscht!!
    .label SPRITEBACKGROUNDCOLL= $d01f         //(31) Bit = 1: Sprite / Hintergrund Kollision
                                               //        Bit-Nr. = Sprite-Nr.
                                               //        Der Inhalt wird beim Lesen gelöscht!
    .label INTERRUPT_REQUEST   = $d019
    .label BORDER_COLOR        = $d020        
    .label BACKGROUND_COLOR    = $d021
    .label TEXTMULTICOLOR1     = $d022 
    .label TEXTMULTICOLOR2     = $d023 
    .label SPRITEMULTICOLOR0   = $d025         //(37) Spritefarbe 0 im Multicolormodus
    .label SPRITEMULTICOLOR1   = $d026         //(38) Spritefarbe 1 im Multicolormodus
    .label SPRITE0COLOR        = $d027         //(39) Farbe von Sprite 0
    .label SPRITE1COLOR        = $d028         //(40) Farbe von Sprite 1
    .label SPRITE2COLOR        = $d029         //(41) Farbe von Sprite 2
    .label SPRITE3COLOR        = $d02a         //(42) Farbe von Sprite 3
    .label SPRITE4COLOR        = $d02b         //(43) Farbe von Sprite 4
    .label SPRITE5COLOR        = $d02c         //(44) Farbe von Sprite 5
    .label SPRITE6COLOR        = $d02d         //(45) Farbe von Sprite 6
    .label SPRITE7COLOR        = $d02e         //(46) Farbe von Sprite 7

    .label COLORRAM            = $d800
//*******************************************************************************
//*** Die VIC II Register  -  ENDE                                            ***
//*******************************************************************************


    .label IRQVECTOR           = $0314             // LSB IRQ Routine (MSB in $0315)

    .label SCREENRAM           = $c000             //Beginn des Bildschirmspeichers
    .label SPRITEPOINTERS      = SCREENRAM+$03f8   //Acht Byte der Sprite-Pointer                                                   //Adresse der Sprite-0-Daten
    
    .label CIA1_A              = $dc00             //Adresse des CIA1-A
    .label CIA1_B              = $dc01             //Adresse des CIA1-B
    .label CIA2_INTERRUPT_CRTL = $dd0d             //Interrupt Control und Status

    .const INPUT_NONE          = $00               // Es wurde noch kein Port gewählt
    .const INPUT_JOY1          = $01               // Joystick in Port-1
    .const INPUT_JOY2          = $02               // oder 2
    .const JOY_UP              = %00000001         // Joystick rauf
    .const JOY_DOWN            = %00000010         // Joystick runter
    .const JOY_LEFT            = %00000100         // Joystick links
    .const JOY_RIGHT           = %00001000         // Joystick rechts
    .const JOY_FIRE            = %00010000         // Joystick FEUER!
