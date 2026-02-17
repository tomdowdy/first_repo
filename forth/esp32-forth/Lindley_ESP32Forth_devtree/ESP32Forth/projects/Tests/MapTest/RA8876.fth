\
\ Minimal SPI Driver for the RA8876 Controller and 7" SPI Display
\ Written in ESP32forth
\ Ported from RA8876_Lite
\ Written/Ported by: Craig A. Lindley
\ Last Update: 09/17/2021

\ PLL parameters in MHz
\  10 constant OSC_FREQ
\ 120 constant DRAM_FREQ
\ 120 constant CORE_FREQ
\  50 constant SCAN_FREQ

\ LCD dimensions
1024 constant SCREEN_WIDTH
 600 constant SCREEN_HEIGHT

\ Text attribute storage
   0 value FGColor
   0 value BGColor
   0 value charWidth
   0 value charHeight
   0 value isAligned
   0 value isEnlargedW
   0 value isEnlargedH

\ Define display 16bit colors
$0000 constant BLACK
$ffff constant WHITE         
$f800 constant RED
$07e0 constant GREEN        
$001f constant BLUE         
$ffe0 constant YELLOW       
$07ff constant CYAN         
$f81f constant MAGENTA
$A145 constant BROWN        

\ Display controller constants
$00 constant CMDWRITE
$80 constant DATAWRITE
$C0 constant DATAREAD
$40 constant STATUSREAD

$04 constant MRWDP 
  0 constant LVDS_FORMAT
$03 constant ICR  
  0 constant GRAPHIC_MODE
  1 constant TEXT_MODE
  0 constant MEMORY_SELECT_IMAGE

  0 constant DISPLAY_OFF
  1 constant DISPLAY_ON

  1 constant CCR
$CC constant CCR0
$CD constant CCR1

  1 constant PLL_ENABLE
  0 constant KEY_SCAN_DISABLE
  0 constant WAIT_NO_MASK
  0 constant TFT_OUTPUT24
  0 constant I2C_MASTER_DISABLE
  0 constant HOST_DATA_BUS_SERIAL
  2 constant MACR
  0 constant DIRECT_WRITE
  0 constant WRITE_MEMORY_LRTB
  0 constant READ_MEMORY_LRTB
  1 constant SERIAL_IF_ENABLE
  0 constant SELECT_CONFIG_PIP1

  \ Color depth selectors
  1 constant CANVAS_CD_16
  1 constant S0_CD_16
  1 constant S1_CD_16
  1 constant PIP1_CD_16
  1 constant PIP2_CD_16
  1 constant IMAGE_CD_16

  0 constant PIP1_DISABLE
  0 constant PIP2_DISABLE

  0 constant CANVAS_BLOCK_MODE
  0 constant OUTPUT_RGB

$10 constant MPWCTR
$11 constant PIPCDEP
$12 constant DPCR
$13 constant PCSR

$14 constant HDWR
$15 constant HDWFTR
$16 constant HNDR
$17 constant HNDFTR
$18 constant HSTR
$19 constant HPWR

$1A constant VDHR0
$1B constant VDHR1
$1C constant VNDR0
$1D constant VNDR1
$1E constant VSTR
$1F constant VPWR

$20 constant MISA0
$21 constant MISA1
$22 constant MISA2
$23 constant MISA3

$24 constant MIW0
$25 constant MIW1
$26 constant MWULX0
$27 constant MWULX1
$28 constant MWULY0
$29 constant MWULY1

$50 constant CVSSA0
$51 constant CVSSA1
$52 constant CVSSA2
$53 constant CVSSA3
$54 constant CVS_IMWTH0
$55 constant CVS_IMWTH1

$56 constant AWUL_X0
$57 constant AWUL_X1
$58 constant AWUL_Y0
$59 constant AWUL_Y1
$5A constant AW_WTH0
$5B constant AW_WTH1
$5C constant AW_HT0
$5D constant AW_HT1
$5E constant AW_COLOR

