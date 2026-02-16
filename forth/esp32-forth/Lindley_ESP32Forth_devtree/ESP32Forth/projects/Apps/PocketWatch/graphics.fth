\ Graphic Functions for the ILI9341 LCD Controller
\ Written by Craig A. Lindley
\ Last Update: 12/15/2021
\ Must have ILI9341.fth loaded


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

