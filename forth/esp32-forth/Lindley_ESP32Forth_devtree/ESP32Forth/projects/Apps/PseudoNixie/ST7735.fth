\ ST7735 65K Color LCD Display Driver
\ Dimensions: 80x160 on SPI Display
\ Written for ESP32Forth
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 05/11/2025

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

 0 value COL_OFFSET
 0 value ROW_OFFSET
 0 value _xstart_
 0 value _ystart_

\ Dimensions of display with current rotation
0 value _width_
0 value _height_

SPI 

\ Write an 8 bit command to the display via VSPI
: wrtCmd ( cmd -- )  
  LCD_DC_PIN LOW digitalWrite
  VSPI.write
  LCD_DC_PIN HIGH digitalWrite
;

\ Get the current display width
: getLCDWidth ( -- width )
  _width_
;

\ Get the current display height
: getLCDHeight ( -- height )
  _height_
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
      CTL_BGR VSPI.write
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Landscape
    1 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_BGR CTL_MX CTL_MV or or VSPI.write
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
    \ Inverted portrait
    2 of
      COL_OFFSET to _xstart_
      ROW_OFFSET to _ystart_
      CTL_BGR CTL_MX CTL_MY or or VSPI.write
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Inverted landscape
    3 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_BGR CTL_MV CTL_MY or or VSPI.write
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
  endcase
;

\ Initialize the VSPI interface and the display controller
: initLCD { rotation }

  \ Initialize VSPI interface
  \ NOTE: assigning -1 to MISO will make it use the default pin
  \ Assigning 0 to MISO will use GPIO 0
\ LCD_SCLK_PIN -1 LCD_MOSI_PIN -1 VSPI.begin
  LCD_SCLK_PIN 0 LCD_MOSI_PIN -1 VSPI.begin
  LCD_SPI_FREQUENCY VSPI.setFrequency

  \ Setup LCD slave device
  SWRESET wrtCmd
  150 MS
  SLPOUT wrtCmd
  10 MS

  \ Set 16 bit color
  COLMOD wrtCmd
  100 MS
  $05 VSPI.write 
  10 MS
  MADCTL wrtCmd
  10 MS
  $08 VSPI.write
  10 MS
  INVOFF wrtCmd
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
;

\ Sets a rectangular display window into which pixel data is written
: setWindow { x0 y0 x1 y1 }

  _xstart_ dup +to x0 +to x1
  _ystart_ dup +to y0 +to y1

  CASET wrtCmd
  x0 VSPI.write16
  x1 VSPI.write16
  RASET wrtCmd
  y0 VSPI.write16
  y1 VSPI.write16
  RAMWR wrtCmd
;

\ Draw a pixel on the display
: pixel { x y color }
  x y x 1+ y 1+ setWindow 
  color VSPI.write16
;

\ Draw vertical line of length with color
: vLine		{ x y len color }
  len 0
  do
    x i y + color pixel
  loop
;

\ Fill a rectangle on the display
: fillRect { x0 y0 x1 y1 color }
  x0 y0 x1 y1 setWindow  

  x1 x0 - abs 1+ y1 y0 - abs 1+ * 0

  do
    color VSPI.write16
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