$5F constant CURH0
$60 constant CURH1
$61 constant CURV0
$62 constant CURV1

\ Cursor control registers
$63 constant F_CURX0
$64 constant F_CURX1 
$65 constant F_CURY0 
$66 constant F_CURY1 

$68 constant DLHSR0
$69 constant DLHSR1
$6A constant DLVSR0
$6B constant DLVSR1
$6C constant DLHER0
$6D constant DLHER1
$6E constant DLVER0
$6F constant DLVER1

$76 constant DCR1
$77 constant ELL_A0
$78 constant ELL_A1
$79 constant ELL_B0
$7A constant ELL_B1
$7B constant DEHR0
$7C constant DEHR1
$7D constant DEVR0
$7E constant DEVR1

$92 constant BTE_COLR

\ Foreground and background color registers
$D2 constant FGCR  
$D3 constant FGCG
$D4 constant FGCB  
$D5 constant BGCR    
$D6 constant BGCG    
$D7 constant BGCB    

$80 constant CIRCLE
$C0 constant CIRCLE_FILL
$A0 constant RECT
$E0 constant RECT_FILL
$B0 constant ROUNDRECT
$F0 constant ROUNDRECT_FILL

\ TFT timing parameters for 1024x600 resolution
   0 constant TFT_MODE
   1 constant XHSYNC_INV
   1 constant XVSYNC_INV
   0 constant XDE_INV
   1 constant XPCLK_INV
  70 constant HPW
 160 constant HND
1024 constant HDW
 160 constant HST
  10 constant VPW
  23 constant VND
 600 constant VDH
  12 constant VST

\ Return page start address. Pages are 0 .. 10
: pageStartAddr ( pg_num -- addr )
  1024 600 2 * * *
;

\ Bring in SPI vocabulary
also SPI

\ Start low level SPI access functions

\ Write command
: writeCmd ( cmd -- )
  LCD_CS LOW digitalWrite
  CMDWRITE VSPI.write
  VSPI.write
  LCD_CS HIGH digitalWrite
;

\ Write data
: writeData ( data -- )
  LCD_CS LOW digitalWrite
  DATAWRITE VSPI.write
  VSPI.write
  LCD_CS HIGH digitalWrite
;
 
\ Read data
: readData ( -- data )
  LCD_CS LOW digitalWrite
  DATAREAD VSPI.write
  0 VSPI.transfer8
  LCD_CS HIGH digitalWrite
;

\ Read status
: readStatus ( -- status )
  LCD_CS LOW digitalWrite
  STATUSREAD VSPI.write
  0 VSPI.transfer8
  LCD_CS HIGH digitalWrite
;

\ Write register
: writeReg ( reg -- )
  writeCmd
;

\ Register data write
: writeRegData ( reg data -- )
  swap
  writeReg
  writeData
;

\ Register data read
: readRegData ( reg -- data )
  writeReg
  readData
;

\ SPI interface to write 16bpp data
: writeData16 ( data16 -- )
  LCD_CS LOW digitalWrite
  DATAWRITE VSPI.write
  dup
  VSPI.write
  8 >> VSPI.write
  LCD_CS HIGH digitalWrite
;

\ End low level SPI access functions


\ Set text cursor position
: setTextCursor { x y }
  F_CURX0 x      writeRegData
  F_CURX1 x 8 >> writeRegData
  F_CURY0 y      writeRegData
  F_CURY1 y 8 >> writeRegData
;

\ Set foreground color
: setFGColor { color16 }
  color16 to FGColor
  FGCR color16 8 >> writeRegData
  FGCG color16 3 >> writeRegData
  FGCB color16 3 << writeRegData
;

\ Set background color
: setBGColor { color16 }
  color16 to BGColor
  BGCR color16 8 >> writeRegData
  BGCG color16 3 >> writeRegData
  BGCB color16 3 << writeRegData
;

\ Set text color
: setTextColor ( fgColor bgColor -- )
  setBGColor
  setFGColor
;

