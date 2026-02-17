\
\ Minimal SPI Driver for the RA8876 Controller and 7" SPI Display
\ Register constants replaced with hardcoded values
\ to eliminate about a 130 constants taking up dictionary space
\ Written in ESP32forth
\ Ported from RA8876_Lite
\ Written/Ported by: Craig A. Lindley
\ Last Update: 11/03/2024

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
  \ CMDWRITE HSPI.write
  0 HSPI.write
  HSPI.write
  LCD_CS HIGH digitalWrite
;

\ Write data
: writeData ( data -- )
  LCD_CS LOW digitalWrite
  \ DATAWRITE HSPI.write
  $80 HSPI.write
  HSPI.write
  LCD_CS HIGH digitalWrite
;
 
\ Read data
: readData ( -- data )
  LCD_CS LOW digitalWrite
  \ DATAREAD HSPI.write
  $C0 HSPI.write
  0 HSPI.transfer8
  LCD_CS HIGH digitalWrite
;

\ Read status
: readStatus ( -- status )
  LCD_CS LOW digitalWrite
  \ STATUSREAD HSPI.write
  $40 HSPI.write
  0 HSPI.transfer8
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
  \ DATAWRITE HSPI.write
  $80 HSPI.write
  dup
  HSPI.write
  8 >> HSPI.write
  LCD_CS HIGH digitalWrite
;

\ End low level SPI access functions

\ Set foreground color
: setFGColor { color16 }
  color16 to FGColor
  \ FGCR color16 8 >> writeRegData
  $D2 color16 8 >> writeRegData
  \ FGCG color16 3 >> writeRegData
  $D3 color16 3 >> writeRegData
  \ FGCB color16 3 << writeRegData
  $D4 color16 3 << writeRegData
;

\ Set background color
: setBGColor { color16 }
  color16 to BGColor
  \ BGCR color16 8 >> writeRegData
  $D5 color16 8 >> writeRegData
  \ BGCG color16 3 >> writeRegData
  $D6 color16 3 >> writeRegData
  \ BGCB color16 3 << writeRegData
  $D7 color16 3 << writeRegData
;


\ graphics mode control
: graphicsMode ( f -- )
  if
    \ ICR LVDS_FORMAT 3 << or
    3 
    \ MEMORY_SELECT_IMAGE or
  else
    \ ICR LVDS_FORMAT 3 << or
    3 
    \ 1 2 << MEMORY_SELECT_IMAGE or
    1 2 << 
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

\ Check that the write fifo is empty
: checkWriteFifoEmpty
  0 0 { count result }
  begin
    1 ms
    readStatus $40 and $40 = to result

    1 +to count
    result count 10000 > or
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
    \ DPCR XPCLK_INV 7 << DISPLAY_ON  6 << OUTPUT_RGB or or 
    $12 1 7 << 1 6 << or 
  else
    \ DPCR XPCLK_INV 7 << DISPLAY_OFF 6 << OUTPUT_RGB or or 
    $12 1 7 << 
  then
  writeRegData
;

: horizontalWidthVH { width height }

  width 8 / 1- { temp }
  \ HDWR    temp writeRegData
  $14    temp writeRegData
  width 8 mod to temp
  \ HDWFTR  temp writeRegData
  $15  temp writeRegData
  height 1- to   temp
  \ VDHR0   temp writeRegData
  $1A   temp writeRegData
  height 1- 8 >> to temp
  \ VDHR1  temp writeRegData
  $1B  temp writeRegData
;

: horizontalNonDisplay { numbers }
  0 { temp }
  numbers 8 <
  if 
    \ HNDR  $00      writeRegData
    $16  $00      writeRegData
    \ HNDFTR numbers writeRegData
    $17 numbers writeRegData
  else
    numbers 8 / 1- to temp
    \ HNDR temp      writeRegData
    $16 temp      writeRegData
    numbers 8 mod  to temp
    \ HNDFTR temp     writeRegData
    $17 temp     writeRegData
  then
;

