\ Graphic Functions for the ILI9341 LCD Controller
\ Written by Craig A. Lindley
\ Last Update: 08/25/2021
\ Must have ILI9341 loaded

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

0 value __x1
0 value __y1

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  x0 width  + to __x1
  y0 height + to __y1
  x0 y0 __x1 __y1 color fillRect
;

\ Fill the screen with a color
: fillScreen { color }
  0 0 getLCDWidth 1- getLCDHeight 1- color fillRect
;

\ Clear the screen to black
: clearScreen ( -- )
    $0000 fillScreen
;

