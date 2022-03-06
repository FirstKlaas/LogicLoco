/*
$c000 - $c3ff     Screen
$c400 - $c7ff  16 Sprites
$d000 - $efff 128 Sprites
$f000 - $f7ff   1 charset
$f800 - $fffd  16 Sprites
*/

* = $c000 "Screen"
    .fill 1024, $00

/*
* = $cc00 "Screenbuffer"
    .fill 1024, $00
*/
* = $d000 "Player Sprites"
    .import binary "assets\sprites.bin"
    
* = $f000 "Charset"
    .import binary "assets\charset.bin"

* = $8000 "Map Data"
MAP_TILES:
    .import binary "assets\tiles.bin"

CHAR_COLORS:
    .import binary "assets\colors.bin"

MAP_1:
    .import binary "assets\map01.bin"