: hSyncStart { numbers }
  0 { temp }
  numbers 8 <
  if
    \ HSTR $00 writeRegData
    $18 $00 writeRegData
  else
    numbers 8 / 1- to temp
    \ HSTR temp writeRegData
    $18 temp writeRegData
  then
;

: hSyncPW { numbers }
  0 { temp }
  numbers 8 <
  if
    \ HPWR $00 writeRegData
    $19 $00 writeRegData
  else
    numbers 8 / 1- to temp
    \ HPWR temp writeRegData
    $19 temp writeRegData
  then
;

: verticalNonDisplay { numbers }
  numbers 1- { temp }
  \ VNDR0 temp      writeRegData
  $1C temp      writeRegData
  \ VNDR1 temp 8 >> writeRegData
  $1D temp 8 >> writeRegData
;

: vSyncStart { numbers }
  numbers 1- { temp }
  \ VSTR temp writeRegData
  $1E temp writeRegData
;

: vSyncPW { numbers }
  numbers 1- { temp }
  \ VPWR temp writeRegData
  $1F temp writeRegData
;

: displayImageAddr { addr }
  \ MISA0 addr       writeRegData
  $20 addr       writeRegData
  \ MISA1 addr  8 >> writeRegData 
  $21 addr  8 >> writeRegData 
  \ MISA2 addr 16 >> writeRegData 
  $22 addr 16 >> writeRegData 
  \ MISA3 addr 24 >> writeRegData 
  $23 addr 24 >> writeRegData 
;

: displayImageWidth { width }
  \ MIW0 width      writeRegData
  $24 width      writeRegData
  \ MIW1 width 8 >> writeRegData 
  $25 width 8 >> writeRegData 
;

: displayWindowStartXY { x y }
  \ MWULX0 x      writeRegData
  $26 x      writeRegData
  \ MWULX1 x 8 >> writeRegData
  $27 x 8 >> writeRegData
  \ MWULY0 y      writeRegData
  $28 y      writeRegData
  \ MWULY1 y 8 >> writeRegData
  $29 y 8 >> writeRegData
;

: canvasImageAddr { addr }
  \ CVSSA0 addr       writeRegData
  $50 addr       writeRegData
  \ CVSSA1 addr  8 >> writeRegData
  $51 addr  8 >> writeRegData
  \ CVSSA2 addr 16 >> writeRegData
  $52 addr 16 >> writeRegData
  \ CVSSA3 addr 24 >> writeRegData
  $53 addr 24 >> writeRegData
;

: canvasImageWidth { width }
  \ CVS_IMWTH0 width      writeRegData
  $54 width      writeRegData
  \ CVS_IMWTH1 width 8 >> writeRegData
  $55 width 8 >> writeRegData
;

: activeWindowXY { x y }
  \ AWUL_X0 x      writeRegData
  $56 x      writeRegData
  \ AWUL_X1 x 8 >> writeRegData  
  $57 x 8 >> writeRegData  
  \ AWUL_Y0 y      writeRegData
  $58 y      writeRegData
  \ AWUL_Y1 y 8 >> writeRegData 
  $59 y 8 >> writeRegData 
;

: activeWindowWH { width height }

  \ AW_WTH0 width      writeRegData
  $5A width      writeRegData
  \ AW_WTH1 width 8 >> writeRegData
  $5B width 8 >> writeRegData
  \ AW_HT0 height      writeRegData
  $5C height      writeRegData
  \ AW_HT1 height 8 >> writeRegData
  $5D height 8 >> writeRegData
;

: setPixelCursor { x y }
  \ CURH0 x      writeRegData
  $5F x      writeRegData
  \ CURH1 x 8 >> writeRegData
  $60 x 8 >> writeRegData
  \ CURV0 y      writeRegData
  $61 y      writeRegData
  \ CURV1 y 8 >> writeRegData
  $62 y 8 >> writeRegData
;

