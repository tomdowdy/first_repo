\ Misc Display Patterns
\ Written in ESP32Forth
\ Written by: Craig A. Lindley
\ Last Update: 10/17/2025

12000 constant DEFAULT_PATTERN_TIMEMS

\ Time in the future for pattern to end
0 value futureTime

\ Rainbow pluses
: rainbowPluses ( -- )

  \ Scroll string
  s" ++++++" 130 COLOR_MODE_PIXEL scrollStr
;

\ Lines support functions

\ Draw a horizontal line
: drawHLine { row color }
  24 0
  do
    i row color setPixelColRow
  loop
;

\ Draw a vertical line
: drawVLine { col color }
  8 0
  do
    col i color setPixelColRow
  loop
;

\ Draw a vertical line in color and show
: drawVLineS { col color }
  8 0
  do
    col i color setPixelColRow
  loop
  show
;

\ Draw inward horizontal lines
: inwardHLines ( -- )
  0 { color }
  4 0
  do
    256 random0toN wheel to color
  
    i color drawHLine
    7 i - color drawHLine
    show
    150 delay

    i 0 drawHLine
    7 i - 0 drawHLine
    show
    150 delay
  loop
;

\ Draw outward horizontal lines
: outwardHLines ( -- )
  0 { color }
  4 0
  do
    256 random0toN wheel to color
  
    3 i - color drawHLine
    4 i + color drawHLine
    show
    150 delay

    3 i - 0 drawHLine
    4 i + 0 drawHLine
    show
    150 delay
  loop
;

\ Draw inward vertical lines
: inwardVLines ( -- )
  0 { color }
  12 0
  do
    256 random0toN wheel to color
  
    i      color drawVLine
    23 i - color drawVLine
    show
    150 delay

    i      0 drawVLine
    23 i - 0 drawVLine
    show
    150 delay
  loop
;

\ Draw outward vertical lines
: outwardVLines ( -- )
  0 { color }
  12 0
  do
    256 random0toN wheel to color
  
    11 i - color drawVLine
    12 i + color drawVLine
    show
    150 delay

    11 i - 0 drawVLine
    12 i + 0 drawVLine
    show
    150 delay
  loop
;

\ Line display pattern
: lines ( -- )

  inwardHLines
  outwardVLines
  outwardHLines
  inwardVLines
;

\ Set all pixels to random colors and then fade to black
: randomColorsThenFade ( -- )

  \ Calculate when pattern display should end
  MS-TICKS DEFAULT_PATTERN_TIMEMS + to futureTime

  0 0 0 0 0 { r g b col row }

  begin 
    \ Pick a pixel by col and row
    COL_NUM random0toN to col
    ROW_NUM random0toN to row

    256 random0toN to r
    256 random0toN to g
    256 random0toN to b

    col row r g b color24 setPixelColRow
    show

    MS-TICKS futureTime >
  until

  \ Now dissolve all pixels

  \ Calculate when pattern display should end
  MS-TICKS DEFAULT_PATTERN_TIMEMS + to futureTime

  begin 
    \ Pick a pixel by col and row
    COL_NUM random0toN to col
    ROW_NUM random0toN to row

    col row 0 setPixelColRow
    show

    MS-TICKS futureTime >
  until
;

\ Wipes color from end to end
: colorWipe ( -- )

  0 0 { color direction }

  2 0 do
    256 random0toN wheel to color
      2 random0toN       to direction

    WS2812_COUNT 0
    do
       direction 0=
      if
        color i setPixelColor24
      else
        color WS2812_COUNT 1- i - setPixelCOlor24
      then
      show
      10 delay
    loop
  loop
;

\ Draw All Lines on Display
: drawAllLines { colorIndex }
  24 0
  do
    i colorIndex 10 * wheel drawVLineS
    1 +to colorIndex
    colorIndex COL_MAX >=
    if
      0 to colorIndex
    then
  loop
;

\ Slowly cycling rainbow colors
: rainbow ( -- )
  3 0 
  do
    24 0
    do
      i drawAllLines
    loop
  loop
;

\ Theater style crawling lights
: theaterChaseRainbow ( -- )
  
  \ Calculate when pattern display should end
  MS-TICKS DEFAULT_PATTERN_TIMEMS + to futureTime

  begin
    20 0
    do
      3 0
      do
        WS2812_COUNT 0
        do
          i k + wheel i j + setPixelColor24
          3
        +loop
        show
        120 delay
        WS2812_COUNT 0
        do
          0 i j + setPixelColor24
          3 
       +loop
      loop
    loop

    MS-TICKS futureTime >
  until
;

\ Lightning Pattern
: lightning ( -- )

  \ Calculate when pattern display should end
  MS-TICKS DEFAULT_PATTERN_TIMEMS + to futureTime

  0 0 128 128 128 color24 { col row white }

  begin
    \ Pick a pixel by col and row
    COL_NUM random0toN to col
    ROW_NUM random0toN to row

    2 random0toN 1 =
    if
      col row white setPixelColRow
    else
      col row 0     setPixelColRow
    then
    show

    MS-TICKS futureTime >
  until
;

