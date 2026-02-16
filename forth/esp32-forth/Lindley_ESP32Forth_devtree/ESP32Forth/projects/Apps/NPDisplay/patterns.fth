\ Misc Display Patterns
\ Written in ESP32Forth
\ Written by: Craig A. Lindley
\ Last Update: 09/29/2022

12000 constant DEFAULT_PATTERN_TIMEMS

\ Time in the future for pattern to end
0 value futureTime

\ Rainbow pluses
: rainbowPluses ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS + to futureTime

  begin

    \ Scroll string
    s" ++++++" 150 COLOR_MODE_PIXEL scrollStr
  
    MS-TICKS futureTime >
  until
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
: lines { durationMS }

  \ Calculate when pattern display should end
  MS-TICKS durationMS + to futureTime

  begin

    inwardHLines
    outwardVLines
    outwardHLines
    inwardVLines

    MS-TICKS futureTime >
  until
;

\ Set all pixels to a random color
: allRandomFade { durationMS } ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS durationMS + to futureTime

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
  MS-TICKS durationMS + to futureTime

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
: colorWipe { durationMS } ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS durationMS + to futureTime

  0 0 { color direction }

  begin

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

    MS-TICKS futureTime >
  until
;

\ Slowly cycling rainbow colors
: rainbow { durationMS } ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS durationMS + to futureTime

  begin
    300 0
    do
      WS2812_COUNT 0
      do
        i 256 * WS2812_COUNT / j + 256 mod wheel i setPixelColor24
      loop
      show
    loop

    MS-TICKS futureTime >
  until
;

\ Theater style crawling lights
: theaterChaseRainbow { durationMS } ( durationMS -- )
  
  \ Calculate when pattern display should end
  MS-TICKS durationMS + to futureTime

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
: lightning ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS + to futureTime

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
: perimeter ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS + to futureTime

  128 random0toN { colorIndex }

  begin
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

    MS-TICKS futureTime >
  until
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
: plasma ( durationMS -- )

  \ Calculate when pattern display should end
  MS-TICKS + to futureTime

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

\ Pattern picker
: pickPattern ( -- )

  randomSeed

  true clearPixels

  10 random0toN
  case
    0 of DEFAULT_PATTERN_TIMEMS lines               endof
    1 of DEFAULT_PATTERN_TIMEMS allRandomFade       endof
    2 of DEFAULT_PATTERN_TIMEMS colorWipe           endof
    3 of DEFAULT_PATTERN_TIMEMS rainbow             endof
    4 of DEFAULT_PATTERN_TIMEMS theaterChaseRainbow endof
    5 of DEFAULT_PATTERN_TIMEMS plasma              endof
    6 of DEFAULT_PATTERN_TIMEMS lightning           endof
    7 of DEFAULT_PATTERN_TIMEMS perimeter           endof
    8 of DEFAULT_PATTERN_TIMEMS plasma              endof
    9 of DEFAULT_PATTERN_TIMEMS rainbowPluses       endof
  endcase
  true clearPixels
;
