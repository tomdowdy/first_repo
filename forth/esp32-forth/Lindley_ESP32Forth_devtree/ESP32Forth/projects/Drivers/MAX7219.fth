\
\ MAX7219 Serial Interfaced, 8 digit LED Display Driver
\ Written for ESP32Forth
\ Last Update: 01/21/2026

\ Hardware Connections
13 constant MAX7912_DATA
14 constant MAX7912_CLK
15 constant MAX7912_CS

 8 constant SCAN_LIMIT

\ Register Addresses
 9 constant DECODE_MODE_ADDR
10 constant INTENSITY_ADDR
11 constant SCAN_LIMIT_ADDR
12 constant SHUTDOWN_ADDR
15 constant DISP_TEST_ADDR

\ These constants assume a 4 matrix/controller LED display
 4 constant NUM_CONTROLLERS
 NUM_CONTROLLERS constant BYTES_PER_ROW

 8 constant NUM_ROWS
 BYTES_PER_ROW NUM_ROWS * constant BUFFER_SIZE

\ Render Buffer
\ LED display contents are written to this buffer
\ then sent to the hardware for display
BUFFER_SIZE byteArray RENDER_BUFFER

\ Temp Buffer for streaming addr:data to display
 2 constant BYTES_PER_INSTRUCTION
NUM_CONTROLLERS BYTES_PER_INSTRUCTION * constant TEMP_BUFFER_SIZE
TEMP_BUFFER_SIZE byteArray TEMP_BUFFER

\ Scroll delay MS. Controls speed of scrolling
200 constant SCROLL_DELAY

\ ******** CODE BELOW ********

\ Show render buffer
: showRB ( -- )

  cr ." RB" cr
  BUFFER_SIZE 0
  do
    i RENDER_BUFFER c@ .hex
  loop
  cr
;

\ Show temp buffer
: showTB ( -- )

  cr ." TB" cr
  TEMP_BUFFER_SIZE 0
  do
    i TEMP_BUFFER c@ .hex
  loop
  cr
;

\ Write temp buffer to the MAX7219
: MAX7912_Write ( -- ) 

  0 { val }

  MAX7912_CS LOW digitalWrite

  TEMP_BUFFER_SIZE 0 
  do
    i TEMP_BUFFER c@ to val

    8 0
    do
      MAX7912_CLK LOW digitalWrite
      val $80 and
      if
        MAX7912_DATA HIGH digitalWrite
      else
        MAX7912_DATA LOW  digitalWrite
      then
      MAX7912_CLK HIGH digitalWrite
      val 1 << to val
    loop
  loop

  MAX7912_CS HIGH digitalWrite
;

\ Display control
\ state: HIGH is ON; LOW is OFF
: displayControl { state -- }

  0 TEMP_BUFFER { addr }
     
  NUM_CONTROLLERS 0
  do
    SHUTDOWN_ADDR addr c!
    1 +to addr
    state addr c!
    1 +to addr
  loop
  MAX7912_Write
;
  
\ Set scan limit
: setScanLimit { limit -- }
  
  0 TEMP_BUFFER { addr }
     
  NUM_CONTROLLERS 0
  do
    SCAN_LIMIT_ADDR addr c!
    1 +to addr
    limit 1- addr c!
    1 +to addr
  loop
  MAX7912_Write
;

\ Set intensity 0 .. 15
: setIntensity { int -- }

  0 TEMP_BUFFER { addr }
     
  NUM_CONTROLLERS 0
  do
    INTENSITY_ADDR addr c!
    1 +to addr
    int addr c!
    1 +to addr
  loop
  MAX7912_Write
;

\ Control BCD decoding
\ state: HIGH BCD decoding on, LOW BCD decoding off
: decodeControl { mode -- }
 
  0 TEMP_BUFFER { addr }
     
  NUM_CONTROLLERS 0
  do
    DECODE_MODE_ADDR addr c!
    1 +to addr
    mode addr c!
    1 +to addr
  loop
  MAX7912_Write
;

\ Set display test mode
\ mode: HIGH test mode on, LOW test mode off
: testModeControl { mode -- }
  
  0 TEMP_BUFFER { addr }
     
  NUM_CONTROLLERS 0
  do
    DISP_TEST_ADDR addr c!
    1 +to addr
    mode addr c!
    1 +to addr
  loop
  MAX7912_Write
;

\ Clear the render buffer
: clearRenderBuffer ( -- )

  0 RENDER_BUFFER BUFFER_SIZE 0 fill
;

\ Set a pixel for display
\ col: 0 .. 31, row: 0 ..7 state: HIGH or LOW
: setPixel { col row state }
  
   row BYTES_PER_ROW * col 8 / + { idx }
   idx RENDER_BUFFER c@
   1 col 8 mod <<
   state
   if
     or
   else
     invert and
   then
   idx RENDER_BUFFER c!
;

\ Send the contents of the RENDER_BUFFER to the hardware for display
: renderBufferContents ( -- )

  0 0 { tempAddr rowAddr }

  \ For each row to transmit
  NUM_ROWS 0
  do
    0 TEMP_BUFFER to tempAddr
    i BYTES_PER_ROW * to rowAddr

    NUM_CONTROLLERS 0 
    do
      j 1+ tempAddr c!
      1 +to tempAddr
      rowAddr NUM_CONTROLLERS i - 1- + RENDER_BUFFER C@ tempAddr c!
      1 +to tempAddr
    loop
    MAX7912_Write
  loop
;

\ Clear the LED display 
: clearDisplay ( -- )

  clearRenderBuffer
  renderBufferContents
;

\ TEXT METHODS AND FUNCTIONS

\ Shift render buffer left one pixel
: shiftRBLeft ( -- )

  NUM_ROWS 0
  do 
    i BYTES_PER_ROW * 
    RENDER_BUFFER dup
    @ 1 <<  swap !
  loop
;

\ Print a character with the font
: pChar { ch -- }

  0 { cp }

  \ Calculate offset of char data in font
  ch $20 - FW * FONT + to cp

  FW 0
  do
    cp c@ 
    1 +to cp
    FH 1+ 0
    do
      dup                (    -- ch ch)
      1 i << and        ( ch ch -- ch f )
      if 
        0 i 1+ HIGH setPixel
      then
    loop
    drop
    renderBufferContents
    shiftRBLeft
    SCROLL_DELAY delay
  loop
  \ Add a column of pixels between characters
  shiftRBLeft
;

\ Scroll a string across the display 
: scrollString { addr len -- }

  len 0
   do
     addr i + c@ pChar
  loop
;

\ Initialize MAX7219 controller
: max7219_Init ( -- )

  \ Configure GPIO pins
  MAX7912_DATA OUTPUT pinMode
  MAX7912_DATA HIGH digitalWrite
  MAX7912_CLK  OUTPUT pinMode
  MAX7912_CLK  HIGH digitalWrite
  MAX7912_CS   OUTPUT pinMode
  MAX7912_CS   HIGH digitalWrite

  \ Turn the display on
  HIGH displayControl

  \ Set scan limit
  SCAN_LIMIT setScanLimit

  \ Set intensity
  0 setIntensity

  \ Turn off BCD decoding
  0 decodeControl

  \ Turn off test mode
  0 testModeControl

  \ Clear the render buffer and the display
  clearDisplay
;


  