\ Set text size. Size is 0, 1 or 2
\ Char height is 16, 24 or 32
\ 0 = 8x16/16x16 1 = 12x24/24x24 2 = 16x32/32x32
: setTextSize { size }
  size
  case
    0 of  8 to charWidth 16 to charHeight endof
    1 of 12 to charWidth 24 to charHeight endof
    2 of 16 to charWidth 32 to charHeight endof
  endcase  CCR0 size 4 << writeRegData
;

\ graphics mode control
: graphicsMode ( f -- )
  if
    ICR LVDS_FORMAT 3 << or
    GRAPHIC_MODE 2 << MEMORY_SELECT_IMAGE or
  else
    ICR LVDS_FORMAT 3 << or
    TEXT_MODE 2 << MEMORY_SELECT_IMAGE or
  then
  writeRegData
;

\ Check that controller is ready
: checkReady ( -- f )
  0 0 { count result }
  begin
    1 ms
    readStatus 2 and 0= to result

    1 +to count
    result count 1000 > or
  until
  result
;

\ Check that SDRAM is ready
: checkSdramReady ( -- f )
  0 0 { count result }
  begin
    1 ms
    readStatus 4 and 4 = to result

    1 +to count
    result count 1000 > or
  until
  result
;

\ Check for code task busy
: checkBusy ( -- )
  0 0 { count result }
  begin
    1 ms
    readStatus 8 and 0= to result

    1 +to count
    result count 1000 > or
  until
;

\ Check that write fifo is not full so it can
\ accept a new character
: checkWriteFifoNotFull ( -- )
  0 0 { count result }
  begin
    1 ms
    readStatus $80 and 0= to result

    1 +to count
    result count 1000 > or
  until
;

\ Initialize the PLL
: initPLL ( -- )

  \ Set pixel clock
  $05 $04 writeRegData  \ PLL Divided by 4
  $06 19   writeRegData

  \ Set SDRAM clock
  $07 $02 writeRegData  \ PLL Divided by 2
  $08 23   writeRegData

  \ Set Core clock
  $09 $02 writeRegData  \ PLL Divided by 2
  $0A 23   writeRegData

  1 ms
  $01 writeReg
  $80 writeData
  2 ms
  readData $80 and $80 =
  if true else false then
;

\ Initialize SDRAM
: initSDRAM ( -- f )
  1875 { AR }
  
  $e0 $29     writeRegData      
  $e1 3       writeRegData
  $e2 AR      writeRegData
  $e3 AR 8 >> writeRegData
  $e4 $01     writeRegData

  checkSdramReady
;

\ Display control
: displayOn ( f -- )
  if
    DPCR XPCLK_INV 7 << DISPLAY_ON  6 << OUTPUT_RGB or or 
  else
    DPCR XPCLK_INV 7 << DISPLAY_OFF 6 << OUTPUT_RGB or or 
  then
  writeRegData
;

: horizontalWidthVH { width height }

  width 8 / 1- { temp }
  HDWR    temp writeRegData
  width 8 mod to temp
  HDWFTR  temp writeRegData
  height 1- to   temp
  VDHR0   temp writeRegData
  height 1- 8 >> to temp
  VDHR1  temp writeRegData
;

: horizontalNonDisplay { numbers }
  0 { temp }
  numbers 8 <
  if 
    HNDR  $00      writeRegData
    HNDFTR numbers writeRegData
  else
    numbers 8 / 1- to temp
    HNDR temp      writeRegData
    numbers 8 mod  to temp
   HNDFTR temp     writeRegData
  then
;

: hSyncStart { numbers }
  0 { temp }
  numbers 8 <
  if
    HSTR $00 writeRegData
  else
    numbers 8 / 1- to temp
    HSTR temp writeRegData
  then
;

: hSyncPW { numbers }
  0 { temp }
  numbers 8 <
  if
    HPWR $00 writeRegData
  else
    numbers 8 / 1- to temp
    HPWR temp writeRegData
  then
;

: verticalNonDisplay { numbers }
  numbers 1- { temp }
  VNDR0 temp      writeRegData
  VNDR1 temp 8 >> writeRegData
