\
\ Multiple Display I2C Driver for the OLED SSD-1306 Display Controller
\ 128x32 monochrome displays
\ Driver configured for 6 displays
\ Written for ESP32forth by Craig A. Lindley
\ Last Update: 05/21/2022

\ I2C constants
    21 constant I2C_SDA
    22 constant I2C_SCL
400000 constant I2C_FREQ
   $70 constant I2C_MUX_ADDR

\ Select Wire vocabulary
Wire

\ Initialize the Wire library in ESP32Forth for using I2C
: initI2C ( -- f )
  I2C_SDA I2C_SCL Wire.begin
  0=
  if 
    \ Initialization Error
    ." Initialization error occurred" cr
    false
  else
    I2C_FREQ Wire.setClock
    true
  then
;

\ Select which I2C interface of the mux should be selected. 0 .. 7
\ Selection remains in effect until changed
: muxChannelSelect { ch } ( ch -- f )
  ch 0 >= ch 7 <= and
  if 
    I2C_MUX_ADDR Wire.beginTransmission
    1 ch << Wire.write drop
    true Wire.endTransmission 0=
    if 
      true
    else
      ." muxChannelSelect error" cr
      false
    then
  else
    ." Channel out of range error" cr
    false
  then
;

\ Display constants

\ The number of displays to be supported 1 .. 8
  6 constant NUM_OF_DISPLAYS

$3C constant SSD1306_ADDR
128 constant SSD1306_WIDTH
 32 constant SSD1306_HEIGHT

\ Calculate required frame buffer size per display
SSD1306_WIDTH SSD1306_HEIGHT * 8 / constant SSD1306_BUFFER_SIZE

\ Calculate total buffer size for NUM_OF_DISPLAYS
SSD1306_BUFFER_SIZE NUM_OF_DISPLAYS * constant TOTAL_BUFFER_SIZE

\ Colors of monochrome display
$00 constant COLOR_BLACK
$01 constant COLOR_WHITE
$02 constant COLOR_INVERSE

\ SSD1306 controller commands
$8D constant CHARGEPUMP
$21 constant COLUMNADDR
$C8 constant COMSCANDEC
$C0 constant COMSCANINC
$A5 constant DISPLAYALLON
$A4 constant DISPLAYALLON_RESUME
$AE constant DISPLAYOFF
$AF constant DISPLAYON
\ $01 constant EXTERNALVCC
$A7 constant INVERTDISPLAY
$20 constant MEMORYMODE
$A6 constant NORMALDISPLAY
$22 constant PAGEADDR
$A0 constant SEGREMAP
$DA constant SETCOMPINS
$81 constant SETCONTRAST
$D5 constant SETDISPLAYCLOCKDIV
$D3 constant SETDISPLAYOFFSET
\ $10 constant SETHIGHCOLUMN
\ $00 constant SETLOWCOLUMN
$A8 constant SETMULTIPLEX
$D9 constant SETPRECHARGE
\ $A1 constant SETSEGMENTREMAP
$40 constant SETSTARTLINE
$DB constant SETVCOMDETECT
$2E constant STOPSCROLL
\ $02 constant SWITCHCAPVCC

\ Program variables
0 value selectedDisplay
0 value bufferOffset

\ Variable storage for each display
NUM_OF_DISPLAYS byteArray displayWidths
NUM_OF_DISPLAYS byteArray displayHeights
NUM_OF_DISPLAYS byteArray displayRotations

\ Allocate one buffer containing all display frame buffers
\ This will make shifting right and left possible
TOTAL_BUFFER_SIZE byteArray BUFFER

\ Send command to the controller
: sendCommand { cmd } ( cmd -- )
  SSD1306_ADDR Wire.beginTransmission
  $80 Wire.write drop
  cmd Wire.write drop
  true Wire.endTransmission 
  0<>
  if 
    ." sendCommand I2C error" cr
  then
;

\ Initialize controller for 128x32 operation
: initController ( -- )
  DISPLAYOFF          sendCommand
  SETDISPLAYCLOCKDIV  sendCommand
  $F0                 sendCommand
  SETMULTIPLEX        sendCommand
  SSD1306_HEIGHT 1-   sendCommand
  SETDISPLAYOFFSET    sendCommand
  $00                 sendCommand
  SETSTARTLINE        sendCommand
  CHARGEPUMP          sendCommand
  $14                 sendCommand
  MEMORYMODE          sendCommand
  $00                 sendCommand
  SEGREMAP            sendCommand
  COMSCANINC          sendCommand
  SETCOMPINS          sendCommand
  $02                 sendCommand
  SETCONTRAST         sendCommand
  $8F                 sendCommand
  SETPRECHARGE        sendCommand
  $22                 sendCommand
  SETVCOMDETECT       sendCommand
  $40                 sendCommand
  DISPLAYALLON_RESUME sendCommand
  NORMALDISPLAY       sendCommand
  STOPSCROLL          sendCommand
  DISPLAYON           sendCommand
;

