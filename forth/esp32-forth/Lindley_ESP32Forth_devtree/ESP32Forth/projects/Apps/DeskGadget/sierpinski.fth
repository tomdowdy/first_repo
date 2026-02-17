\ ESP32Forth Desk Gadget - Sierpinski Triangles Display Pattern
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/16/2022
\

 220 constant OFFSET
3000 constant UPDATE_DELAYMS

   0 value maxDepth
   0 value colorInc
   0 value colorIndex
   0 value color

\ Using defer because of recursion
defer subTri

: subTriangle { level x1 y1 x2 y2 x3 y3 } 

  x1 y1 x2 y2 x3 y3 color drawTriangle

  level maxDepth <
  if

    level 1+

    \ Smaller triangle 1
    x1 x2 + 2 / x2 x3 - 2 / +
    y1 y2 + 2 / y2 y3 - 2 / +
    x1 x2 + 2 / x1 x3 - 2 / +
    y1 y2 + 2 / y1 y3 - 2 / +
    x1 x2 + 2 /
    y1 y2 + 2 /
    subTri

    level 1+

    \ Smaller triangle 2
    x3 x2 + 2 / x2 x1 - 2 / +
    y3 y2 + 2 / y2 y1 - 2 / +
    x3 x2 + 2 / x3 x1 - 2 / +
    y3 y2 + 2 / y3 y1 - 2 / +
    x3 x2 + 2 /
    y3 y2 + 2 /
    subTri

    level 1+

    \ Smaller triangle 3
    x1 x3 + 2 / x3 x2 - 2 / +
    y1 y3 + 2 / y3 y2 - 2 / +
    x1 x3 + 2 / x1 x2 - 2 / +
    y1 y3 + 2 / y1 y2 - 2 / +
    x1 x3 + 2 /
    y1 y3 + 2 /
    subTri

  then
  80 ms
;

\ This function only draws one triangle, the outer triangle
\ and then starts the recursive process
: drawSierpinski { x1 y1 x2 y2 x3 y3 }

  colorIndex Palette @ to color
  colorInc +to colorIndex
  colorIndex PAL_SIZE >
  if
    colorIndex PAL_SIZE - to colorIndex
  then

  x1 y1 x2 y2 x3 y3 color drawTriangle

  \ Call the recursive function that will draw all the rest.
  \ The 3 corners of it are always the centers of the sides, so they are averages
  1
  x1 x2 + 2 /
  y1 y2 + 2 /
  x1 x3 + 2 /
  y1 y3 + 2 /
  x2 x3 + 2 /
  y2 y3 + 2 /
  subTriangle
;

' subTriangle is subTri

\ Sierpinski triangle display pattern
: doSierpinski ( -- returnReason )

  0 0 0 0 0 0 { _x1 _y1 _x2 _y2 _x3 _y3 }

  begin

    2 random0toN 0=
    if  
      WHITE fillScreen
    else
      BLACK fillScreen
    then
    4 random0toN
    case
      0
      of
        \ Tip at top
        XMID            to _x1
        offset          to _y1
        offset          to _x2
        HEIGHT offset - to _y2
        WIDTH  offset - to _x3
        _y2             to _y3
      endof

      1
      of
        \ Tip at bottom
        offset          to _x1
        offset          to _y1
        WIDTH offset -  to _x2
        _y1             to _y2
        XMID            to _x3
        HEIGHT offset - to _y3
      endof

      2
      of
        \ Tip at left
        offset          to _x1
        YMID            to _y1
        WIDTH offset -  to _x2
        offset          to _y2
        _x2             to _x3
        HEIGHT offset - to _y3
      endof

      3
      of
        \ Tip at right
        offset          to _x1
        offset          to _y1
        WIDTH offset -  to _x2
        YMID            to _y2
        _x1             to _x3
        HEIGHT offset - to _y3
      endof
    endcase

    3 6 randomNtoM to maxDepth 
    PAL_SIZE maxDepth / to colorInc
    NUM_PALETTES random0toN genPalette
    PAL_SIZE random0toN to colorIndex

    \ Draw
    _x1 _y1 _x2 _y2 _x3 _y3 drawSierpinski

    UPDATE_DELAYMS ms

    \ Check for pattern exit
    checkForExit

  until
  returnReason
;