;

: vSyncStart { numbers }
  numbers 1- { temp }
  VSTR temp writeRegData
;

: vSyncPW { numbers }
  numbers 1- { temp }
  VPWR temp writeRegData
;

: displayImageAddr { addr }
  MISA0 addr       writeRegData
  MISA1 addr  8 >> writeRegData 
  MISA2 addr 16 >> writeRegData 
  MISA3 addr 24 >> writeRegData 
;

: displayImageWidth { width }
  MIW0 width      writeRegData
  MIW1 width 8 >> writeRegData 
;

: displayWindowStartXY { x y }
  MWULX0 x      writeRegData
  MWULX1 x 8 >> writeRegData
  MWULY0 y      writeRegData
  MWULY1 y 8 >> writeRegData
;

: canvasImageAddr { addr }
  CVSSA0 addr       writeRegData
  CVSSA1 addr  8 >> writeRegData
  CVSSA2 addr 16 >> writeRegData
  CVSSA3 addr 24 >> writeRegData
;

: canvasImageWidth { width }
  CVS_IMWTH0 width      writeRegData
  CVS_IMWTH1 width 8 >> writeRegData
;

: activeWindowXY { x y }
  AWUL_X0 x      writeRegData
  AWUL_X1 x 8 >> writeRegData  
  AWUL_Y0 y      writeRegData
  AWUL_Y1 y 8 >> writeRegData 
;

: activeWindowWH { width height }

  AW_WTH0 width      writeRegData
  AW_WTH1 width 8 >> writeRegData
  AW_HT0 height      writeRegData
  AW_HT1 height 8 >> writeRegData
;

: setPixelCursor { x y }
  CURH0 x      writeRegData
  CURH1 x 8 >> writeRegData
  CURV0 y      writeRegData
  CURV1 y 8 >> writeRegData
;

\ Initialize the controller
: initialize ( -- f )

  \ Initialize the PLL
  initPLL FALSE =
  if ." PLL initialization failed" false exit then

  \ Initialize SDRAM
  initSDRAM FALSE =
  if ." SDRAM initialization failed" false exit then

  CCR writeReg
  PLL_ENABLE 7 << WAIT_NO_MASK 6 << or
  KEY_SCAN_DISABLE 5 << TFT_OUTPUT24 3 << or
  I2C_MASTER_DISABLE 2 << SERIAL_IF_ENABLE 1 << or
  HOST_DATA_BUS_SERIAL or or or
  writeData

  MACR writeReg
  DIRECT_WRITE 6 << READ_MEMORY_LRTB 4 << or
  WRITE_MEMORY_LRTB 1 << or
  writeData

  ICR writeReg
  LVDS_FORMAT 3 << GRAPHIC_MODE 2 << MEMORY_SELECT_IMAGE or or
  writeData

  MPWCTR writeReg
  PIP1_DISABLE 7 << PIP2_DISABLE 6 << or
  SELECT_CONFIG_PIP1 4 << IMAGE_CD_16 2 << or
  TFT_MODE or or
  writeData

  PIPCDEP writeReg
  PIP1_CD_16 2 << PIP2_CD_16 or
  writeData

  AW_COLOR writeReg
  CANVAS_BLOCK_MODE 2 << CANVAS_CD_16 or
  writeData

  BTE_COLR
  S0_CD_16 5 << S1_CD_16 2 << or
  S0_CD_16 or
  writeRegData

  \ TFT timing configuration
  DPCR writeReg
  XPCLK_INV 7 << DISPLAY_OFF 6 << OUTPUT_RGB or or
  writeData
    
  PCSR writeReg
  XHSYNC_INV 7 << XVSYNC_INV 6 << XDE_INV 5 << or or
  writeData

  HDW VDH horizontalWidthVH
  HND horizontalNonDisplay
  HST hSyncStart
  HPW hSyncPW
  VND verticalNonDisplay
  VST vSyncStart
  VPW vSyncPW
  
  \ Image buffer configuration
  0 pageStartAddr displayImageAddr
  SCREEN_WIDTH displayImageWidth
  0 0 displayWindowStartXY
  0 pageStartAddr canvasImageAddr
  SCREEN_WIDTH canvasImageWidth
  0 0 activeWindowXY
  SCREEN_WIDTH SCREEN_HEIGHT activeWindowWH
  true
