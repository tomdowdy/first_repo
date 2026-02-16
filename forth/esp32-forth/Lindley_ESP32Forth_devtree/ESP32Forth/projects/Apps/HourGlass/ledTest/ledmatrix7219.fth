\
\ MAX7219 driver for cascaded 8x8 LED matrices
\ Written for ESP32forth
\ Written by Craig A. Lindley
\ Last Update: 07/10/2022

\ Number of cascaded MAX7219 devices to support
2 constant NUMBER_OF_DEVICES

\ OP codes for MAX7219
$0900 constant DECODE
$0A00 constant INTENSITY
$0B00 constant SCANLIMIT
$0C00 constant ENABLE
$0F00 constant TEST

\ Rotation constants
0 constant ROT0
1 constant ROT90
2 constant ROT180
3 constant ROT270

\ Storage for LED GPIO pin number
0 value LED_CS_PIN

\ Storage for current display rotation
0 value displayRotation

\ Bring in SPI vocabulary
also SPI

\ **************** Frame Buffer Functions ****************

\ Calculate size of required FRAMEBUFFER
NUMBER_OF_DEVICES 8 * constant FRAMEBUFFER_SIZE

\ Create framebuffer for reading/writing display content
FRAMEBUFFER_SIZE byteArray FRAMEBUFFER

\ Get index into framebuffer for given x, y pixel location
: getPixelIndex { x y } ( x y -- index )

  y NUMBER_OF_DEVICES * x 3 >> +
;

\ Display a row of framebuffer data
: displayRow { row } ( row -- )
  \ Assert chip select
  LED_CS_PIN LOW digitalWrite

  NUMBER_OF_DEVICES 0
  do
    i row NUMBER_OF_DEVICES * +
    FRAMEBUFFER c@

    row 1+ 8 << or
    VSPI.transfer16 drop   
  loop
  \ Deassert chip select
  LED_CS_PIN HIGH digitalWrite
;

\ Display framebuffer content
: display ( -- )
  8 0
  do
    i displayRow
  loop
;

\ Set a pixel (off/on) in the framebuffer
\ Uses native orientation of displays without rotation
: _setPixel { disp x y state } ( x y state -- )
  disp 0<>
  if
    x 8 + to x
  then

  \ Prepare bit mask
  1 7 x 7 and - <<

  x y getPixelIndex dup
  FRAMEBUFFER c@ 

  state
  if
    rot or 
  else
    rot invert and
  then
  swap FRAMEBUFFER c!
;

\ Set display rotation
: setRotation ( rot -- )
  to displayRotation
;

\ Transfor pixel coordinates in accordance with rotation
: transform { x y } ( x y -- newx newy)
  0 { t }
  displayRotation
  case
    ROT0
     of         
       \ Nothing to do
     endof

    ROT90 
     of
       x to t
       7 y - to x
       t to y 
     endof

    ROT180
     of      
       7 x - to x
       7 y - to y
     endof

    ROT270
     of      
       x to t
       y to x
       7 t - to y
     endof
  endcase
  x y
;

\ Set pixel off/on on selected display
: setPixel { disp x y state } ( disp x y state -- )
  x y transform
  disp -rot state _setPixel
;

\ Get a pixel's state (off/on) from the framebuffer
\ Uses native orientation of displays without rotation
: _getPixel { disp x y } ( disp x y -- pixel )
  disp 0<>
  if
    x 8 + to x
  then

  \ Prepare bit mask
  1 7 x 7 and - <<

  x y getPixelIndex FRAMEBUFFER c@ and
;

\ Get a pixel's state (off/on) from selected display
: getPixel { disp x y } ( disp x y -- pixel )
  x y transform
  disp -rot _getPixel
;

\ **************** Command Functions ****************

\ Send a command to all MAX7219 devices
: sendCommand { cmd } ( cmd -- )
  \ Assert chip select
  LED_CS_PIN LOW digitalWrite
  NUMBER_OF_DEVICES 0
  do
    cmd VSPI.transfer16 drop
  loop
  \ Deassert chip select
  LED_CS_PIN HIGH digitalWrite
;

\ Set/Reset MAX7219 enable/shutdown state
: setEnabled ( enabledState -- )
  if
    ENABLE 1 or  
  else
    ENABLE
  then
  sendCommand
;

\ Set display intensity
\ 0 is lowest intensity (but not off). 15 highest intensity
: setIntensity { level } ( level -- )
  level 0<
  if
    0 to level
  then
  level 15 >
  if
    15 to level
  then
  level sendCommand
;

\ Set scan limit
\ NOTE: see documentation for limiting scan because device can be blown
\ best to leave this alone
\ limit = 7 is all digits
: setScanLimit { limit } { limit } ( limit -- )
  limit 0<
  if
    0 to limit
  then
  limit 7 >
  if
    7 to limit
  then
  SCANLIMIT limit or
  sendCommand
;

\ **************** Driver Functions ****************

\ Clear display - all pixels off
: clearDisplay ( -- )
  \ Clear the framebuffer
  0 FRAMEBUFFER FRAMEBUFFER_SIZE erase

  \ Display cleared framebuffer
  display
;

\ Fill display - all pixels on
: fillDisplay ( -- )
  \ Clear the framebuffer
  0 FRAMEBUFFER FRAMEBUFFER_SIZE $FF fill

  \ Display initialized framebuffer
  display
;

\ Initialize driver
: initMAX7219Driver ( CS_PIN -- )
  \ Save GPIO CS pin
  to LED_CS_PIN

  \ Initialize display chip select pin
  LED_CS_PIN OUTPUT pinMode
  LED_CS_PIN HIGH digitalWrite

  \ Clear the framebuffer
  0 FRAMEBUFFER FRAMEBUFFER_SIZE erase

  \ Disable display
  false setEnabled

  \ Set display to minimum intensity
  0 setIntensity

  \ Turn off test mode
  TEST sendCommand

  \ Turn off BCD decoding
  DECODE sendCommand

  \ Set maximum scan limit
  SCANLIMIT 7 or sendCommand

  \ Enable display
  true setEnabled

  \ Update the display
  display
;