\ Initialize the controller
: initialize ( -- f )

  \ Initialize the PLL
  initPLL FALSE =
  if ." PLL initialization failed" false exit then

  \ Initialize SDRAM
  initSDRAM FALSE =
  if ." SDRAM initialization failed" false exit then

  \ CCR writeReg
  1 writeReg
  \ PLL_ENABLE 7 << WAIT_NO_MASK 6 << or
  1 7 <<
  \ KEY_SCAN_DISABLE 5 << TFT_OUTPUT24 3 << or
  0
  \ I2C_MASTER_DISABLE 2 << SERIAL_IF_ENABLE 1 << or
  \ SERIAL_IF_ENABLE 1 <<
  1 1 <<
  \ HOST_DATA_BUS_SERIAL or or or
  0 or or or
  writeData

  \ MACR writeReg
  2 writeReg
  \ DIRECT_WRITE 6 << READ_MEMORY_LRTB 4 << or
  \ READ_MEMORY_LRTB 4 <<
  0
  \ WRITE_MEMORY_LRTB 1 << or
  \ 0 1 << or
  writeData

  \ ICR writeReg
  3 writeReg
  \ LVDS_FORMAT 3 << GRAPHIC_MODE 2 << MEMORY_SELECT_IMAGE or or
  \ MEMORY_SELECT_IMAGE
  0
  writeData

  \ MPWCTR writeReg
  $10 writeReg
  \ PIP1_DISABLE 7 << PIP2_DISABLE 6 << or
  0
  \ SELECT_CONFIG_PIP1 4 << IMAGE_CD_16 2 << or
  1 2 <<
  \ TFT_MODE or or
  or
  writeData

  \ PIPCDEP writeReg
  $11 writeReg
  \ PIP1_CD_16 2 << PIP2_CD_16 or
  1 2 << 1 or
  writeData

  \ AW_COLOR writeReg
  $5E writeReg
  \ CANVAS_BLOCK_MODE 2 << CANVAS_CD_16 or
  1
  writeData

  \ BTE_COLR
  $92
  \ S0_CD_16 5 << S1_CD_16 2 << or
  1 5 << 1 2 << or
  \ S0_CD_16 or
  1 or
  writeRegData

  \ TFT timing configuration
  \ DPCR writeReg
  $12 writeReg
  \ XPCLK_INV 7 << DISPLAY_OFF 6 << OUTPUT_RGB or or
  1 7 <<
  writeData
    
  \ PCSR writeReg
  $13 writeReg
  \ XHSYNC_INV 7 << XVSYNC_INV 6 << XDE_INV 5 << or or
  1 7 << 1 6 << or
  writeData

  \ HDW VDH horizontalWidthVH
  1024 600 horizontalWidthVH
  \ HND horizontalNonDisplay
  160 horizontalNonDisplay
  \ HST hSyncStart
  160 hSyncStart
  \ HPW hSyncPW
  70 hSyncPW
  \ VND verticalNonDisplay
  23 verticalNonDisplay
  \ VST vSyncStart
  12 vSyncStart
  \ VPW vSyncPW
  10 vSyncPW
  
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

defer textColorSetter
defer textSizeSetter

\ Initialize GPIO and reset controller
: RA8876.begin ( -- f )

  \ Configure HSPI interface for talking to display
  LCD_SCK LCD_MISO LCD_MOSI LCD_CS HSPI.begin
  SPI_FREQ HSPI.setFrequency

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
  if 
    ." RA8876 not ready!" cr
    false
    exit
  then

  \ Read ID code must disable pll, 01h bit7 set 0
  $01 $08 writeRegData
  1 ms

  $FF readRegData $76 <>
  $FF readRegData $77 <> and
  if 
    ." RA8876 or RA8877 not found!" cr
    false
    exit
  then

  \ Do controller initialization
  initialize FALSE =
  if
    ." RA8876 or RA8877 initialization failed" cr
    false exit
  then

  \ Set default text colors
  WHITE BLACK textColorSetter

  \ Set default text size
  0 textSizeSetter

  \ Turn the display on
  true displayOn
  true