;
 
\ Initialize GPIO and reset controller
: begin ( -- f )

  \ Configure HSPI interface for talking to display
  LCD_SCK LCD_MISO LCD_MOSI LCD_CS VSPI.begin
  SPI_FREQ VSPI.setFrequency

  \ First set all outputs
  LCD_RESET OUTPUT pinMode
  LCD_CS    OUTPUT pinMode
  LCD_BL    OUTPUT pinMode

  \ Next, set initial levels
  LCD_RESET HIGH digitalWrite
  LCD_CS    HIGH digitalWrite
  LCD_BL    HIGH digitalWrite

  \ Set single input
  LCD_WAIT  INPUT_PULLUP pinMode

  \ Give the display controller a hard reset
  100 ms
  LCD_RESET LOW digitalWrite
  10 ms
  LCD_RESET HIGH digitalWrite
  10 ms

  checkReady FALSE =
  if false exit then

  \ Read ID code must disable pll, 01h bit7 set 0
  $01 $08 writeRegData
  1 ms

  $FF readRegData $76 <>
  $FF readRegData $77 <> and
  if 
    ." RA8876 or RA8877 not found!"
    false
    exit
  then

  \ Do controller initialization
  initialize FALSE =
  if
    ." RA8876 or RA8877 initialization failed"
    false exit
  then

  \ Set default text colors
  WHITE BLACK setTextColor

  \ Set default text size
  0 setTextSize

  \ Turn the display on
  true displayOn
  true
;

\ Draw a pixel
: drawPixel { x y color16 }
  x y setPixelCursor
  MRWDP writeReg
  color16 writeData16
;

\ Temp storage for foreground color
0 value _fgc

\ Draw a rectangle
: drawRect { x0 y0 x1 y1 color16 }
  FGColor to _fgc
  color16 setFGColor
  DLHSR0 x0      writeRegData
  DLHSR1 x0 8 >> writeRegData
  DLVSR0 y0      writeRegData
  DLVSR1 y0 8 >> writeRegData
  DLHER0 x1      writeRegData
  DLHER1 x1 8 >> writeRegData
  DLVER0 y1      writeRegData
  DLVER1 y1 8 >> writeRegData        
  DCR1 RECT writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a filled rectangle
: drawFilledRect { x0 y0 x1 y1 color16 }
  FGColor to _fgc
  color16 setFGColor
  DLHSR0 x0      writeRegData
  DLHSR1 x0 8 >> writeRegData
  DLVSR0 y0      writeRegData
  DLVSR1 y0 8 >> writeRegData
  DLHER0 x1      writeRegData
  DLHER1 x1 8 >> writeRegData
  DLVER0 y1      writeRegData
  DLVER1 y1 8 >> writeRegData        
  DCR1 RECT_FILL writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw rounded rectangle
: drawRoundedRect { x0 y0 x1 y1 radius color16 }
  FGColor to _fgc
  color16 setFGColor
  DLHSR0 x0      writeRegData
  DLHSR1 x0 8 >> writeRegData
  DLVSR0 y0      writeRegData
  DLVSR1 y0 8 >> writeRegData
  DLHER0 x1      writeRegData
  DLHER1 x1 8 >> writeRegData
  DLVER0 y1      writeRegData
  DLVER1 y1 8 >> writeRegData    
  ELL_A0 radius      writeRegData    
  ELL_A1 radius 8 >> writeRegData 
  ELL_B0 radius      writeRegData    
  ELL_B1 radius 8 >> writeRegData
  DCR1 ROUNDRECT writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw filled rounded rectangle
