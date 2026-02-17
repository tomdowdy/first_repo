\ Text test for MDGadget 32x48 chars

32 constant CHAR_WIDTH
48 constant CHAR_HEIGHT

\ Get bit of font data
\ Row 0 .. 47; Col 0 .. 31
: getBit { charAddr row col } ( charAddr row col -- 0/1 )
  col 8 / row 4 * + charAddr + c@
  col 8 mod $80 swap >> and
  if 1 else 0 then
;

\ Draw a numeric char on specified display
: drawChar { charAddr }

  CHAR_HEIGHT 0
  do
     CHAR_WIDTH 0 
    do
      i j 40 + charAddr j i getBit pixel
    loop
  loop
  show
;

0 value dispNum

: test
  \ Initialize I2C mux
  initI2C drop
  3 initDisplays

  begin
    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    0 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    1 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    10 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    2 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    3 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    10 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    4 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    5 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    10 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    6 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    7 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    10 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    8 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    9 numbers drawChar
    200 delay

    dispNum selectDisplay 1 +to dispNum
    clearDisplay
    10 numbers drawChar
    200 delay

    false
  until
;
 

