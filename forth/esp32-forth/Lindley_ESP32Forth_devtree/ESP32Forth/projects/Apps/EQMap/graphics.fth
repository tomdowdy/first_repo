\ Graphic Functions for the ILI9341 LCD Controller
\ Written by Craig A. Lindley
\ Last Update: 08/31/2021
\ Must have ILI9341 loaded

\ Local like variables
0 value _x1
0 value _y1

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  x0 width  + to _x1
  y0 height + to _y1
  x0 y0 _x1 _y1 color fillRect
;

\ Fill the screen with a color
: fillScreen { color }
  0 0 getLCDWidth 1- getLCDHeight 1- color fillRect
;

\ Clear the screen to black
: clearScreen ( -- )
    $0000 fillScreen
;

\ Draw vertical line of length with color
: vLine		{ x y len color -- }
  x y x y len + color
  fillRect
;

\ Local variables for functions below
0 value _f_
0 value _dx_
0 value _dy_
0 value _x_
0 value _y_

\ Draw a circle with color
: circle { x y radius color }
  1 radius - to _f_
  1 to _dx_
  -2 radius * to _dy_
  0 to _x_
  radius to _y_

  _x_ _y_ radius + color pixel
  _x_ _y_ radius - color pixel
  _x_ radius + y color pixel
  _x_ radius - y color pixel

  begin
    _x_ _y_ <
  while
    _f_ 0 >=
    if
      -1 +to _y_
      2 +to _dy_
      _dy_ +to _f_
    then
    1 +to _x_
    2 +to _dx_
    _dx_ +to _f_
    
    x _x_ + y _y_ + color pixel
    x _x_ - y _y_ + color pixel
    x _x_ + y _y_ - color pixel
    x _x_ - y _y_ - color pixel
    x _y_ + y _x_ + color pixel
    x _y_ - y _x_ + color pixel  
    x _y_ + y _x_ - color pixel
    x _y_ - y _x_ - color pixel
  repeat
;

