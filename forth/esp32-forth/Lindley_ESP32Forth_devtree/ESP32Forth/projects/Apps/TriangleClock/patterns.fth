\ Display Patterns for the Triangle Clock

\ Pattern display duration
25                           constant PATTERN_DURATION_SECS
PATTERN_DURATION_SECS 1000 * constant PATTERN_DURATION_MS

\ Number of available display patterns
2 constant NUMBER_OF_PATTERNS

\ Misc Functions

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

\ Color Values
                       0 constant COLOR0
225 255   0 hsvToColor24 constant COLOR1
225 255  60 hsvToColor24 constant COLOR2
225 255 120 hsvToColor24 constant COLOR3
225 255 180 hsvToColor24 constant COLOR4
225 255 240 hsvToColor24 constant COLOR5
225 255 300 hsvToColor24 constant COLOR6

COLOR0 COLOR0 COLOR0
COLOR1 COLOR1 COLOR1
COLOR0 COLOR0 COLOR0 
COLOR2 COLOR2 COLOR2
COLOR0 COLOR0 COLOR0 
COLOR3 COLOR3 COLOR3
COLOR0 COLOR0 COLOR0  
COLOR4 COLOR4 COLOR4
COLOR0 COLOR0 COLOR0  
COLOR5 COLOR5 COLOR5
COLOR0 COLOR0 COLOR0  
COLOR6 COLOR6 COLOR6
36 initializedArray COLOR_ARRAY

\ TriPattern
: triPattern ( -- )

  0 { colorIndex }

  \ Calculate time to end display pattern
  ms-ticks PATTERN_DURATION_MS + { endTime }
 
  begin
    WS2812_COUNT 0
    do
      colorIndex COLOR_ARRAY i setPixelColor24
    
      1 +to colorIndex
      colorIndex 36 mod to colorIndex
    loop
    showPixels

    250 delay

    ms-ticks endTime >
  until
;

\ RainbowPattern
: rainbowPattern ( -- )

  \ Pick a random hue separation value 
  3 30 randomNtoM 0 0 { hueSep hue val }

  \ Pick a color value
  2 random0toN 
  0=
  if 
    128 to val
  else
    255 to val
  then
 
  \ Calculate time to end display pattern
  ms-ticks PATTERN_DURATION_MS + { endTime }
 
  begin
    WS2812_COUNT 0
    do
      \ Pick a hue
      val 255 hue hsvToColor24 i setPixelColor24

      hueSep +to hue
      hue 360 mod to hue
      showPixels
    loop

    250 delay

    ms-ticks endTime >
  until
;

\ Randomly pick a pattern for display
: pickPattern ( -- )

  NUMBER_OF_PATTERNS random0toN
  case
    0 OF triPattern     ENDOF
    1 OF rainbowPattern ENDOF
  endcase

  \ Turn off display
  true clearPixels
;
