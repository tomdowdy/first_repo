\
\ Full Update Monochrome SPI Driver - Full frame buffer always copied to display
\ Partial updates not supported
\ for the MagTag 2.9" ePaper display with IL0373 Display Controller
\ Written in ESP32forth
\ MAGTAG.fth is required
\ Written by: Craig A. Lindley
\ Last Update: 03/05/2023
\

\ ***************************************************************************
\ ***                         Look Up Tables (LUTs)                       ***
\ ***************************************************************************

\ LUTs all are 42 bytes in size except for LUT20 which is 44
42 constant LUT_SIZE

create LUT20_VCOM_DC_FULL
  $00 c, $08 c, $00 c, $00 c, $00 c, $02 c,	
  $60 c, $28 c, $28 c, $00 c, $00 c, $01 c,	
  $00 c, $14 c, $00 c, $00 c, $00 c, $01 c,	
  $00 c, $12 c, $12 c, $00 c, $00 c, $01 c,	
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,	
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,	
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,	
  $00 c, $00 c,			

create LUT21_W2W_FULL
  $40 c, $08 c, $00 c, $00 c, $00 c, $02 c,
  $90 c, $28 c, $28 c, $00 c, $00 c, $01 c,
  $40 c, $14 c, $00 c, $00 c, $00 c, $01 c,
  $A0 c, $12 c, $12 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

create LUT22_B2W_FULL
  $40 c, $08 c, $00 c, $00 c, $00 c, $02 c,
  $90 c, $28 c, $28 c, $00 c, $00 c, $01 c,
  $40 c, $14 c, $00 c, $00 c, $00 c, $01 c,
  $A0 c, $12 c, $12 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

create LUT23_W2B_FULL
  $80 c, $08 c, $00 c, $00 c, $00 c, $02 c,
  $90 c, $28 c, $28 c, $00 c, $00 c, $01 c,
  $80 c, $14 c, $00 c, $00 c, $00 c, $01 c,
  $50 c, $12 c, $12 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

create LUT24_B2B_FULL
  $80 c, $08 c, $00 c, $00 c, $00 c, $02 c,
  $90 c, $28 c, $28 c, $00 c, $00 c, $01 c,
  $80 c, $14 c, $00 c, $00 c, $00 c, $01 c,
  $50 c, $12 c, $12 c, $00 c, $00 c, $01 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

\ ***************************************************************************
\ ***                     Global Constants and Variables                  ***
\ ***************************************************************************

\ Color definitions
$00 constant EPD_BLACK
$FF constant EPD_WHITE

\ Display physical dimensions - defined in MagTag.fth
\ 128 constant EPD_WIDTH
\ 296 constant EPD_HEIGHT

\ Display oriented dimensions
EPD_WIDTH  value width
EPD_HEIGHT value height

\ Frame buffer
EPD_WIDTH 8 / EPD_HEIGHT * constant FRAME_BUFFER_SIZE
FRAME_BUFFER_SIZE byteArray FRAME_BUFFER 

0 value powerIsOn
0 value rotation

\ ***************************************************************************
\ ***                          Low Level Words                            ***
\ ***************************************************************************

\ Fill the Frame Buffer with specified color (black or white)
: fillFrameBuffer ( color -- )
  0 FRAME_BUFFER FRAME_BUFFER_SIZE rot fill
;

\ Bring in SPI vocabulary
also SPI

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
  
  \ Give the IL0373 display controller a hard reset
  100 ms
  EPD_RESET LOW digitalWrite
  100 ms
  EPD_RESET HIGH digitalWrite
  100 ms

  false to powerIsOn
;

\ SPI data transfer
: sendData ( data -- )
    
  EPD_CS LOW digitalWrite
  VSPI.write
  EPD_CS HIGH digitalWrite
;

\ Send data buffer
: sendDataBuffer ( a n -- )

  EPD_CS LOW digitalWrite
  over + swap
  do
    i c@ VSPI.write
  loop
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
    10 ms
    EPD_BUSY digitalRead 
  until
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

