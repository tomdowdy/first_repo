\
\ 4 Color SPI Grayscale Driver for MagTag ePaper display with IL0373 Controller
\ Driver supports full display updates. Partial updates not supported.
\ Written in ESP32forth
\ MAGTAG.fth is required
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 03/07/2023
\

\ ***************************************************************************
\ ***                       IL0373 Controller Commands                    ***
\ ***************************************************************************

$00 constant PANEL_SETTING
$01 constant POWER_SETTING
$02 constant POWER_OFF
$04 constant POWER_ON
$06 constant BOOSTER_SOFT_START
$10 constant DTM1
$12 constant DISPLAY_REFRESH
$13 constant DTM2
$30 constant PLL
$50 constant CDI
$61 constant RESOLUTION
$82 constant VCM_DC_SETTING

\ ***************************************************************************
\ ***                     IL0373 Initialization Sequences                 ***
\ ***************************************************************************

create GRAY4_INIT_CODE
  POWER_SETTING c, 5 c, $03 c, $00 c, $2B c, $2B c, $13 c,
  BOOSTER_SOFT_START c, 3 c, $17 c, $17 c, $17 c,
  POWER_ON c, 0 c,
  $FF c, 200 c,
  PANEL_SETTING c, 1 c, $3F c,
  PLL c, 1 c, $3C c,    
  VCM_DC_SETTING c, 1 c, $12 c,
  CDI c, 1 c, $97 c,
  $FE c, \ EOM

\ ***************************************************************************
\ ***                         Look Up Tables (LUTs)                       ***
\ ***************************************************************************

create GRAY4_LUT_CODE
  \ LUT_VCOM
  $20 c,  42 c,
  $00 c, $0A c, $00 c, $00 c, $00 c, $01 c,
  $60 c, $14 c, $14 c, $00 c, $00 c, $01 c,
  $00 c, $14 c, $00 c, $00 c, $00 c, $01 c,
  $00 c, $13 c, $0A c, $01 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

  \ LUT_WW
  $21 c,  42 c,
  $40 c, $0A c, $00 c, $00 c, $00 c, $01 c,
  $90 c, $14 c, $14 c, $00 c, $00 c, $01 c,
  $10 c, $14 c, $0A c, $00 c, $00 c, $01 c,
  $A0 c, $13 c, $01 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

  \ LUT_BW
  $22 c,  42 c,
  $40 c, $0A c, $00 c, $00 c, $00 c, $01 c,
  $90 c, $14 c, $14 c, $00 c, $00 c, $01 c,
  $00 c, $14 c, $0A c, $00 c, $00 c, $01 c,
  $99 c, $0C c, $01 c, $03 c, $04 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

  \ LUT_WB
  $23 c,  42 c,
  $40 c, $0A c, $00 c, $00 c, $00 c, $01 c,
  $90 c, $14 c, $14 c, $00 c, $00 c, $01 c,
  $00 c, $14 c, $0A c, $00 c, $00 c, $01 c,
  $99 c, $0B c, $04 c, $04 c, $01 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

  \ LUT_BB
  $24 c,  42 c,
  $80 c, $0A c, $00 c, $00 c, $00 c, $01 c,
  $90 c, $14 c, $14 c, $00 c, $00 c, $01 c,
  $20 c, $14 c, $0A c, $00 c, $00 c, $01 c,
  $50 c, $13 c, $01 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

  $FE c, \ EOM

\ ***************************************************************************
\ ***                     Global Constants and Variables                  ***
\ ***************************************************************************

\ Available colors
0 constant EPD_WHITE
1 constant EPD_LIGHTGRAY
2 constant EPD_DARKGRAY
3 constant EPD_BLACK

\ Display oriented dimensions
EPD_WIDTH  value width
EPD_HEIGHT value height

\ Current display rotation
0 value rotation

\ Frame buffers - 1 for color plane, 1 for black plane
EPD_WIDTH EPD_HEIGHT * 8 / constant FRAME_BUFFER_SIZE
FRAME_BUFFER_SIZE byteArray COLOR_BUFFER 
FRAME_BUFFER_SIZE byteArray BLACK_BUFFER 

\ ***************************************************************************
\ ***                          Low Level Words                            ***
\ ***************************************************************************

\ Bring in SPI vocabulary
also SPI

\ Reset hardware
: resetHardware ( -- )

  \ Give the IL0373 display controller a hard reset
  50 ms
  EPD_RESET LOW digitalWrite
  50 ms
  EPD_RESET HIGH digitalWrite
  50 ms
;

\ Initialize the hardware
: initializeHardware ( -- )

  \ Busy is an input
  EPD_BUSY  INPUT_PULLUP pinMode

  \ Now set all other GPIO lines to outputs
  EPD_RESET OUTPUT pinMode
  EPD_DC    OUTPUT pinMode
  EPD_CS    OUTPUT pinMode

  \ Next, set initial levels
  EPD_RESET HIGH digitalWrite
  EPD_DC    HIGH digitalWrite
  EPD_CS    HIGH digitalWrite

  \ Initialize VSPI interface
  EPD_SCK EPD_MISO EPD_MOSI EPD_CS VSPI.begin
  EPD_SPI_FREQUENCY VSPI.setFrequency

  \ Reset hardware
  resetHardware