\ Display rainbow around perimeter of display
: perimeter ( -- )

  128 random0toN { colorIndex }

  5 0 do
    \ Across the top of display
    24 0 
    do
      i 0 colorIndex wheel setPixelColRow
      6 +to colorIndex
      show
    loop

    \ Across the right side of display
    8 0
    do
      23 i colorIndex wheel setPixelColRow
      6 +to colorIndex
      show
    loop

    \ Across the bottom of display
    24 0 
    do
      23 i - 7 colorIndex wheel setPixelColRow
      6 +to colorIndex
      show
    loop

    \ Across the left side of display
    8 0
    do
      0 7 i - colorIndex wheel setPixelColRow
      6 +to colorIndex
      show
    loop
    
  loop
;

\ Plasma display pattern variables
fvariable phaseIncrement
fvariable colorStretch
fvariable phase
fvariable color_1
fvariable color_2
fvariable color_3
fvariable color_4
fvariable distance1
fvariable distance2
fvariable distance3
fvariable p1x
fvariable p1y
fvariable p2x
fvariable p2y
fvariable p3x
fvariable p3y
fvariable dist1x
fvariable dist1y
fvariable dist2x
fvariable dist2y
fvariable dist3x
fvariable dist3y

\ Plasma function
: plasma ( -- )

  \ Calculate when pattern display should end
  MS-TICKS DEFAULT_PATTERN_TIMEMS + to futureTime

  \ Initialize temp variables
  0 0 0 { r g b }

  \ Initialize variable to different values every run
  62 random0toN s>f 10.0e f/ phase sf!

  \ Controls the speed of the moving points. Higher == faster. I like 0.08
  20 random0toN s>f 100.0e f/ phaseIncrement sf!

  \ Higher numbers will produce tighter color bands. I like 0.11
  20 random0toN s>f 100.0e f/ colorStretch sf!

  begin
    phase sf@ phaseIncrement sf@ f+ phase sf!

    \ Create various point values
    phase sf@ 1.000e f* fsin 1.0e f+ 4.5e f* p1x sf!
    phase sf@ 1.310e f* fsin 1.0e f+ 4.0e f* p1y sf!
    phase sf@ 1.770e f* fsin 1.0e f+ 4.5e f* p2x sf!
    phase sf@ 2.865e f* fsin 1.0e f+ 4.0e f* p2y sf!
    phase sf@ 0.250e f* fsin 1.0e f+ 4.5e f* p3x sf!
    phase sf@ 0.750e f* fsin 1.0e f+ 4.0e f* p3y sf!

    ROW_NUM 0
    do
      COL_NUM 1 >> 0
      do
        \ Calculate the distance between this LED and p1.
        i s>f p1x sf@ f- dist1x sf!
        j s>f p1y sf@ f- dist1y sf!
        dist1x sf@ fdup f* dist1y sf@ fdup f* f+ fsqrt distance1 sf!

        \ Calculate the distance between this LED and p2.
        i s>f p2x sf@ f- dist2x sf!
        j s>f p2y sf@ f- dist2y sf!
        dist2x sf@ fdup f* dist2y sf@ fdup f* f+ fsqrt distance2 sf!

        \ Calculate the distance between this LED and p3.
        i s>f p3x sf@ f- dist3x sf!
        j s>f p3y sf@ f- dist3y sf!
        dist3x sf@ fdup f* dist3y sf@ fdup f* f+ fsqrt distance3 sf!

        \ Warp the distance with a sin() function.
        distance1 sf@ color_1 sf!
        distance2 sf@ color_2 sf!
        distance3 sf@ color_3 sf!
        distance1 sf@ distance2 sf@ colorStretch sf@ f* f* fsin 2.0e f+ 0.5e f* color_4 sf!

        color_1 sf@ color_4 sf@ f* color_1 sf! 
        color_2 sf@ color_4 sf@ f* color_2 sf! 
        color_3 sf@ color_4 sf@ f* color_3 sf! 
        color_4 sf@ fdup f*        color_4 sf! 

        \ Force colors into range 0 .. 255
        color_1 sf@ f>s to r
        r 255 > if 255 to r then
        color_2 sf@ f>s to g
        g 255 > if 255 to g then
        color_3 sf@ f>s to b
        b 255 > if 255 to b then

        \ Plot pixel
        i j r g b color24 setPixelColRow

        \ Plot mirrored pixel
        COL_NUM i - 1- j r g b color24 setPixelColRow
      loop
    loop
    show
    100 delay

    MS-TICKS futureTime >
  until
;

\ Craig Pattern
: craig ( -- )

  \ Scroll string
  s" Welcome to Craig's Place" 130 COLOR_MODE_PIXEL scrollStr
;


\ Pattern picker
: pickPattern ( -- )

  randomSeed

  true clearPixels

  12 random0toN

  case
    0 of craig                endof
    1 of lines                endof
    2 of randomColorsThenFade endof
    3 of colorWipe            endof
    4 of perimeter            endof
    5 of rainbow              endof
    6 of theaterChaseRainbow  endof
    7 of plasma               endof
    8 of lightning            endof
    9 of perimeter            endof
   10 of plasma               endof
   11 of rainbowPluses        endof
  endcase
  true clearPixels
;
