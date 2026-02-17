\
\ ESP32Forth Desk Gadget -  Fun Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/16/2022
\

    3 constant NUM_PATTERNS

   40 constant LABEL_WIDTH
   30 constant LABEL_HEIGHT
GREEN constant LABEL_COLOR
BLACK constant LABEL_TEXT_COLOR

\ Define the labels on this page
105 70 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0" 2 LABEL_TEXT_COLOR buttonCreate MIN10_LABEL
175 70 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 1" 2 LABEL_TEXT_COLOR buttonCreate MIN_LABEL

\ Define the buttons on this page
105 110 LABEL_WIDTH 30 B_D_COLOR s" +" 2 BLACK buttonCreate MIN10_BUTTON
175 110 LABEL_WIDTH 30 B_D_COLOR s" +" 2 BLACK buttonCreate MIN_BUTTON

\ Action buttons
123 150 70 30 B_D_COLOR s" Start" 2 BLACK buttonCreate START_BUTTON
123 190 70 30 B_D_COLOR s" Back"  2 BLACK buttonCreate BACK_BUTTON

\ Display the static page content
: displayFunPage

  BLUE fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  WHITE setFGColor
  BLUE  setBGColor

  \ Output text
   8 s" Fun Page" pCenteredString
  28 s" Pattern Duration" pCenteredString
  48 s" Minutes" pCenteredString

  \ Draw buttons and labels
   MIN10_LABEL buttonDraw
     MIN_LABEL buttonDraw
  MIN10_BUTTON buttonDraw
    MIN_BUTTON buttonDraw
  START_BUTTON buttonDraw
   BACK_BUTTON buttonDraw
;

0 value _min10Count
0 value _minCount

false value _done
false value __done

: doFun ( -- )

  displayFunPage

  0 to _min10Count
  1 to _minCount

  _min10Count MIN10_LABEL setButtonNumber
  _minCount   MIN_LABEL   setButtonNumber

  false to _done
  false to __done

  begin

    \ Check buttons for touch
    getTouchPoint
    if
      xTouch yTouch MIN10_BUTTON buttonPoll
      if
        1 +to _min10Count
        _min10Count 5 >
        if
          0 to _min10Count
        then
        _min10Count MIN10_LABEL setButtonNumber
      then

      xTouch yTouch MIN_BUTTON buttonPoll
      if
        1 +to _minCount
        _minCount 9 >
        if
          0 to _minCount
        then
        _minCount MIN_LABEL setButtonNumber
      then

      xTouch yTouch START_BUTTON buttonPoll
      if
        false to __done
        begin        
          \ Calculate when pattern display will end
          _min10Count 10 * _minCount + 60000 * MS-TICKS + to futureTimeMS

          NUM_PATTERNS random0toN
          case
            0 of doWebs       endof
            1 of doPlasma     endof
            2 of doSierpinski endof
          endcase

          \ Returned value determines what to do
          RETURN_TOUCH =
          if
            \ Redisplay FunPage
            displayFunPage
            _min10Count MIN10_LABEL setButtonNumber
            _minCount   MIN_LABEL   setButtonNumber
            true to __done
          then
          __done
        until
      then

      xTouch yTouch BACK_BUTTON buttonPoll
      if
        true to _done
      then
    then
    _done
  until
;
    
 