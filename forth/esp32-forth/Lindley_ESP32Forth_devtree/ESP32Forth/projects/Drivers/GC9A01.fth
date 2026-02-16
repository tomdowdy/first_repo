\
\ SPI Driver for the GC9A01 Display Controller of round LCD
\ Written for ESP32forth
\ Written by Craig A. Lindley
\ Last Update: 3/15/2023

\ Electrical connections to ESP32 D1 Mini
 5 constant LCD_CS
18 constant LCD_SCK
23 constant LCD_MOSI
19 constant LCD_MISO \ Not used
26 constant LCD_DC
33 constant LCD_RESET
22 constant LCD_BL

40000000 constant LCD_SPI_FREQUENCY

\ LCD dimensions
240 constant LCD_WIDTH
240 constant LCD_HEIGHT

\ Display controller constants
$20 constant INVOFF
$21 constant INVON
$29 constant DISPON

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

$35 constant TEON
$3A constant PIXFMT

$C3 constant VREG1A
$C4 constant VREG1B
$C9 constant VREG2A

$FE constant INREGEN1
$EF constant INREGEN2
$F0 constant GAMMA1
$F1 constant GAMMA2
$F2 constant GAMMA3
$F3 constant GAMMA4

$E1 constant GMCTRN1
$E8 constant FRAMERATE

$11 constant SLPOUT
$29 constant DISPON

\ Initialization data
create INIT_DATA
  INREGEN2 c, 0 c, $EB c, 1 c, $14 c,
  INREGEN1 c, 0 c,
  INREGEN2 c, 0 c,
  $EB c, 1 c, $14 c, $84 c, 1 c, $40 c, $85 c, 1 c, $FF c,
  $86 c, 1 c, $FF c, $87 c, 1 c, $FF c, $88 c, 1 c, $0A c,
  $89 c, 1 c, $21 c, $8A c, 1 c, $00 c, $8B c, 1 c, $80 c,
  $8C c, 1 c, $01 c, $8D c, 1 c, $01 c, $8E c, 1 c, $FF c,
  $8F c, 1 c, $FF c, $B6 c, 2 c, $00 c, $00 c,
  MADCTL c, 1 c, MADCTL_MX MADCTL_BGR or c,
  PIXFMT c, 1 c, $05 c,
  $90 c, 4 c, $08 c, $08 c, $08 c, $08 c, $BD c, 1 c, $06 c,
  $BC c, 1 c, $00 c, $FF c, 3 c, $60 c, $01 c, $04 c,
  VREG1A c, $13 c,
  VREG1B c, $13 c,
  VREG2A c, $22 c,
  $BE c, 1 c, $11 c,
  GMCTRN1 c, 2 c, $10 c, $0E c,
  $DF c, 3 c, $21 c, $0c c, $02 c,
  GAMMA1 c, 6 c, $45 c, $09 c, $08 c, $08 c, $26 c, $2A c,
  GAMMA2 c, 6 c, $43 c, $70 c, $72 c, $36 c, $37 c, $6F c,
  GAMMA3 c, 6 c, $45 c, $09 c, $08 c, $08 c, $26 c, $2A c,
  GAMMA4 c, 6 c, $43 c, $70 c, $72 c, $36 c, $37 c, $6F c,
  $ED c, 2 c, $1B c, $0B c, $AE c,    1 c, $77 c, $CD c,    1 c, $63 c,
  $70 c, 9 c, $07 c, $07 c, $04 c, $0E c, $0F c, $09 c, $07 c, $08 c, $03 c,
  FRAMERATE c, 1 c, $34 c,
  $62 c, 12 c, $18 c, $0D c, $71 c, $ED c, $70 c, $70 c, $18 c, $0F c,
  $71 c, $EF c, $70 c, $70 c, $63 c, 12 c, $18 c, $11 c, $71 c, $F1 c, 
  $70 c, $70 c, $18 c, $13 c, $71 c, $F3 c, $70 c, $70 c,
  $64 c, 7 c, $28 c, $29 c, $F1 c, $01 c, $F1 c, $00 c, $07 c,
  $66 c, 10 c, $3C c, $00 c, $CD c, $67 c, $45 c, $45 c, $10 c, $00 c,
  $00 c, $00 c, $67 c, 10 c, $00 c, $3C c, $00 c, $00 c, $00 c, $01 c, 
  $54 c, $10 c, $32 c, $98 c, $74 c, 7 c, $10 c, $85 c, $80 c, $00 c,
  $00 c, $4E c, $00 c, $98 c, 2 c, $3e c, $07 c,
  TEON c, 0 c,
  INVON c, 0 c,
  SLPOUT c, $80 c, \ Exit sleep
  DISPON c, $80 c, \ Display on
  $00 c,           \ End of list

