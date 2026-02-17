
\ Line drawing functions
\ Written by Craig A. Lindley
\ Last Update: 08/12/2021
\ Must have display driver loaded

\ Draw horizontal line of length with color
: hLine { x y len color }
  x y x len + y color
  fillRect
;

\ Draw vertical line of length with color
: vLine	{ x y len color }
  x y x y len + color
  fillRect
;

\ Local variables for line function below
0 value __s
0 value __de
0 value __er
0 value __dx
0 value __dy
0 value __y
0 value __t

\ Draw line with color
: line { x0 y0 x1 y1 color }
  y1 y0 - abs x1 x0 - abs > to __s 
  __s
  if
    x0 to __t y0 to x0 __t to y0
    x1 to __t y1 to x1 __t to y1
  then
  x0 x1 >
  if
    x0 to __t x1 to x0 __t to x1    
    y0 to __t y1 to y0 __t to y1
  then
  x1 x0 - to __dx
  y1 y0 - abs to __dy
  __dx 1 >> to __er
  y0 y1 <
  if 1 to __y else -1 to __y then
  x1 1+ x0 
  do
    __s
    if y0 i color pixel else i y0 color pixel then
    __er __dy - to __er
    __er 0<
    if __y +to y0 __dx +to __er then
  loop
;
