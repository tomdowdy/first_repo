\ Graphic Functions
\ Written by Craig A. Lindley
\ Last Update: 11/24/2024


\ Draw horizontal line of length with color
: hLine		{ x y len color -- }
  x y x len + 1- y color
  fillRect
;

\ Draw vertical line of length with color
: vLine		{ x y len color -- }
  x y x y len + 1- color
  fillRect
;

\ Draw line with color
: line { x0 y0 x1 y1 c }

  \ Create locals
  0 0 0 0 0 0 0 { s de er dx dy y t }

  y1 y0 - abs x1 x0 - abs > to s 
  s
  if
    x0 to t y0 to x0 t to y0
    x1 to t y1 to x1 t to y1
  then
  x0 x1 >
  if
    x0 to t x1 to x0 t to x1    
    y0 to t y1 to y0 t to y1
  then
  x1 x0 - to dx
  y1 y0 - abs to dy
  dx 1 >> to er
  y0 y1 <
  if 1 to y else -1 to y then
  x1 1+ x0 
  do
    s
    if y0 i c pixel else i y0 c pixel then
    er dy - to er
    er 0<
    if y +to y0 dx +to er then
  loop
;

\ Draw a triangle
: drawTriangle { x1 y1 x2 y2 x3 y3 color }
  x1 y1 x2 y2 color line
  x1 y1 x3 y3 color line
  x2 y2 x3 y3 color line
;

\ Draw a rectangle
: drawRect { x y w h color }
  x y w        color hLine
  x y h + 1- w color hLine
  x y h        color vLine
  x w + 1- y h color vLine
;

\ Draw a multi-display circle with color
: circle { xc yc radius color }
  1 radius - 1 -2 radius * 0 radius { f dx dy x y }

  xc yc radius + color pixel
  xc yc radius - color pixel
  xc radius + yc color pixel
  xc radius - yc color pixel

  begin
    x y <
  while
    f 0 >=
    if
      y 1- to y
      dy 2 + to dy 
      f dy + to f 
    then
    x 1+ to x 
    dx 2 + to dx 
    f dx + to f 

    xc x + yc y + color pixel
    xc x - yc y + color pixel
    xc x + yc y - color pixel
    xc x - yc y - color pixel
    xc y + yc x + color pixel
    xc y - yc x + color pixel
    xc y + yc x - color pixel
    xc y - yc x - color pixel
  repeat
;

\ Local variables for functions below
0 value _f_
0 value _dx_
0 value _dy_
0 value _x_
0 value _y_

\ Quarter circle drawer used to do circles and rounded rects
: drawCircleHelper  { x y radius cornerflags color }
  1 radius - to _f_
  1 to _dx_
  -2 radius * to _dy_
  0 to _x_
  radius to _y_

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

    cornerflags 4 and
    if x _x_ + y _y_ + color pixel x _y_ + y _x_ + color pixel then
    cornerflags 2 and
    if x _x_ + y _y_ - color pixel x _y_ + y _x_ - color pixel then
    cornerflags 8 and
    if x _y_ - y _x_ + color pixel x _x_ - y _y_ + color pixel then
    cornerflags 1 and
    if x _y_ - y _x_ - color pixel x _x_ - y _y_ - color pixel then
  repeat
;

\ Quarter circle drawer with fill used to do circles and rounded rects
: fillCircleHelper { x y radius cornerflags delta color }
  1 radius - to _f_
  1 to _dx_
  -2 radius * to _dy_
  0 to _x_
  radius to _y_

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

    cornerflags 1 and
    if
      x _x_ + y _y_ - 2 _y_ * 1+ delta + color vLine   
      x _y_ + y _x_ - 2 _x_ * 1+ delta + color vLine   
    then
    cornerflags 2 and
    if
      x _x_ - y _y_ - 2 _y_ * 1+ delta + color vLine   
      x _y_ - y _x_ - 2 _x_ * 1+ delta + color vLine   
    then
  repeat
;


\ Draw a filled circle
: fillCircle  { x y radius color }
  x y radius - 2 radius * 1+ color vLine
  x y radius 3 0 color fillCircleHelper
;

\ Draw a rounded rect
: roundedRect  { x y width height radius color }
  \ Draw outline
  x radius +   y             width  2 radius * - color hLine
  x radius +   y height + 1- width  2 radius * - color hLine
  x            y radius +    height 2 radius * - color vline
  x width + 1- y radius +    height 2 radius * - color vline
  \ Draw corners
  x radius +             y radius +              radius 1 color drawCircleHelper
  x width + radius - 1-  y radius +              radius 2 color drawCircleHelper
  x width + radius - 1-  y height +  radius - 1- radius 4 color drawCircleHelper
  x radius +             y height +  radius - 1- radius 8 color drawCircleHelper
;

\ Draw a filled rounded rect
: fillRoundedRect { x y width height radius color }
  x radius + y width 2 radius * - height color fillRect2

  \ Draw four corners
  x width + radius - 1- y radius + radius 1 height 2 radius * - 1- color fillCircleHelper
  x radius +            y radius + radius 2 height 2 radius * - 1- color fillCircleHelper
;


