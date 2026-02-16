\ Button / Label Class
\ Buttons/Labels are drawn as rounded rects
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/17/2022

\ Button default attributes
       5 constant B_D_H_SPACE
      73 constant B_D_WIDTH
      25 constant B_D_HEIGHT
       4 constant B_D_RADIUS

       2 constant B_D_TEXT_SIZE
DARKGREY constant B_D_COLOR
   BLACK constant B_D_TEXT_COLOR


\ Button defining word
\ label is an s" string
\ Create dictionary entry and store all button parameters there
: buttonCreate ( x y w h buttonColor label textsize textcolor -- )

  create , , , , , , , , , does>
;

\ Dump the button's data
: buttonDump { bAddr }
  cr
  \ Extract button parameters
  bAddr 32 + @ ." x: " . cr
  bAddr 28 + @ ." y: " . cr
  bAddr 24 + @ ." w: " . cr
  bAddr 20 + @ ." h: " . cr
  bAddr 16 + @ ." bc: " . cr
  bAddr 12 + @ bAddr  8 + @ ." label: " type cr
  bAddr  4 + @ ." ts: " . cr
  bAddr      @ ." tc: " . cr
;

\ Draw a button
: buttonDraw { bAddr }
  0 0 0 0 0 0 0 0 0 { x y w h bc la ln ts tc }   
  
  \ Extract button parameters
  bAddr 32 + @ to x
  bAddr 28 + @ to y
  bAddr 24 + @ to w
  bAddr 20 + @ to h
  bAddr 16 + @ to bc
  bAddr 12 + @ to la
  bAddr  8 + @ to ln
  bAddr  4 + @ to ts
  bAddr      @ to tc

  \ Draw the rounded rect
  x y w h B_D_RADIUS bc fillRoundedRect

  \ Save current text parameters
  0 0 0 0 0 { _ts _tfc _tbc _tsw _tsh }

  getTextSize to _ts
  getFGColor  to _tfc
  getBGColor  to _tbc

  ts setTextSize

  \ Get string dimensions
  la ln getStringWidth  to _tsw
        getStringHeight to _tsh

  tc setFGColor
  bc setBGColor

  \ Draw button label
  x w 2 / + _tsw 2 / - 2 +
  y h 2 / + _tsh 2 / - 2 +
  la ln pString

  \ Restore text parameters
  _ts setTextSize
  _tfc setFGColor
  _tbc setBGColor
;

\ Set button/label color
: setButtonColor { color bAddr } ( color bAddr -- )
  
  color bAddr 16 + !

  \ Draw/ReDraw the button
  bAddr buttonDraw
;

\ Set text of button/label
: setButtonText { a n bAddr } ( a n bAddr -- )
  
  a bAddr 12 + !
  n bAddr  8 + !

  \ Draw/ReDraw the button
  bAddr buttonDraw
;

\ Set button/label text to a number
: setButtonNumber { n bAddr } ( n bAddr -- )
  n str bAddr setButtonText
;

\ Set button/label text size
: setButtonTextSize { ts bAddr } ( ts bAddr -- )

  ts bAddr 4 + !

  \ Draw/ReDraw the button
  bAddr buttonDraw
;

\ Poll button
\ _x and _y are the coordinates of the screen touch
\ Returns true if button was pressed
: buttonPoll { _x _y bAddr } ( _x _y bAddr -- f )
  false 0 0 0 0 { r x y w h }   

  \ Extract button parameters
  bAddr 32 + @ to x
  bAddr 28 + @ to y
  bAddr 24 + @ to w
  bAddr 20 + @ to h

  \ Check if touch point is within the button
  _x x >= _x x w + <= and 
  _y y >= _y y h + <= and and
  if
    true to r
  then
  r
;


 
