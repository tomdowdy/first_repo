\ ESP32Forth Desk Gadget - Webs Display Pattern
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/16/2022
\

\ Ratio of display width to height expressed as floating point number
1.333333e fconstant fRatio

\ Webs display pattern
: doWebs ( -- returnReason )

  0 0 { _indx _color }

  BLACK fillScreen

  begin
    _indx getRandomWheelIndex to _indx
    _indx wheel to _color
    getLCDHeight 0
    do
      0 i i s>f fRatio f* f>s 239 _color line
      30 ms
      5
    +loop
    
    _indx getRandomWheelIndex to _indx
    _indx wheel to _color
    0 getLCDHeight 1-
    do
      319 i i s>f fRatio f* f>s 0 _color line
      30 ms
      -5
    +loop
    
    _indx getRandomWheelIndex to _indx
    _indx wheel to _color
    0 getLCDHeight 1-
    do
      0 i 240 i - s>f fRatio f* f>s 0 _color line
      30 ms
      -5
    +loop
    
    _indx getRandomWheelIndex to _indx
    _indx wheel to _color
    240 0
    do
      319 i 240 i - s>f fRatio f* f>s 239 _color line
      30 ms
      5
    +loop

    \ Check for pattern exit
    checkForExit

  until
  returnReason
;
