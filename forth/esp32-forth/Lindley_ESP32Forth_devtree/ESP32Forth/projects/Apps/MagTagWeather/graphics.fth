\ Graphic Functions for the IL0373 EPaper Display Controller
\ Written in ESP32Forth
\ Written by: Craig A. Lindley
\ Last Update: 03/11/2023
\

\ Draw horizontal line of length with color
: hLine		{ x y len color }
  len 0
  do
    i x + y color pixel
  loop
;

\ Draw vertical line of length with color
: vLine		{ x y len color }
  len 0
  do
    x i y + color pixel
  loop
;

\ Fill a rectangle on the display - slightly different signature
: fillRectangle { x0 y0 width height color }

  height 0
  do
    width 0
    do
      i x0 + j y0 + color pixel
    loop
  loop
;

\ Quarter circle drawer used to do circles and rounded rects
: drawCircleHelper  { x y radius cornerflags color }

  0 0 0 0 0 { _f_ _dx_ _dy_ _x_ _y_ }

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