;

\ Draw a pixel
: drawPixel { x y color16 }
  x y setPixelCursor
  \ MRWDP writeReg
  4 writeReg
  color16 writeData16
;

\ Temp storage for foreground color
0 value _fgc

\ Draw a rectangle
: drawRect { x0 y0 x1 y1 color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DLHSR0 x0      writeRegData
  $68 x0      writeRegData
  \ DLHSR1 x0 8 >> writeRegData
  $69 x0 8 >> writeRegData
  \ DLVSR0 y0      writeRegData
  $6A y0      writeRegData
  \ DLVSR1 y0 8 >> writeRegData
  $6B y0 8 >> writeRegData
  \ DLHER0 x1      writeRegData
  $6C x1      writeRegData
  \ DLHER1 x1 8 >> writeRegData
  $6D x1 8 >> writeRegData
  \ DLVER0 y1      writeRegData
  $6E y1      writeRegData
  \ DLVER1 y1 8 >> writeRegData        
  $6F y1 8 >> writeRegData        
  \ DCR1 RECT writeRegData
  $76 $A0 writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a filled rectangle
: drawFilledRect { x0 y0 x1 y1 color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DLHSR0 x0      writeRegData
  $68 x0      writeRegData
  \ DLHSR1 x0 8 >> writeRegData
  $69 x0 8 >> writeRegData
  \ DLVSR0 y0      writeRegData
  $6A y0      writeRegData
  \ DLVSR1 y0 8 >> writeRegData
  $6B y0 8 >> writeRegData
  \ DLHER0 x1      writeRegData
  $6C x1      writeRegData
  \ DLHER1 x1 8 >> writeRegData
  $6D x1 8 >> writeRegData
  \ DLVER0 y1      writeRegData
  $6E y1      writeRegData
  \ DLVER1 y1 8 >> writeRegData        
  $6F y1 8 >> writeRegData        
  \ DCR1 RECT_FILL writeRegData
  $76 $E0 writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw rounded rectangle
: drawRoundedRect { x0 y0 x1 y1 radius color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DLHSR0 x0      writeRegData
  $68 x0      writeRegData
  \ DLHSR1 x0 8 >> writeRegData
  $69 x0 8 >> writeRegData
  \ DLVSR0 y0      writeRegData
  $6A y0      writeRegData
  \ DLVSR1 y0 8 >> writeRegData
  $6B y0 8 >> writeRegData
  \ DLHER0 x1      writeRegData
  $6C x1      writeRegData
  \ DLHER1 x1 8 >> writeRegData
  $6D x1 8 >> writeRegData
  \ DLVER0 y1      writeRegData
  $6E y1      writeRegData
  \ DLVER1 y1 8 >> writeRegData    
  $6F y1 8 >> writeRegData    
  \ ELL_A0 radius      writeRegData    
  $77 radius      writeRegData    
  \ ELL_A1 radius 8 >> writeRegData 
  $78 radius 8 >> writeRegData 
  \ ELL_B0 radius      writeRegData    
  $79 radius      writeRegData    
  \ ELL_B1 radius 8 >> writeRegData
  $7A radius 8 >> writeRegData
  \ DCR1 ROUNDRECT writeRegData
  $76 $B0 writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw filled rounded rectangle
: drawFilledRoundedRect { x0 y0 x1 y1 radius color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DLHSR0 x0      writeRegData
  $68 x0      writeRegData
  \ DLHSR1 x0 8 >> writeRegData
  $69 x0 8 >> writeRegData
  \ DLVSR0 y0      writeRegData
  $6A y0      writeRegData
  \ DLVSR1 y0 8 >> writeRegData
  $6B y0 8 >> writeRegData
  \ DLHER0 x1      writeRegData
  $6C x1      writeRegData
  \ DLHER1 x1 8 >> writeRegData
  $6D x1 8 >> writeRegData
  \ DLVER0 y1      writeRegData
  $6E y1      writeRegData
  \ DLVER1 y1 8 >> writeRegData    
  $6F y1 8 >> writeRegData    
  \ ELL_A0 radius      writeRegData    
  $77 radius      writeRegData    
  \ ELL_A1 radius 8 >> writeRegData 
  $78 radius 8 >> writeRegData 
  \ ELL_B0 radius      writeRegData    
  $79 radius      writeRegData    
  \ ELL_B1 radius 8 >> writeRegData
  $7A radius 8 >> writeRegData
  \ DCR1 ROUNDRECT_FILL writeRegData
  $76 $F0 writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a circle
: drawCircle { x y radius color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DEHR0 x       writeRegData
  $7B x       writeRegData
  \ DEHR1 x 8 >>  writeRegData
  $7C x 8 >>  writeRegData
  \ DEVR0 y       writeRegData
  $7D y       writeRegData
  \ DEVR1 y 8 >>  writeRegData
  $7E y 8 >>  writeRegData
  \ ELL_A0 radius writeRegData    
  $77 radius writeRegData    
  \ ELL_A1 radius 8 >> writeRegData 
  $78 radius 8 >> writeRegData 
  \ ELL_B0 radius      writeRegData    
  $79 radius      writeRegData    
  \ ELL_B1 radius 8 >> writeRegData
  $7A radius 8 >> writeRegData
  \ DCR1 CIRCLE writeRegData
  $76 $80 writeRegData
  checkBusy
  _fgc setFGColor
;

\ Draw a filled circle
: drawFilledCircle { x y radius color16 }
  FGColor to _fgc
  color16 setFGColor
  \ DEHR0 x       writeRegData
  $7B x       writeRegData
  \ DEHR1 x 8 >>  writeRegData
  $7C x 8 >>  writeRegData
  \ DEVR0 y       writeRegData
  $7D y       writeRegData
  \ DEVR1 y 8 >>  writeRegData
  $7E y 8 >>  writeRegData
  \ ELL_A0 radius writeRegData    
  $77 radius writeRegData    
  \ ELL_A1 radius 8 >> writeRegData 
  $78 radius 8 >> writeRegData 
  \ ELL_B0 radius      writeRegData    
  $79 radius      writeRegData    
  \ ELL_B1 radius 8 >> writeRegData
  $7A radius 8 >> writeRegData
  \ DCR1 CIRCLE_FILL writeRegData
  $76 $C0 writeRegData
  checkBusy
  _fgc setFGColor
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

\ Text functions follow

\ Set text color
: setTextColor ( fgColor bgColor -- )
  setBGColor
  setFGColor
;

\ Set text cursor position
: setTextCursor { x y }
  \ F_CURX0 x      writeRegData
  $63 x      writeRegData
  \ F_CURX1 x 8 >> writeRegData
  $64 x 8 >> writeRegData
  \ F_CURY0 y      writeRegData
  $65 y      writeRegData
  \ F_CURY1 y 8 >> writeRegData
  $66 y 8 >> writeRegData
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
  endcase  \ CCR0 size 4 << writeRegData
  $CC size 4 << writeRegData
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
  \ CCR1 align 7 << chroma 6 << widthEnlarge 2 << heightEnlarge
  $CD align 7 << chroma 6 << widthEnlarge 2 << heightEnlarge
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
  \ MRWDP writeReg
  4 writeReg
  addr n + addr
  do
    checkWriteFifoNotFull
    i c@ writeData
  loop
  checkBusy
  true graphicsMode
;

\ Justify text left, center or right
0 constant JL
1 constant JC
2 constant JR

\ Write a justified s" string to the display at y position
: justifyTextString { mode y addr n }
  addr n stringWidth { sw }
  mode
  case
    JL of                    0 endof
    JC of SCREEN_WIDTH sw - 2/ endof
    JR of SCREEN_WIDTH sw -    endof
  endcase
  y addr n drawTextString
;

\ Resolve forward references
' setTextColor is textColorSetter
' setTextSize  is textSizeSetter

only forth definitions



