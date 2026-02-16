\ Text Functions for 8x8 NeoPixel Panel using 5x7 Font
\ Written in ESP32Forth
\ Display driver and font has to be loaded previously
\ Written By: Craig A. Lindley
\ Last Update: 09/20/2022

\ Foreground and background color storage
0 value FGColor 
0 value BGColor 

\ Set the text's foreground color
: setFGColor	( color -- )
  to FGColor
;

: getFGColor
  FGColor
;

\ Set the text's background color
: setBGColor	( color -- )
  to BGColor
;

: getBGColor
  BGColor
;

\ Calculate address offset of char data in font
: calcCharOffset ( ch -- addr )
  $20 - FW * FONT +
;

\ Print a character from the font at specified position
\ Origin of char is at the top left corner col, row
\ Foreground and background colors are printed.
: pChar { col row ch } ( col row ch -- )
  \ Calculate offset of char data in font
  ch calcCharOffset { cp }

  FW 0
  do
    cp c@ 
    1 +to cp
    FH 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
          j col + row i + FGColor setPixelColRow
      else
          j col + row i + BGColor setPixelColRow
      then
    loop
    drop
  loop
;

\ Print string onto display at specified position 
\ with current text size and foreground color
: pString ( col row addr cnt -- )
  over + swap
  do
    2dup i c@ pChar

    \ Advance x position by font char width
    swap FW 1+ + swap
  loop
  2drop
  show
;

\ Print a horizontally centered text string
: pCenteredString { row addr cnt }
  \ Calculate length of string in pixels
  FW 1+ cnt * 
  COL_NUM swap - 2 /
  row addr cnt pString
;

\ Get string width
: getStringWidth   ( addr cnt -- width )
  swap drop   ( addr cnt -- count )
  FW 1+ * 
;

\ Get string height
: getStringHeight ( -- height ) 
  FH
;

\ ******************** Text Scrolling Functions ********************

\ Maximum length of text string to scroll
100 constant MAX_STR_LEN

\ Buffer size for storing font data
FW 1+ MAX_STR_LEN * constant META_BUF_SIZE

\ Create a buffer for storing font data from ASCII text
META_BUF_SIZE byteArray metaBuffer

\ Index into the meta buffer
0 value metaIndex

\ Process string into the meta buffer
: processStr { addr n } ( addr n -- )
  \ Check string len
  n MAX_STR_LEN <
  if
    \ String length OK  
    0 to metaIndex
    0 metaBuffer META_BUF_SIZE erase

    n 0
    do
      addr c@ calcCharOffset ( -- addr )
      FW 0
      do
        dup             ( addr -- addr addr )
        c@ metaIndex metaBuffer c!
        1 +to metaIndex
        1+
      loop
      drop
      1 +to metaIndex
      1 +to addr
    loop
  else
    ." String to long" cr
  then
;

\ Possible text/character color modes
0 constant COLOR_MODE_STR     \ Text takes on solid FGColor
1 constant COLOR_MODE_CHAR    \ Each char of string has dynamically assigned color
2 constant COLOR_MODE_STRIPED \ Each stripe of char has dynamically assigned color
3 constant COLOR_MODE_PIXEL   \ Each pixel of each char has dynamically assigned color

\ Scroll a string across the display from right to left with constant FGColor
: scrollStrStr { delayMS } ( delayMS -- )
  metaIndex 0
  do
    i metaBuffer C@
    FH 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
          COL_MAX i FGColor setPixelColRow
      then
    loop
    drop

    show
    delayMS delay
    shiftMatrixLeft
  loop
;

\ Scroll a string across the display from right to left with each char
\ getting a different dynamic color
: scrollStrChar { delayMS } ( delayMS -- )
  0 FW 1+ { color24 ci }

  metaIndex 0
  do
    ci FW >=
    if 
      \ Pick a color for the next char
      dynamicColorSelector to color24
      0 to ci
    else
      1 +to ci
    then

    i metaBuffer C@
    FH 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
          COL_MAX i color24 setPixelColRow
      then
    loop
    drop

    show
    delayMS delay
    shiftMatrixLeft
  loop
;

\ Scroll a string across the display from right to left with striped characters
\ with dynamic color
: scrollStrStriped { delayMS } ( delayMS -- )
  0 { color24 }

  metaIndex 0
  do
    \ Pick a color for the char stripe
    dynamicColorSelector to color24

    i metaBuffer C@
    FH 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
          COL_MAX i color24 setPixelColRow
      then
    loop
    drop

    show
    delayMS delay
    shiftMatrixLeft
  loop
;

\ Scroll a string across the display from right to left with 
\ dynamic color for each pixel
: scrollStrPixel { delayMS } ( delayMS -- )
  metaIndex 0
  do
    i metaBuffer C@
    FH 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
          COL_MAX i dynamicColorSelector setPixelColRow
      then
    loop
    drop

    show
    delayMS delay
    shiftMatrixLeft
  loop
;

\ Scroll a string with selected delay and color mode
: scrollStr { addr n delayMS colorMode } ( addr n delayMS colorMode -- )
  \ All pixels off
  false clearPixels

  \ Preprocess the string
  addr n processStr

  colorMode
  case
    COLOR_MODE_STR     of delayMS scrollStrStr     endof
    COLOR_MODE_CHAR    of delayMS scrollStrChar    endof
    COLOR_MODE_STRIPED of delayMS scrollStrStriped endof
    COLOR_MODE_PIXEL   of delayMS scrollStrPixel   endof
  endcase

  \ Scroll the message string completely off of the display before returning

  COL_NUM 0
  do
    ROW_NUM 0
    do
      COL_MAX i 0 setPixelColRow
    loop
    show
    delayMS delay
    shiftMatrixLeft
  loop
;

