;

\ SPI data transfer
: sendData ( data -- )
    
  EPD_CS LOW digitalWrite
  VSPI.write
  EPD_CS HIGH digitalWrite
;

\ Send a command
: sendCommand ( cmd -- )

  EPD_DC LOW digitalWrite
  sendData
  EPD_DC HIGH digitalWrite
;
  
\ Wait for the busy signal to end (goes HIGH)
: busyWait ( -- )

  begin
    10 delay
    EPD_BUSY digitalRead 
  until
;

\ Send command list
: sendCommandList { addr } ( addr -- )

  0 0 { cmd args }
  begin
    addr c@ $FE <>
  while
    addr c@ to cmd
    1 +to addr
    addr c@ to args
    1 +to addr
    cmd $FF =
    if
      busyWait
      args delay
    else
      cmd sendCommand
      args 0 >
      if
        args 0
        do
          addr c@ sendData
          1 +to addr
        loop
      then
    then
  repeat
;
  
\ Clear all data buffers
: clearBuffers ( -- )

  0 COLOR_BUFFER FRAME_BUFFER_SIZE $FF fill
  0 BLACK_BUFFER FRAME_BUFFER_SIZE $FF fill
;

\ Write frame buffer to EPD
: writeFrameBufferToEPD { addr n index }

  index 0=
  if
    \ Start writing BW data
    DTM1 sendCommand
  else
    \ Start writing RED data
    DTM2 sendCommand
  then

  EPD_CS LOW digitalWrite
  addr n + addr
  do
    i c@ VSPI.write
  loop
  EPD_CS HIGH digitalWrite
;

\ Set display rotation
: setRotation ( rotation -- )

  4 mod
  dup to rotation
  case
    0 of EPD_WIDTH to width  EPD_HEIGHT to height endof
    1 of EPD_WIDTH to height EPD_HEIGHT to width  endof
    2 of EPD_WIDTH to width  EPD_HEIGHT to height endof
    3 of EPD_WIDTH to height EPD_HEIGHT to width  endof
  endcase
;

\ Power on display
: powerOn ( -- )

  \ Reset the hardware
  resetHardware

  GRAY4_INIT_CODE sendCommandList
  GRAY4_LUT_CODE  sendCommandList
  
  RESOLUTION sendCommand
  EPD_WIDTH          sendData
  EPD_HEIGHT 8 >>    sendData
  EPD_HEIGHT $FF and sendData
;

\ Power off display
: powerOff

  CDI sendCommand
  $17 sendData
  VCM_DC_SETTING sendCommand
  $00 sendData
  POWER_OFF sendCommand
;

\ Display the contents of the frame buffers
: display ( -- )

  powerOn

  0 COLOR_BUFFER FRAME_BUFFER_SIZE 1 writeFrameBufferToEPD
  20 delay
  0 BLACK_BUFFER FRAME_BUFFER_SIZE 0 writeFrameBufferToEPD

  \ Update display
  DISPLAY_REFRESH sendCommand

  100 delay

  busyWait

  powerOff
;

\ Initialize the hardware and the display controller
: initEPD ( rotation -- )

  \ Set the display rotation
  setRotation

  \ Initialize the hardware
  initializeHardware

  \ Clear display buffers
  clearBuffers

  powerOff
;

\ ***************************************************************************
\ ***                     Low Level Graphics Functions                    ***
\ ***************************************************************************

\ Draw a pixel at x,y with color
: pixel { x y color } ( x y color -- ) 

  x 0 < x 295 > or
  y 0 < y 127 > or or
  if 
    ." x: " x . ." y: " y . ."  out of range" cr
  then

  0 0 0 0 { t index blackBit colorBit }
  rotation
  case
    0
     of
       \ Nothng to do
     endof
    1
     of
       x to t y to x t to y
       EPD_WIDTH x - 1- to x
     endof
    2
     of
       EPD_WIDTH  x - 1- to x
       EPD_HEIGHT y - 1- to y
     endof
    3
     of
       x to t y to x t to y
       EPD_HEIGHT y - 1- to y
     endof
  endcase

  color
  case
    EPD_WHITE
    of
      false to colorBit
      false to blackBit
    endof
    EPD_LIGHTGRAY
    of
      true  to colorBit
      false to blackBit
    endof
    EPD_DARKGRAY
    of
      false to colorBit
      true  to blackBit
    endof
    EPD_BLACK
    of
      true to colorBit
      true to blackBit
    endof
  endcase

  \ ." x: " x . ."  y: " y . cr

  \ Calculate index into frame buffer for byte containing pixel
  y 16 * x 8 / + to index

  \ ." Index: " index . cr


  colorBit 
  if
    index COLOR_BUFFER c@ 1 7 x 8 mod - << invert and index COLOR_BUFFER c!
  else
    index COLOR_BUFFER c@ 1 7 x 8 mod - <<        or  index COLOR_BUFFER c!
  then

  blackBit 
  if
    index BLACK_BUFFER c@ 1 7 x 8 mod - << invert and index BLACK_BUFFER c!
  else
    index BLACK_BUFFER c@ 1 7 x 8 mod - <<        or  index BLACK_BUFFER c!
  then
;

only forth definitions