\ Initialize GPIO and reset controller
: initAndReset ( -- )

  \ First set all lines to outputs
  LCD_RESET OUTPUT pinMode
  LCD_DC    OUTPUT pinMode
  LCD_CS    OUTPUT pinMode
  LCD_BL    OUTPUT pinMode

  \ Next c, set initial levels
  LCD_RESET HIGH digitalWrite
  LCD_DC    HIGH digitalWrite
  LCD_CS    HIGH digitalWrite
  LCD_BL    HIGH digitalWrite

  \ Give the ILI9341 display controller a hard reset
  50 ms
  LCD_RESET LOW digitalWrite
  50 MS
  LCD_RESET HIGH digitalWrite
  50 ms
;

\ Bring in SPI vocabulary
SPI

\ Initialize HSPI interface
: initSPI ( -- )
  LCD_SCK LCD_MISO LCD_MOSI LCD_CS VSPI.begin
  LCD_SPI_FREQUENCY VSPI.setFrequency
 ;

\ Write 8 bit data to LCD controller
: wrt8Data ( data -- )
  LCD_CS LOW digitalWrite
  VSPI.write
  LCD_CS HIGH digitalWrite
;

\ Write 8 bit command to LCD controller
: wrt8Cmd ( cmd -- )
  LCD_DC LOW digitalWrite
  wrt8Data
  LCD_DC HIGH digitalWrite
;
 
\ Write command and data
: wrt8CmdData { cmd addr n }
  cmd wrt8Cmd
  n 0 >
  if
    addr n + addr
    do
      i c@ wrt8Data
    loop
  then
;

\ Write 16 bit data to LCD controller
: wrt16Data ( data -- )
  LCD_CS LOW digitalWrite
  VSPI.write16
  LCD_CS HIGH digitalWrite
;

\ Retrieve byte data at index
: getData ( index -- data )
  INIT_DATA + c@
;

\ Load initialization data into the ILI9341 display controller
: loadData ( -- )

  0 0 0 0 { indx x cmd args }
  
  begin
    indx getData to cmd
    1 +to indx
    cmd 0 >
  while
    indx getData to x
    1 +to indx
    x $7F and to args
    
    cmd INIT_DATA indx + args wrt8CmdData
    args +to indx
    x $80 and
    if
      150 delay
    then
  repeat
;

\ Return width of LCD screen
: getLCDWidth
  LCD_WIDTH
;

\ Return height of LCD screen
: getLCDHeight
  LCD_HEIGHT
;

\ Backlight control function doesn't work on early T4 devices
: backlight ( high/low -- )
  if 
    LCD_BL HIGH digitalWrite
  else
    LCD_BL LOW  digitalWrite
  then
;

\ Set the LCD display rotation
\ 0 top towards from connector
\ 1 top right of connector
\ 2 top away from the connector
\ 3 top left of connector
: setLCDRotation ( rotation -- )
  4 mod
  0 { cmd }
  case
    0 of 
        MADCTL_MX MADCTL_BGR or to cmd
      endof
    1 of 
        MADCTL_MV MADCTL_BGR or to cmd
      endof
    2 of 
        MADCTL_MY MADCTL_BGR or to cmd
      endof
    3 of 
        MADCTL_MX MADCTL_MY MADCTL_MV MADCTL_BGR or or or to cmd
      endof
  endcase
  MADCTL wrt8Cmd
  cmd wrt8Data
;

\ Set the display RAM address window
: setWindow { x y w h }

  x w + 1- { x1 }
  y h + 1- { y1 }

  CASET wrt8Cmd
   x wrt16Data
  x1 wrt16Data
  RASET wrt8Cmd
   y wrt16Data
  y1 wrt16Data
  RAMWR wrt8Cmd
;

\ Pass 8-bit (each) R c,G c,B c, get back 16-bit packed color
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

  \ Set rotation
  setLCDRotation

  \ Clear the screen
  clearScreen
;

forth
