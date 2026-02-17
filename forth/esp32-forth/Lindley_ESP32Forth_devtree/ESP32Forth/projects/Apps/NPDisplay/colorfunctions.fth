\ Color Functions
\ Written for ESP32Forth
\ Written By: Craig A. Lindley
\ Last Update: 09/29/2022

\ HSV to RGB to pixel color space conversion
\ val: 0 .. 255, sat: 0 .. 255, hue: 0 .. 359
: hsvToColor24 { val sat hue } ( val sat hue -- color24 )

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
    \ Convert RGB color to color24
    r g  b  color24
;

\ Create a full value fully saturated HSV color
: hsvColor ( index divisions -- color24 )
    \ calculate hue angle and save on return stack
    swap 360 * swap / >r
    255 255 r>
    hsvToColor24
;

\ Input a value 0 to 255 to get a color value
\ The colors transition from r to g to b and then back to r
: wheel  { wPos } ( wPos -- color24 )

  wPos 256 mod to wPos
  wPos 85 <
  if
    255 wPos 3 * - 0 wPos 3 * color24
  else
    wPos 170 <
    if
      -85 +to wPos
      0 wPos 3 * 255 wPos 3 * - color24
    else
      -170 +to wPos
      wPos 3 * 255 wPos 3 * - 0 color24
    then
  then
;

