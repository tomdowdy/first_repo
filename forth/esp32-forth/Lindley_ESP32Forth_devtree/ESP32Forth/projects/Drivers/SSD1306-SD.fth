\
\ I2C Driver for the OLED SSD-1306 Display Controller
\ 128x32 monochrome display
\ Written for ESP32forth by Craig A. Lindley
\ Last Update: 05/18/2022

$3C constant SSD1306_ADDR
128 constant SSD1306_WIDTH
 32 constant SSD1306_HEIGHT

\ Calculate required buffer size
SSD1306_WIDTH SSD1306_HEIGHT * 8 / constant SSD1306_BUFFER_SIZE

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
0 value displayWidth
0 value displayHeight
0 value displayRotation

\ Allocate a frame buffer
SSD1306_BUFFER_SIZE byteArray BUFFER

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
      index BUFFER c@ Wire.write drop
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

: show
  _show _show
;

\ Set the frame buffer to black
: clearBuffer
  0 BUFFER SSD1306_BUFFER_SIZE $00 fill
;

\ Set the frame buffer to white
: fillBuffer
  0 BUFFER SSD1306_BUFFER_SIZE $FF fill
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
  displayWidth
;

: height ( -- height )
  displayHeight
;

\ Set display rotation values 0 .. 3
: setRotation ( rotation -- )
  4 mod dup to displayRotation
  case
    0 of SSD1306_WIDTH  to displayWidth SSD1306_HEIGHT to displayHeight endof
    1 of SSD1306_HEIGHT to displayWidth SSD1306_WIDTH  to displayHeight endof
    2 of SSD1306_WIDTH  to displayWidth SSD1306_HEIGHT to displayHeight endof
    3 of SSD1306_HEIGHT to displayWidth SSD1306_WIDTH  to displayHeight endof
  endcase
  \ displayWidth . ."   " displayHeight . cr
;

\ Set a pixel to black, white or inverse
: pixel { x y color } ( x y color -- )
  0 0 { newX newY }
  displayRotation
  case
    0 of x to newX y to newY endof
    1 of SSD1306_WIDTH y - 1- to newX x to newY endof
    2 of SSD1306_WIDTH x - 1- to newX SSD1306_HEIGHT y - 1- to newY endof
    3 of y to newX SSD1306_HEIGHT x - 1- to newY endof
  endcase

  \ Create local containing addr of pixel data
  newY 8 / SSD1306_WIDTH * newX + BUFFER { addr }
  1 newY 7 and << { selector }
  
  color
  case
    COLOR_WHITE   of addr c@ selector or addr c!         endof
    COLOR_BLACK   of addr c@ selector invert and addr c! endof
    COLOR_INVERSE of addr c@ selector xor addr c!        endof
  endcase
;

\ Initialize display controller
: initDisplay ( rotation -- )
  setRotation
  initController
  clearDisplay
;

\ Fill a rectangle on the display
: fillRect { x0 y0 x1 y1 color }
  x1 1+ x0
  do
    y1 1+ y0
    do
      i j color pixel
    loop
  loop
  show
;

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  width x0
  do
    height y0
    do
      i j color pixel
    loop
  loop
  show
;

: ttHoriz
  clearDisplay
  0 0 10 10 1 fillRect
  1000 delay
;

: ttVert
  clearDisplay
  0 0 10 10 1 fillRect
  1000 delay
;

: testR0 { disp }
  disp muxChannelSelect drop
  0 initDisplay
  ttHoriz
;

: testR1 { disp }
  disp muxChannelSelect drop
  1 initDisplay
  ttVert
;

: testR2 { disp }
  disp muxChannelSelect drop
  2 initDisplay
  ttHoriz
;

: testR3 { disp }
  disp muxChannelSelect drop
  3 initDisplay
  ttVert
;

: DisplayRotate { disp }
  disp testR0
  disp testR1
  disp testR2
  disp testR3

  0 setRotate
;

: testRotate
  0 DisplayRotate
  clearDisplay
  1 DisplayRotate
  clearDisplay 
;


initI2C drop

  

