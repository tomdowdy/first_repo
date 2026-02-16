\ ST7789 65K Color LCD Display Driver
\ Dimensions: 135x240 on TTGO T-Display
\ Written for ESPForth
\ By: Craig A. Lindley
\ Last Update: 08/12/2021

\ Define some 16 bit color values
$0000 constant BLK
$F800 constant RED
$FFE0 constant YEL
$07E0 constant GRN
$001F constant BLU
$07FF constant CYA
$F81F constant MAG
$FFFF constant WHT

\ ST7735 commands
$01 constant SWRESET \ software reset
$11 constant SLPOUT  \ sleep out
$13 constant NORON   \ normal display on
$20 constant INVOFF  \ display inversion off 
$21 constant INVON   \ display inversion on
$29 constant DISPON  \ display on
$2A constant CASET   \ column address set
$2B constant RASET   \ row address set
$2C constant RAMWR   \ RAM write
$36 constant MADCTL  \ pixel direction control
$3A constant COLMOD  \ color mode

\ Display rotation constants
$80 constant CTL_MY
$40 constant CTL_MX
$20 constant CTL_MV
$00 constant CTL_RGB
$08 constant CTL_BGR

53 value COL_OFFSET
40 value ROW_OFFSET
 0 value _xstart_
 0 value _ystart_

\ Dimensions of display with current rotation
0 value _width_
0 value _height_

SPI 

\ Write an 8 bit command to the display via SPI
: wrtCmd ( cmd -- )
  LCD_CS LOW digitalWrite
  LCD_DC LOW digitalWrite
  VSPI.write
  LCD_DC HIGH digitalWrite
  LCD_CS HIGH digitalWrite
;

\ Write 8 bit data to the display via SPI
: wrtData ( data -- ) 
  LCD_CS LOW digitalWrite
  VSPI.write
  LCD_CS HIGH digitalWrite
;

\ Write 16 bit data to the display via SPI
: wrtData16 ( data -- ) 
  LCD_CS LOW digitalWrite
  VSPI.write16
  LCD_CS HIGH digitalWrite
;

\ Get the current display width
: getLCDWidth ( -- width )
  _width_
;

\ Get the current display height
: getLCDHeight ( -- height )
  _height_
;

\ Backlight control function
: backlight ( true/false -- )
  if
    LCD_BL HIGH digitalWrite
  else
    LCD_BL LOW  digitalWrite
  then
;

\ Set display rotation
: setRotation ( rotation -- )
  \ Legal values 0, 1, 2, 3
  4 mod
  MADCTL wrtCmd
  case
    \ Portrait away from USB connector
    0 of
      COL_OFFSET to _xstart_
      ROW_OFFSET to _ystart_
      CTL_RGB wrtData
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Landscape
    1 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_RGB CTL_MX CTL_MV or or wrtData
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
    \ Inverted portrait
    2 of
      COL_OFFSET to _xstart_
      ROW_OFFSET to _ystart_
      CTL_RGB CTL_MX CTL_MY or or wrtData
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Inverted landscape
    3 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_RGB CTL_MV CTL_MY or or wrtData
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
  endcase
;

\ Initialize the VSPI interface and the display controller
: initLCD { rotation }

  \ Initialize VSPI interface
  LCD_SCLK -1 LCD_MOSI LCD_CS VSPI.begin
  80000000 VSPI.setFrequency

  \ Set GPIO pins as outputs
  LCD_RESET OUTPUT pinMode
  LCD_DC    OUTPUT pinMode
  LCD_CS    OUTPUT pinMode
  LCD_BL    OUTPUT pinMode

  \ Next, set initial levels
  LCD_RESET HIGH digitalWrite
  LCD_DC    HIGH digitalWrite
  LCD_CS    HIGH digitalWrite
  LCD_BL    HIGH digitalWrite

  \ Give the display controller a hard reset
  50 MS
  LCD_RESET LOW digitalWrite
  50 MS
  LCD_RESET HIGH digitalWrite
  50 MS

  \ Setup LCD slave device
  SWRESET wrtCmd
  150 MS
  SLPOUT wrtCmd
  10 MS

  \ Set 16 bit color
  COLMOD wrtCmd
  100 MS
  $55 wrtData 
  10 MS
  MADCTL wrtCmd
  10 MS
  $08 wrtData
  10 MS
  INVON wrtCmd
  10 MS
  NORON wrtCmd
  10 MS 
  DISPON wrtCmd 
  10 MS

  \ Set initial display dimensions and offsets
  LCD_WIDTH  to _width_
  LCD_HEIGHT to _height_

  COL_OFFSET to _xstart_
  ROW_OFFSET to _ystart_

  \ Set rotation
  rotation setRotation

  \ Turn backlight on
  true backlight
;

\ Sets a rectangular display window into which pixel data is written
: setWindow { x0 y0 x1 y1 }

  _xstart_ dup +to x0 +to x1
  _ystart_ dup +to y0 +to y1

  CASET wrtCmd
  x0 wrtData16
  x1 wrtData16
  RASET wrtCmd
  y0 wrtData16
  y1 wrtData16
  RAMWR wrtCmd
;

\ Draw a pixel on the display
: pixel { x y color }
  x y x 1+ y 1+ setWindow 
  color wrtData16
;

\ Fill a rectangle on the display
: fillRect { x0 y0 x1 y1 color }
  x0 y0 x1 y1 setWindow  

  x1 x0 - abs 1+ y1 y0 - abs 1+ * 0

  do
    color wrtData16
  loop
;

\ Fill a rectangle on the display - slightly different signature
: fillRect2 { x0 y0 width height color }
  x0 y0 x0 width + 1- y0 height + 1- color fillRect
;

\ Fill the LCD display with a color
: fillLCD { color }
  0 0 _width_ 1- _height_ 1- 
  color fillRect
;

\ Clear the LCD display to black
: clearLCD ( -- )
  BLK fillLCD
;

forth


