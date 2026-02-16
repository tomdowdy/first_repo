\ 16 bit Color Functions
\ Written for ESP32forth
\ Written By: Craig A. Lindley
\ Last Update: 01/17/2022

\ Percent of full brightness
50 value BRIGHTNESS

\ Function to dim color values because WS2812's are very bright
: dim ( r g b -- r g b )
  rot BRIGHTNESS * 100 /
  rot BRIGHTNESS * 100 /
  rot BRIGHTNESS * 100 /
;

\ HSV to RGB to pixel color space conversion
\ val: 0 .. 255, sat: 0 .. 255, hue: 0 .. 359
: hsvToColor16 { val sat hue } ( val sat hue -- color16 )

    \ Declare local variables
    0 0 0 0 0 0 0 0 { region fpart p q t r g b }

    \ Change range from 0 .. 359 to 0 .. 255
    hue 255 * 359 / to hue

    sat 0=
    if
        val dup dup to r to g to b
    else
        hue 43 / to region
        hue region 43 * - 6 * to fpart

        val 255 sat - * 8 >> to p
        val 255 sat fpart * 8 >> - * 8 >> to q
        val 255 sat 255 fpart - * 8 >> - * 8 >> to t

        region
        case
            0 of val to r   t to g   p to b endof
            1 of   q to r val to g   p to b endof
            2 of   p to r val to g   t to b endof
            3 of   p to r   q to g val to b endof
            4 of   t to r   p to g val to b endof
            5 of val to r   p to g   q to b endof
        endcase
    then
    \ Convert RGB color to color16
    r g  b color565
;

\ Create a full value fully saturated HSV color
: hsvColor ( index divisions -- color16)
    \ calculate hue angle and save on return stack
    swap 360 * swap / >r
    255 255 r>
    hsvToColor16
;

\ Get a color from synthesized palette of colors
256 3 /   constant range
range 2 * constant range2

: paletteColor { indx } ( r g b -- color16 )
    \ Declare local variables
    0 0 0 { r g b }

    indx 256 mod >r
    r@ 0 >= r@ range < and
    if
        255 3 r@ * -              to r
        3 r@ *                    to g
        0                         to b
    else
        r@ range >= r@ range 2 * < and
        if
            0                     to r
            255 3 r@ range - * -  to g
            3 r@ range - *        to b
        else
            3 r@ range2 - *       to r
            0                     to g
            255 3 r@ range2 - * - to b
        then
    then
    r> drop
    \ Convert RGB color to color16
    r  g  b color565
;

\ Input a value 0 to 255 to get a color value
\ The colors transition from r to g to b and then back to r
: wheel  { wPos } ( wPos -- color16 )

  255 wPos - to wPos
  wPos 85 <
  if
    255 wPos 3 * - 0 wPos 3 * color565
  else wPos 170 <
    if
      -85 +to wPos
      0 wPos 3 * 255 wPos 3 * - color565
    else
      -170 +to wPos
      wPos 3 * 255 wPos 3 * - 0   color565
    then
  then
;

\ Get a random wheel index with a min distance of 42 from indx
: getRandomWheelIndex { indx } ( indx -- newIndx )
  0 0 0 0 { r x y d }
  begin
    d 42 <
  while
    256 random0toN to r
    indx r - abs to x
    255 x - to y
    x y min to d
  repeat
  r
;

