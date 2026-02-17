\
\ ESP32Forth Driver for LCD 1602A 16x2 Line Character LCD Display
\ Code assumes RW pin grounded
\ Code runs in 4 bit mode
\
\ Ported from Arduino LiquidCrystal library by: Craig A. Lindley
\ Last Update: 04/24/2023
\

\ Display connections to ESP32 D1 Mini
16 constant LCD_RS
17 constant LCD_E
18 constant LCD_D4
19 constant LCD_D5
21 constant LCD_D6
22 constant LCD_D7
23 constant LCD_BL

\ Command values
$01 constant CLEARDISPLAY
$02 constant RETURNHOME
$04 constant ENTRYMODESET
$08 constant DISPLAYCONTROL
$10 constant CURSORSHIFT
$20 constant FUNCTIONSET
$40 constant SETCGRAMADDR
$80 constant SETDDRAMADDR

\ Flags for display entry mode
$00 constant ENTRYRIGHT
$02 constant ENTRYLEFT
$01 constant ENTRYSHIFTINCREMENT
$00 constant ENTRYSHIFTDECREMENT

\ Flags for display on/off control
$04 constant DISPLAYON
$00 constant DISPLAYOFF
$02 constant CURSORON
$00 constant CURSOROFF
$01 constant BLINKON
$00 constant BLINKOFF

\ Flags for display/cursor shift
$08 constant DISPLAYMOVE
$00 constant CURSORMOVE
$04 constant MOVERIGHT
$00 constant MOVELEFT

\ Flags for function set
$10 constant 8BITMODE
$00 constant 4BITMODE
$08 constant 2LINE
$00 constant 1LINE
$04 constant 5x10DOTS
$00 constant 5x8DOTS

$00 constant ROW0_OFFSET
$40 constant ROW1_OFFSET

\ Driver variables
0 value _displayFunction
0 value _displayControl
0 value _displayMode

\ Write 4 bits of data to display
: write4Bits { n -- }
  LCD_D4 n      $01 and digitalWrite
  LCD_D5 n 1 >> $01 and digitalWrite
  LCD_D6 n 2 >> $01 and digitalWrite
  LCD_D7 n 3 >> $01 and digitalWrite

  \ Pulse the enable line
  LCD_E LOW digitalWrite
  1 delayMicroseconds
  LCD_E HIGH digitalWrite
  1 delayMicroseconds
  LCD_E LOW digitalWrite
  100 delayMicroseconds
;  

\ Send command or data to display
: send ( value mode -- )
  LCD_RS swap digitalWrite
  dup 4 >> write4Bits
           write4Bits
;

\ Write command to display
: writeCmd ( value -- )
  LOW send
;

\ Write data to display
: writeData ( value -- )
  HIGH send
;

\ Initialize driver into 4 bit mode
: begin { lines dotSize -- }
  
  \ Initialize GPIO
  LCD_RS OUTPUT pinMode
  LCD_E  OUTPUT pinMode
  LCD_D4 OUTPUT pinMode
  LCD_D5 OUTPUT pinMode
  LCD_D6 OUTPUT pinMode
  LCD_D7 OUTPUT pinMode
  LCD_BL OUTPUT pinMode

  0 to _displayFunction

  lines 2 =
  if
    _displayFunction 2LINE or to _displayFunction
  then

  dotSize 5x8DOTS <>
  lines 1 = and
  if
    _displayFunction 5x10DOTS or to _displayFunction
  then

  \ Do initializstion of display
  \ See page 45/46 of Hitachi 44780 spec
  50000 delayMicroseconds
  LCD_RS LOW digitalWrite
  LCD_E  LOW digitalWrite

  \ We started in 8 bit mode so try to set 4 bit mode
  $03 write4Bits
  4500 delayMicroseconds

  \ Second try
  $03 write4Bits
  4500 delayMicroseconds

  \ Third try
  $03 write4Bits
  150 delayMicroseconds

  \ Set to 4 bit mode
  $02 write4Bits

  \ Set display functions: # of lines, font size. etc
  FUNCTIONSET _displayFunction or writeCmd

  \ Turn display on with no cursor or blinking
  DISPLAYON CURSOROFF BLINKOFF or or to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd

  \ Clear display
  CLEARDISPLAY writeCmd
  2000 delayMicroseconds

  \ Initialize to default text direction for romance languages
  ENTRYLEFT ENTRYSHIFTDECREMENT or to _displayMode
  ENTRYMODESET _displayMode or writeCmd

  \ Backlight on
  LCD_BL HIGH digitalWrite
;

\ High Level Commands

\ Backlight control
: backlight ( f -- )
  if
    LCD_BL HIGH digitalWrite
  else
    LCD_BL LOW  digitalWrite
  then
;

\ Clear display
: clearDisplay ( -- )
  CLEARDISPLAY writeCmd
  2000 delayMicroseconds
;

\ Home display
: homeDisplay ( -- )
  RETURNHOME writeCmd
  2000 delayMicroseconds
;

\ Set cursor position on display
\ col: 0..15, row: 0..1
: setCursor ( col row -- )
  ROW0_OFFSET { ROWOFFSET }
  1 =
  if
    ROW1_OFFSET to ROWOFFSET
  then  

  ROWOFFSET + SETDDRAMADDR or writeCmd
;

\ Turn display off
: noDisplay ( -- )
  _displayControl DISPLAYON invert and to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Turn display on
: display ( -- )
  _displayControl DISPLAYON or to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Turn cursor off
: noCursor ( -- )
  _displayControl CURSORON invert and to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Turn cursor on
: cursor ( -- )
  _displayControl CURSORON or to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Turn blinking off
: noBlink ( -- )
  _displayControl BLINKON invert and to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Turn blink on
: blink ( -- )
  _displayControl BLINKON or to _displayControl
  DISPLAYCONTROL _displayControl or writeCmd
;

\ Scroll display left
: scrollDisplayLeft ( -- )
  CURSORSHIFT DISPLAYMOVE MOVELEFT or or writeCmd
;

\ Scroll display right
: scrollDisplayRight ( -- )
  CURSORSHIFT DISPLAYMOVE MOVERIGHT or or writeCmd
;

\ Text flow left to right
: textLeftToRight ( -- )
  _displayMode ENTRYLEFT or to _displayMode
  ENTRYMODESET _displayMode or writeCmd
;

\ Text flow right to left
: textRightToLeft ( -- )
  _displayMode ENTRYLEFT invert and to _displayMode
  ENTRYMODESET _displayMode or writeCmd
;

\ This will right justify text from the cursor
: autoScroll ( -- ) 
  _displayMode ENTRYSHIFTINCREMENT or to _displayMode
  ENTRYMODESET _displayMode or writeCmd
;

\ This will left justify text from the cursor
: noAutoScroll ( -- ) 
  _displayMode ENTRYSHIFTINCREMENT invert and to _displayMode
  ENTRYMODESET _displayMode or writeCmd
;

\ Print string onto display at specified position 
: pString ( col row addr n -- )
  >r >r
  setCursor
  r> r>
  over + swap
  do
    i c@ writeData
  loop
;

\ Print a string centered on the display on row
: pCenteredString { row addr n -- }
  16 n - 2 / row addr n pString 
;



