\ ST7735 65K Color LCD Display Driver
\ Dimensions: 128x160 on Sainsmart SPI Display
\ Written for ESP32Forth
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 07/14/2023

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

 2 value COL_OFFSET
 0 value ROW_OFFSET
 0 value _xstart_
 0 value _ystart_

\ Dimensions of display with current rotation
0 value _width_
0 value _height_

SPI 

\ Write an 8 bit command to the display via SPI
: wrtCmd ( cmd -- )  
  LCD_CS_PIN LOW digitalWrite
  LCD_DC_PIN LOW digitalWrite
  VSPI.write
  LCD_DC_PIN HIGH digitalWrite
  LCD_CS_PIN HIGH digitalWrite
;

\ Write 8 bit data to the display via SPI
: wrtData ( data -- ) 
  LCD_CS_PIN LOW digitalWrite
  VSPI.write
  LCD_CS_PIN HIGH digitalWrite
;

\ Write 16 bit data to the display via SPI
: wrtData16 ( data -- ) 
  LCD_CS_PIN LOW digitalWrite
  VSPI.write16
  LCD_CS_PIN HIGH digitalWrite
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
    LCD_BL_PIN HIGH digitalWrite
  else
    LCD_BL_PIN LOW  digitalWrite
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
      CTL_BGR wrtData
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Landscape
    1 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_BGR CTL_MX CTL_MV or or wrtData
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
    \ Inverted portrait
    2 of
      COL_OFFSET to _xstart_
      ROW_OFFSET to _ystart_
      CTL_BGR CTL_MX CTL_MY or or wrtData
      LCD_WIDTH  to _width_
      LCD_HEIGHT to _height_
    endof
    \ Inverted landscape
    3 of
      ROW_OFFSET to _xstart_
      COL_OFFSET to _ystart_
      CTL_BGR CTL_MV CTL_MY or or wrtData
      LCD_HEIGHT to _width_
      LCD_WIDTH  to _height_
    endof
  endcase
;

\ Initialize the VSPI interface and the display controller
: initLCD { rotation }

  \ Configure GPIO pins
  LCD_CS_PIN OUTPUT pinMode
  LCD_BL_PIN OUTPUT pinMode
  LCD_DC_PIN OUTPUT pinMode
  LCD_RESET_PIN OUTPUT pinMode

  \ Initialize GPIO pins
  LCD_CS_PIN HIGH digitalWrite
  LCD_BL_PIN HIGH digitalWrite
  LCD_DC_PIN HIGH digitalWrite
  LCD_RESET_PIN HIGH digitalWrite

  \ Initialize VSPI interface
  LCD_SCLK_PIN -1 LCD_MOSI_PIN LCD_CS_PIN VSPI.begin
  LCD_SPI_FREQUENCY VSPI.setFrequency

  \ Give the ST7735 a hard reset
  50 delay
  LCD_RESET_PIN LOW digitalWrite
  50 delay
  LCD_RESET_PIN HIGH digitalWrite
  50 delay

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


