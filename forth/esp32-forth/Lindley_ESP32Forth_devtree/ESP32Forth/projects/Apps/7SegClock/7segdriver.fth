\ 7 Segment Display Driver
\ Written for ESP32Forth
\ Written By: Craig A. Lindley
\ Last Update: 09/11/2021

\ Separator control
\ Set to black to turn separator off
: setSeparator { color24 }

  color24 0 segmentsArray setPixelColor24
  show
;

\ Clear a specified 7 segment display
\ dispNum: 0 .. 3
: clearDisplay { dispNum }

  dispNum 7 * 1+ { offset }
  7 0
  do
    0 0 0 offset i + segmentsArray setPixelRGB
  loop
  show
;

\ Set a specified 7 segment display to a color
\ dispNum: 0 .. 3
: setDisplay { dispNum color24 }

  dispNum 7 * 1+ { offset }
  7 0
  do
    color24 offset i + segmentsArray setPixelColor24
  loop
  show
;

\ Display a numeric digit on specified 7 segment display with specified color
\ dispNum: 0 .. 3; num: 0 .. 9
: displayANumber1 { dispNum num color24 } ( dispNum num color24 -- )

  \ First clear the specified display
  dispNum clearDisplay

  \ Calculate segment offset for dispNum
  dispNum 7 * 1+ { offset }
  num
  case
    0 of      
      color24 offset     segmentsArray setPixelColor24
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 4 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    1 of
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
    endof
    2 of
      color24 offset     segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 4 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    3 of
      color24 offset     segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    4 of
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
    endof
    5 of
      color24 offset     segmentsArray setPixelColor24
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    6 of      
      color24 offset     segmentsArray setPixelColor24
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 4 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    7 of
      color24 offset     segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
    endof
    8 of      
      color24 offset     segmentsArray setPixelColor24
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 4 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
    9 of
      color24 offset     segmentsArray setPixelColor24
      color24 offset 1+  segmentsArray setPixelColor24
      color24 offset 2 + segmentsArray setPixelColor24
      color24 offset 3 + segmentsArray setPixelColor24
      color24 offset 5 + segmentsArray setPixelColor24
      color24 offset 6 + segmentsArray setPixelColor24
    endof
  endcase
  show
;

\ Dynamic color variables
0 value colorIndex
0 value colorDivisions

\ Initialize dynamic color selection with specified number of divisions
: initDynamicColorSelection1 (  divisions -- )
  
  to colorDivisions

  \ Then pick a random color index to start with
  colorDivisions random0toN to colorIndex
;

\ Initialize dynamic color selection with random number of divisions
: initDynamicColorSelection2 ( -- )

  \ Pick a random number of color divisions
  7 WS2812_COUNT 3 * randomNtoM to colorDivisions

  \ Then pick a random color index to start with
  colorDivisions random0toN to colorIndex
;

\ Do the initialize now
initDynamicColorSelection2

\ Dynamic Color Selector
: dynamicColorSelector ( -- color24 )
  colorIndex colorDivisions hsvColor
  1 +to colorIndex
  colorIndex colorDivisions >=
  if
    0 to colorIndex
  then
;

\ Display a numeric digit on specified 7 segment display with dynamic color segments
\ dispNum: 0 .. 3; num: 0 .. 9
: displayANumber2 { dispNum num } ( dispNum num -- )

  \ First clear the specified display
  dispNum clearDisplay

  \ Calculate segment offset for dispNum
  dispNum 7 * 1+ { offset }
  num
  case
    0 of      
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 4 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    1 of
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
    endof
    2 of
      dynamicColorSelector offset     segmentsArray setPixelcolor24
      dynamicColorSelector offset 2 + segmentsArray setPixelcolor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 4 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    3 of
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    4 of
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
    endof
    5 of
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    6 of      
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 4 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    7 of
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
    endof
    8 of      
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 4 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
    9 of
      dynamicColorSelector offset     segmentsArray setPixelColor24
      dynamicColorSelector offset 1+  segmentsArray setPixelColor24
      dynamicColorSelector offset 2 + segmentsArray setPixelColor24
      dynamicColorSelector offset 3 + segmentsArray setPixelColor24
      dynamicColorSelector offset 5 + segmentsArray setPixelColor24
      dynamicColorSelector offset 6 + segmentsArray setPixelColor24
    endof
  endcase
  show
;