: drawFilledRoundedRect { x0 y0 x1 y1 radius color16 }
  FGColor to _fgc
  color16 setFGColor
  DLHSR0 x0      writeRegData
  DLHSR1 x0 8 >> writeRegData
  DLVSR0 y0      writeRegData
  DLVSR1 y0 8 >> writeRegData
  DLHER0 x1      writeRegData
  DLHER1 x1 8 >> writeRegData
  DLVER0 y1      writeRegData
  DLVER1 y1 8 >> writeRegData    
  ELL_A0 radius      writeRegData    
  ELL_A1 radius 8 >> writeRegData 
  ELL_B0 radius      writeRegData    
  ELL_B1 radius 8 >> writeRegData
  DCR1 ROUNDRECT_FILL writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a circle
: drawCircle { x y radius color16 }
  FGColor to _fgc
  color16 setFGColor
  DEHR0 x       writeRegData
  DEHR1 x 8 >>  writeRegData
  DEVR0 y       writeRegData
  DEVR1 y 8 >>  writeRegData
  ELL_A0 radius writeRegData    
  ELL_A1 radius 8 >> writeRegData 
  ELL_B0 radius      writeRegData    
  ELL_B1 radius 8 >> writeRegData
  DCR1 CIRCLE writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a filled circle
: drawFilledCircle { x y radius color16 }
  FGColor to _fgc
  color16 setFGColor
  DEHR0 x       writeRegData
  DEHR1 x 8 >>  writeRegData
  DEVR0 y       writeRegData
  DEVR1 y 8 >>  writeRegData
  ELL_A0 radius writeRegData    
  ELL_A1 radius 8 >> writeRegData 
  ELL_B0 radius      writeRegData    
  ELL_B1 radius 8 >> writeRegData
  DCR1 CIRCLE_FILL writeRegData
  checkBusy
  _fgc setFGColor
;

\ Set text attributes
\ align: 0-disabled 1-enabled
\ chroma: 0-disabled 1-enabled 
\ widthEnlarge: 0-1X 1-2X 2-3x 3-4x
\ heightEnlarge: 0-1X 1-2X 2-3x 3-4x
: setTextAttributes { align chroma widthEnlarge heightEnlarge }
  align to isAligned
  widthEnlarge  to isEnlargedW
  heightEnlarge to isEnlargedH
  CCR1 align 7 << chroma 6 << widthEnlarge 2 << heightEnlarge
  or or or writeRegData
;

\ Calculate total char width
: calculateCharWidth ( -- width )
  isAligned 1 =
  if 
    charWidth 2 *
  else
    charWidth
  then
  isEnlargedW
  case
    0 of 1 * endof
    1 of 2 * endof
    2 of 3 * endof
    3 of 4 * endof
  endcase
;

\ Calculate total char height
: calculateCharHeight ( -- height )
  charHeight
  isEnlargedH
  case
    0 of 1 * endof
    1 of 2 * endof
    2 of 3 * endof
    3 of 4 * endof
  endcase
;

\ Calculate width in pixel of a string
: stringWidth ( addr n -- width )
  nip
  calculateCharWidth *
;

\ Write an s" string to the display at specified position
: drawTextString { x y addr n }
  false graphicsMode
  x y setTextCursor
  MRWDP writeReg
  addr n + addr
  do
    checkWriteFifoNotFull
    i c@ writeData
  loop
  checkBusy
  true graphicsMode
;

\ Fill the screen with specified color
: fillScreen ( color16 -- )
  >r 0 0 SCREEN_WIDTH 1- SCREEN_HEIGHT 1- r> drawFilledRect
;

\ Clear the screen to black
: clearScreen ( -- )
  BLACK fillScreen
;

\ Return width of LCD screen
: getScreenWidth
  SCREEN_WIDTH
;

\ Return height of LCD screen
: getScreenHeight
  SCREEN_HEIGHT
;

\ Backlight control function
: backlight ( high/low -- )
  if 
    LCD_BL HIGH digitalWrite
  else
    LCD_BL LOW  digitalWrite
  then
;

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

only forth definitions



