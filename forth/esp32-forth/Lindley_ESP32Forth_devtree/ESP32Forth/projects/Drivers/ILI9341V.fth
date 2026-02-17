\
\ SPI Driver for the ILI9341 Display Controller
\ Written for ESP32forth
\ Uses the VSPI interface pins 18, 19, 23, 5
\ Written by Craig A. Lindley
\ Last Update: 11/01/2023

\ LCD dimensions (un rotated)
240 constant LCD_WIDTH
320 constant LCD_HEIGHT

\ Bring in SPI vocabulary
SPI

\ Display controller constants
$2A constant CASET  \ Column Address Set
$2B constant RASET  \ Row Address Set
$2C constant RAMWR  \ Memory Write

$36 constant MADCTL
$80 constant MADCTL_MY
$40 constant MADCTL_MX
$20 constant MADCTL_MV
$10 constant MADCTL_ML
$00 constant MADCTL_RGB
$08 constant MADCTL_BGR
$04 constant MADCTL_MH

0 value lcdWidth
0 value lcdHeight

\ ILI9341 initialization data
create INIT_DATA
  $EF c, 3 c, $03 c, $80 c, $02 c,
  $CF c, 3 c, $00 c, $C1 c, $30 c,
  $ED c, 4 c, $64 c, $03 c, $12 c, $81 c,
  $E8 c, 3 c, $85 c, $00 c, $78 c,
  $CB c, 5 c, $39 c, $2C c, $00 c, $34 c, $02 c,
  $F7 c, 1 c, $20 c,
  $EA c, 2 c, $00 c, $00 c,
  $C0 c, 1 c, $23 c,
  $C1 c, 1 c, $10 c,
  $C5 c, 2 c, $3e c, $28 c,
  $C7 c, 1 c, $86 c,
  $36 c, 1 c, $48 c,
  $3A c, 1 c, $55 c,
  $B1 c, 2 c, $00 c, $18 c,
  $B6 c, 3 c, $08 c, $82 c, $27 c,
  $F2 c, 1 c, $00 c,
  $26 c, 1 c, $01 c,
  $E0 c, 15 c, $0F c, $31 c, $2B c, $0C c, $0E c, $08 c, $4E c, $F1 c, $37 c, $07 c, $10 c, $03 c, $0E c, $09 c, $00 c,
  $E1 c, 15 c, $00 c, $0E c, $14 c, $03 c, $11 c, $07 c, $31 c, $C1 c, $48 c, $08 c, $0F c, $0C c, $31 c, $36 c, $0F c,
  $00 c,

\ Initialize GPIO and reset controller
: initAndReset ( -- )

  \ First set all lines to outputs
  LCD_RESET OUTPUT pinMode
  LCD_DC    OUTPUT pinMode
  LCD_CS    OUTPUT pinMode
  LCD_BL    OUTPUT pinMode

  \ Next, set initial levels
  LCD_RESET HIGH digitalWrite
  LCD_DC    HIGH digitalWrite
  LCD_CS    HIGH digitalWrite
  LCD_BL    HIGH digitalWrite

  \ Set LCD display dimensions
  LCD_WIDTH  to lcdWidth
  LCD_HEIGHT to lcdHeight

  \ Give the ILI9341 display controller a hard reset
  50 ms
  LCD_RESET LOW digitalWrite
  50 MS
  LCD_RESET HIGH digitalWrite
  50 ms
;

\ Initialize VSPI interface
: initSPI ( -- )
  LCD_SCK LCD_MISO LCD_MOSI LCD_CS VSPI.begin
  LCD_FREQUENCY VSPI.setFrequency
 ;

\ Write 8 bit command to LCD controller
: wrt8Cmd ( cmd -- )
  LCD_CS LOW digitalWrite
  LCD_DC LOW digitalWrite
  VSPI.write
  LCD_DC HIGH digitalWrite
  LCD_CS HIGH digitalWrite
;

\ Write 8 bit data to LCD controller
: wrt8Data ( data -- )
  LCD_CS LOW digitalWrite
  VSPI.write
  LCD_CS HIGH digitalWrite
