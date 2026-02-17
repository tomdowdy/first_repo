\ Text Functions for ESP32forth
\ Display driver and font has to be loaded previously
\ Written By: Craig A. Lindley
\ Last Update: 08/12/2021

\ Foreground and background color storage
$FFFF value FGColor 
$0000 value BGColor 

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

0 value textSize 
0 value charSpaceWidth
0 value charSpaceHeight

\ Set the size of the text
: setTextSize	( size -- )
  to textSize

  \ Calculate char dimensions
  FW 1+ textSize * to charSpaceWidth
  FH 1+ textSize * to charSpaceHeight
;

: getTextSize
  textSize
;

\ Set text size and calculate char spacing
1 setTextSize

0 value __cp
0 value __x
0 value __y

\ Print a character from the font with scaling at specified position
\ Origin of char is at the top left corner x, y
\ Only the foreground color is printed.
: pChar ( x y ch -- )

  \ Calculate offset of char data in font
  $20 - FW * FONT + to __cp
  to __y 
  to __x

  FW 0
  do
    __cp c@ 
    1 +to __cp
    FH 1+ 0
    do
      dup                  ( ch -- ch ch )
      1 i << and        ( ch ch -- ch f )
      if 
        textSize 1 =
        if
          j __x + __y i + FGColor pixel
        else
          j textSize * __x + i textSize * __y + textSize dup FGColor fillRect2
        then
      else
        textSize 1 =
        if
          j __x + __y i + BGColor pixel
        else
          j textSize * __x + i textSize * __y + textSize dup BGColor fillRect2
        then
      then
    loop
    drop
  loop
  textSize 1 =
  if
    __x 5 + __y 8 BGColor vLine
  else
    textSize 5 * __x + __y textSize dup 8 * BGColor fillRect2
  then
;

\ Print string onto display at specified position 
\ with current text size and foreground color
: pString ( x y addr cnt -- )
  over + swap
  do
    2dup i c@ pChar

    \ Advance x by font char width
    swap charSpaceWidth + swap
  loop
  2drop
;

\ Print a horizontally centered text string
: pCenteredString { y addr cnt }
  \ Calculate length of string in pixels
  charSpaceWidth cnt * 
  getLCDWidth swap - 2 /
  y addr cnt pString
;

\ Get string width
: getStringWidth   ( addr cnt -- width )
  swap drop   ( addr cnt -- count )
  charSpaceWidth * 
;

\ Get string height
: getStringHeight ( -- height ) 
  charSpaceHeight
;

\ Clear out the area the string will be drawn into
: clearStringArea ( x y addr cnt -- )
  getStringWidth charSpaceHeight BGColor fillRect2
;




