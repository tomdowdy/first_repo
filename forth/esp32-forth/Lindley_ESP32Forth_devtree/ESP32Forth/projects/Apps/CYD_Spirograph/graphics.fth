\ Graphic Functions for the Spirograph App
\ Written by Craig A. Lindley
\ Last Update: 05/24/2024
\ Must have ILI9341 loaded

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

\ Fill the screen with a color
: fillScreen { color }
  0 0 getLCDWidth 1- getLCDHeight 1- color fillRect
;

\ Clear the screen to black
: clearScreen ( -- )
    $0000 fillScreen
;