;
 
\ Write 16 bit data to LCD controller
: wrt16Data ( data -- )
  LCD_CS LOW digitalWrite
  VSPI.write16
  LCD_CS HIGH digitalWrite
;

\ Write 32 bit data to LCD controller
: wrt32Data ( data -- )
  LCD_CS LOW digitalWrite
  VSPI.write32
  LCD_CS HIGH digitalWrite
;

\ Retrieve byte data at index
: getData ( index -- data )
  INIT_DATA + c@
;

0 value _indx
0 value _b

\ Load initialization data into the ILI9341 display controller
: loadData ( -- )
  0 to _indx
  begin
    _indx getData to _b
    _b 0 <>
  while
    _b wrt8Cmd
    1 +to _indx
    _indx getData 0
    do
      1 +to _indx
      _indx getData wrt8Data
    loop
    1 +to _indx
    _indx getData to _b
  repeat
;

\ Return width of LCD screen in currect rotation
: getLCDWidth
  lcdWidth
;

\ Return height of LCD screen in currect rotation
: getLCDHeight
  lcdHeight
;

\ Backlight control function doesn't work on early T4 devices
: backlight ( high/low -- )
  if 
    LCD_BL HIGH digitalWrite
  else
    LCD_BL LOW  digitalWrite
  then
;

0 value _cmd

\ Set the LCD display rotation
\ 0 top away from connector
\ 1 top right of connector
\ 2 top at connector
\ 3 top left of connector
: setLCDRotation ( rotation -- )
  4 mod
  case
    0 of 
        MADCTL_MX MADCTL_BGR or to _cmd
        LCD_WIDTH  to lcdWidth
        LCD_HEIGHT to lcdHeight
      endof
    1 of 
        MADCTL_MV MADCTL_BGR or to _cmd
        LCD_HEIGHT to lcdWidth
        LCD_WIDTH  to lcdHeight
      endof
    2 of 
        MADCTL_MY MADCTL_BGR or to _cmd
        LCD_WIDTH  to lcdWidth
        LCD_HEIGHT to lcdHeight
      endof
    3 of 
        MADCTL_MX MADCTL_MY MADCTL_MV MADCTL_BGR or or or to _cmd
        LCD_HEIGHT to lcdWidth
        LCD_WIDTH  to lcdHeight
      endof
  endcase
  MADCTL wrt8Cmd
  _cmd wrt8Data
;

\ Initialize LCD Controller
: initLCD ( rotation -- )

  \ Initialize GPIO and controller
  initAndReset

  \ Initialize SPI
  initSPI

  \ Load controller data
  loadData

  \ Backlight on
  true backlight

  \ Exit sleep
  $11 wrt8Cmd
  120 ms

  \ Display on
  $29 wrt8Cmd
  120 ms

  \ Set rotation
  setLCDRotation
;

0 value _xa
0 value _ya

\ Set the display RAM address window
: setWindow { x y w h }
  x 16 << x w + 1- + to _xa
  y 16 << y h + 1- + to _ya

  CASET wrt8Cmd
  _xa wrt32Data
  RASET wrt8Cmd
  _ya wrt32Data
  RAMWR wrt8Cmd
;

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

\ Draw a pixel on the display
: pixel { x y color }
  x y 1 1 setWindow
  color wrt16Data
;

0 value _x
0 value _y
0 value _w
0 value _h

\ Fill a rectangle on the display
: fillRect { x0 y0 x1 y1 color }
  x1 x0 - 1+ to _w
  y1 y0 - 1+ to _h
  x0 y0 _w _h setWindow
  _w _h * 0
  do
    color wrt16Data
  loop
;

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  x0 width  + to _x
  y0 height + to _y
  x0 y0 _x _y color fillRect
;

\ Fill the screen with a color
: fillScreen { color }
  0 0 getLCDWidth 1- getLCDHeight 1- color fillRect
;

\ Clear the screen to black
: clearScreen ( -- )
    $0000 fillScreen
;

only forth definitions
