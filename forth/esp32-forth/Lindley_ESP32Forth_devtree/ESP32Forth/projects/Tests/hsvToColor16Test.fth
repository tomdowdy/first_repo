\ Test of the hsvToColor16 function

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
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

\ Program entry point
: main ( -- )

 ." Test of color565 function\n"
 ." r: 255, g: 0, b: 0 - color16: " 255 0 0 color565 .hex cr
 ." r: 0, g: 255, b: 0 - color16: " 0 255 0 color565 .hex cr
 ." r: 0, g: 0, b: 255 - color16: " 0 0 255 color565 .hex cr

 cr cr
 ." Test of hsvToColor16 function" 
 ." h: 0, s: 0, v: 0 - color16: " 0 0 0 hsvToColor16 . cr
 ." h: 32, s: 32, v: 45 - color16: " 32 32 45 hsvToColor16 .hex cr
 ." h: 64, s: 64, v: 90 - color16: " 64 64 90 hsvToColor16 .hex cr
 ." h: 96, s: 96, v: 135 - color16: " 96 96 135 hsvToColor16 .hex cr
 ." h: 128, s: 128, v: 180 - color16: " 128 128 180 hsvToColor16 .hex cr
 ." h: 160, s: 160, v: 225 - color16: " 160 160 225 hsvToColor16 .hex cr
 ." h: 192, s: 192, v: 270 - color16: " 192 192 270 hsvToColor16 .hex cr
 ." h: 224, s: 224, v: 315 - color16: " 224 224 315 hsvToColor16 .hex cr
 ." h: 224, s: 0, v: 315 - color16: " 224 0 315 hsvToColor16 .hex cr
;


