\ Graphic shapes
\ Content mostly ported from Adafruit GFX by Craig A. Lindley
\ Last Update: 08/14/2021
\ Must have display driver loaded

\ Draw a rectangle with color
: rect  { x0 y0 x1 y1 color -- }
  x0 y0 x1 x0 - color hLine
  x0 y1 x1 x0 - color hLine
  x0 y0 y1 y0 - color vLine
  x1 y0 y1 y0 - color vLine
;

: rect2  { x y width height color }
  x y width            color hLine
  x y height + width   color hLine
  x y         height   color vLine
  x width + y height   color vLine
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