\ Rotate the x, y, w and h coordinates according to the rotation value set above
: rotate { x y w h } ( x y w h -- x' y' w' h' )
 
  0 { t }
  rotation
  case
    0 
     of    
       \ Nothing to do here
     endof
    1 
     of 
       x to t y to x t to y
       w to t h to w t to h
       EPD_WIDTH x - w - to x
     endof
    2
     of
       EPD_WIDTH  x - w - to x
       EPD_HEIGHT y - h - to y
    endof
    3
     of
       x to t y to x t to y
       w to t h to w t to h
       EPD_HEIGHT y - h - to y
     endof
  endcase
  x y w h
;

\ Power on display
: powerOn ( -- )

  powerIsOn false =
  if
    $04 sendCommand
    busyWait
    true to powerIsOn
  then
;

\ Power off display
: powerOff

  $02 sendCommand
  busyWait
  false to powerIsOn
;

\ Set RAM access region -  In this case all of the EPD RAM
: setFullRAMRegion ( -- )

  0 0 127 295 { x y xe ye }

  $90 sendCommand \ partial window
  x 256  mod sendData
  xe 256 mod sendData
  y 256 /    sendData
  y 256 mod  sendData
  ye 256 /   sendData
  ye 256 mod sendData
  $01        sendData
;

\ Initialize the EPD for operation
: initializeDisplay ( -- )

  $01 sendCommand  \ POWER SETTING
  $03 sendData
  $00 sendData
  $2B sendData
  $2B sendData
  $03 sendData
  $06 sendCommand \ boost soft start
  $17 sendData    \ A
  $17 sendData    \ B
  $17 sendData    \ C
  $00 sendCommand \ panel setting
  $BF sendData    
  $0D sendData    \ VCOM to 0V fast
  $30 sendCommand \ PLL setting
  $3A sendData    \ 3a 100HZ   29 150Hz 39 200HZ 31 171HZ
  $61 sendCommand \ resolution setting
  EPD_WIDTH sendData
  EPD_HEIGHT 8 >> sendData
  EPD_HEIGHT $FF and sendData

  $82 sendCommand \ vcom_DC setting
  $08 sendData
  $50 sendCommand \ VCOM AND DATA INTERVAL SETTING
  $97 sendData    \ WBmode:VBDF 17|D7 VBDW 97 VBDB 57 WBRmode:VBDF F7 VBDW 77 VBDB 37  VBDR B7
  $20 sendCommand
  LUT20_VCOM_DC_FULL LUT_SIZE 2 + sendDataBuffer
  $21 sendCommand
  LUT21_W2W_FULL LUT_SIZE sendDataBuffer
  $22 sendCommand
  LUT22_B2W_FULL LUT_SIZE sendDataBuffer
  $23 sendCommand
  LUT23_W2B_FULL LUT_SIZE sendDataBuffer
  $24 sendCommand
  LUT24_B2B_FULL LUT_SIZE sendDataBuffer
  powerOn

  setFullRAMRegion
;

\ Display the contents of the frame buffer
: display ( -- )

  powerOn

  \ Write frame buffer image to display
  $13 sendCommand

  FRAME_BUFFER_SIZE 0
  do
    i FRAME_BUFFER c@ sendData
  loop

  $92 sendCommand
  1 delay

  \ Update display
  $12 sendCommand
  busyWait

  powerOff
;

\ Initialize the hardware and the display controller
: initEPD ( rotation -- )

  \ Set the display rotation
  setRotation

  \ Initialize the hardware
  initializeHardware

  \ Initialize EPD display
  initializeDisplay

  \ Clear frame buffer
  EPD_WHITE fillFrameBuffer
;

\ ***************************************************************************
\ ***                     Low Level Graphics Functions                    ***
\ ***************************************************************************

\ Draw a pixel at x,y with color
: pixel { x y color } ( x y color -- )

  0 { t }
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

  \ Calculate index into frame buffer for byte containing pixel
  x 8 / y EPD_WIDTH 8 / * + to t

  color
  if
    t FRAME_BUFFER c@ $01   7 x 8 mod - << or      t FRAME_BUFFER c!
  else
    t FRAME_BUFFER c@ $FF 1 7 x 8 mod - << xor and t FRAME_BUFFER c!
  then
;

only forth definitions
