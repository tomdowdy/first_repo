
\ ********************* Program Entry ******************

\ Select SPI vocabulary
SPI

0 value colX
0 value rowY
0 value disp

\ App Entry Point
: main

  \ Initialize VSPI interface
  LED_CLK 4 LED_DIN LED_CS VSPI.begin
  SPI_FREQ VSPI.setFrequency

  \ Initialize LED driver
  LED_CS initMAX7219Driver

  0 setRotation

  begin
\ Test setting of pixels
\    2 0 
\    do
\      8 0
\      do
\        16 0
\        do
\          0 i j true setPixel 
\          display
\          20 delay
\        loop
\      loop
\
\      8 0
\      do
\        16 0
\        do
\          0 i j false setPixel 
\          display
\          20 delay
\        loop
\      loop
\    loop
\
\ Test rotation of display pixels on each display
\    clearDisplay
\    0 setRotation
\    4 0
\    do
\      0 i 0 true setPixel
\      1 i 0 true setPixel
\      display
\      200 delay
\    loop
\
\    1 setRotation
\    4 0
\    do
\      0 i 0 true setPixel
\      1 i 0 true setPixel
\      display
\      200 delay
\    loop
\
\    2 setRotation
\    4 0
\    do
\      0 i 0 true setPixel
\      1 i 0 true setPixel
\      display
\      200 delay
\    loop
\
\    3 setRotation
\    4 0
\    do
\      0 i 0 true setPixel
\      1 i 0 true setPixel
\      display
\      200 delay
\    loop
\
\ Test getPixel function
  clearDisplay

  50 0
  do
    2 random0toN to disp
    8 random0toN to colX
    8 random0toN to rowY

    ." disp: " disp . space ." col: " colX . space ." row: " rowY . cr
 
    \ Set selected pixel on selected display
    disp colX rowY true setPixel display
    100 delay

    \ Now read back selected pixel to check for match
    disp colX rowY getPixel 0=
    if ." getPixel mismatch" cr then
  loop

  50 0
  do
    \ Set all pixels on
    fillDisplay

    2 random0toN to disp
    8 random0toN to colX
    8 random0toN to rowY

    ." disp: " disp . space ." col: " colX . space ." row: " rowY . cr
 
    \ Clear selected pixel on selected display
    disp colX rowY false setPixel display
    100 delay

    \ Now read back selected pixel to check for match
    disp colX rowY getPixel 0<>
    if ." getPixel mismatch" cr then
  loop


    false
  until
;

only forth
