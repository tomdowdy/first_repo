\ Color Functions
\ Written for ESP32Forth
\ Written By: Craig A. Lindley
\ Last Update: 09/10/2021

\ Percent of full brightness
20 value BRIGHTNESS

\ Function to dim color values because WS2812's are very bright
: dim ( r g b -- r g b )
  rot BRIGHTNESS * 100 /
  rot BRIGHTNESS * 100 /
  rot BRIGHTNESS * 100 /
;

\ Convert indiviual RGB color components into 24 bit color
\ NOTE: Code is for Ws2812's with color order GRB 
: color24  ( r g b -- color24 ) dim -rot 16 << -rot 8 << -rot or or ;

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