\ Copy frame buffer to controller for display
: _show ( -- )
  COLUMNADDR       sendCommand
  $00              sendCommand
  SSD1306_WIDTH 1- sendCommand
  
  0 { index }

  SSD1306_BUFFER_SIZE 16 / 0
  do
    SSD1306_ADDR Wire.beginTransmission
    $40 Wire.write drop
    16 0
    do
      index BUFFER bufferOffset + c@ Wire.write drop
      1 +to index
    loop
    true Wire.endTransmission
    0<>
    if 
      ." sendCommand I2C error" cr
    then
  loop
;

only forth definitions

\ Don't know why this is necessary but it seems to be
: show
  _show
  _show
;

\ Set the frame buffer to black
: clearBuffer
  0 BUFFER bufferOffset + SSD1306_BUFFER_SIZE $00 fill
;

\ Set the frame buffer to white
: fillBuffer
  0 BUFFER bufferOffset + SSD1306_BUFFER_SIZE $FF fill
;

\ Clear display
: clearDisplay ( -- )
  clearBuffer
  show
;

\ Fill display
: fillDisplay ( -- )
  fillBuffer
  show
;

\ Turn display on
: displayOn ( -- )
  DISPLAYON sendCommand
;

\ Turn display off
: displayOff ( -- )
  DISPLAYOFF sendCommand
;

\ Invert display
: invertDisplay ( -- )
  INVERTDISPLAY sendCommand
;

\ Normal display
: normalDisplay ( -- )
  NORMALDISPLAY sendCommand
;

\ Get the display width
: width ( -- width )
  selectedDisplay displayWidths c@
;

: height ( -- height )
  selectedDisplay displayHeights c@
;

\ Set display rotation values 0 .. 3
: setRotation ( rotation -- )

  0 0 { dw dh }

  4 mod dup selectedDisplay displayRotations c!
  case
    0 of SSD1306_WIDTH  to dw SSD1306_HEIGHT to dh endof
    1 of SSD1306_HEIGHT to dw SSD1306_WIDTH  to dh endof
    2 of SSD1306_WIDTH  to dw SSD1306_HEIGHT to dh endof
    3 of SSD1306_HEIGHT to dw SSD1306_WIDTH  to dh endof
  endcase

  dw selectedDisplay displayWidths  c!
  dh selectedDisplay displayHeights c!
;

\ Set a pixel to black, white or inverse
: pixel { x y color } ( x y color -- )
  0 0 { newX newY }

  selectedDisplay displayRotations c@
  case
    0 of x to newX y to newY endof
    1 of SSD1306_WIDTH y - 1- to newX x to newY endof
    2 of SSD1306_WIDTH x - 1- to newX SSD1306_HEIGHT y - 1- to newY endof
    3 of y to newX SSD1306_HEIGHT x - 1- to newY endof
  endcase

  \ Create local containing addr of pixel data
  newY 8 / SSD1306_WIDTH * newX + BUFFER bufferOffset + { addr }
  1 newY 7 and << { selector }
  
  color
  case
    COLOR_WHITE   of addr c@ selector or addr c!         endof
    COLOR_BLACK   of addr c@ selector invert and addr c! endof
    COLOR_INVERSE of addr c@ selector xor addr c!        endof
  endcase
;

\ Select the display to control
: selectDisplay { n } ( n -- )
  n NUM_OF_DISPLAYS mod to n

  n to selectedDisplay

  \ Select mux channel for display I2C control
  n muxChannelSelect drop

  \ Calculate offset of frame buffers in BUFFER
  \ NOTE: buffers order is reversed to enable rotation
  \ Display buffer order 5 4 3 2 1 0
  NUM_OF_DISPLAYS 1- n - SSD1306_BUFFER_SIZE * to bufferOffset
;

\ Initialize display controller
: initDisplay ( rotation -- )
  setRotation
  initController
  clearDisplay
;

\ Initialize all configured displays with specified rotation
: initDisplays { rotation } ( rotation -- )

  \ Initialize I2C mux
  initI2C drop

  NUM_OF_DISPLAYS 0
  do
    i selectDisplay
    rotation initDisplay
  loop

  \ Select first display
  0 selectDisplay
;

\ Clear all displays
: clearDisplays

  NUM_OF_DISPLAYS 0
  do
    i selectDisplay
    clearDisplay
  loop
;

\ Show all displays
: showAllDisplays

  NUM_OF_DISPLAYS 0
  do
    i selectDisplay
    show
  loop
;

\ Fill a rectangle on the display
: fillRect { x0 y0 x1 y1 color }
  x1 1+ x0
  do
    y1 1+ y0
    do
      j i color pixel
    loop
  loop
  show
;

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  width x0 + x0
  do
    height y0 + y0
    do
      j i color pixel
    loop
  loop
  show
;

\ Create tmp buffer for shifted data storage
128 byteArray tmpBuf

\ Rotate the display contents left
: rotate
  \ Save the last row of display 0's data to tmp storage
  TOTAL_BUFFER_SIZE 128 - buffer 0 tmpBuf 128 memmove

  \ Shift all display buffers
  0 buffer 128 buffer TOTAL_BUFFER_SIZE 128 -  memmove

  \ Set first row of display 5's data from tmp storage
  0 tmpBuf 0 buffer 128 memmove
;






