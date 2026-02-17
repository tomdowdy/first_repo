\ Text Functions for ESP32forth
\ Display driver and font has to be loaded previously
\ Written By: Craig A. Lindley
\ Last Update: 03/11/2023

\ Foreground and background color storage
EPD_BLACK value FGColor 
EPD_WHITE value BGColor 

1 value textSize 
0 value charSpaceWidth
0 value charSpaceHeight

\ Set the size of the text
: setTextSize	( size -- )
  to textSize

  \ Calculate char dimensions
  FW 1+ textSize * to charSpaceWidth
  FH 1+ textSize * to charSpaceHeight
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
          j textSize * __x + i textSize * __y + textSize dup FGColor fillRectangle
        then
      else
        textSize 1 =
        if
          j __x + __y i + BGColor pixel
        else
          j textSize * __x + i textSize * __y + textSize dup BGColor fillRectangle
        then
      then
    loop
    drop
  loop
  textSize 1 =
  if
    __x 5 + __y 8 BGColor vLine
  else
    textSize 5 * __x + __y textSize dup 8 * BGColor fillRectangle
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

