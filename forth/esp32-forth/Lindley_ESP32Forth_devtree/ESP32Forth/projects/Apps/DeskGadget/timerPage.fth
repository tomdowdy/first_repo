\
\ Desk Gadget App - Timer Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/04/2022
\

 BLUE constant PG_COLOR

  500 constant ALARM_DELAY
   40 constant LABEL_WIDTH
   30 constant LABEL_HEIGHT
GREEN constant LABEL_COLOR
BLACK constant LABEL_TEXT_COLOR

\ Define the labels on this page
 65 30 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0" 2 LABEL_TEXT_COLOR buttonCreate HR_LABEL
115 30 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" :" 3 LABEL_TEXT_COLOR buttonCreate COLON_LABEL
165 30 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0" 2 LABEL_TEXT_COLOR buttonCreate MIN10_LABEL
215 30 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0" 2 LABEL_TEXT_COLOR buttonCreate MIN_LABEL

\ Define the buttons on this page
 65 70 LABEL_WIDTH 30 B_D_COLOR s" +" 2 BLACK buttonCreate HR_BUTTON
165 70 LABEL_WIDTH 30 B_D_COLOR s" +" 2 BLACK buttonCreate MIN10_BUTTON
215 70 LABEL_WIDTH 30 B_D_COLOR s" +" 2 BLACK buttonCreate MIN_BUTTON

\ Alarm status label
 65 110 190 30 LABEL_COLOR s" Alarm Off" 2 BLACK buttonCreate STATUS_LABEL

\ Action buttons
 65 150 70 30 B_D_COLOR s" Start" 2 BLACK buttonCreate START_BUTTON
183 150 70 30 B_D_COLOR s" Stop"  2 BLACK buttonCreate STOP_BUTTON
123 192 70 30 B_D_COLOR s" Back"  2 BLACK buttonCreate BACK_BUTTON

\ Display the static page content
: displayTimerPage

  PG_COLOR fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  WHITE setFGColor
  BLUE  setBGColor

  \ Output text
  8 s" Timer Page" pCenteredString

  \ Draw buttons and labels
      HR_LABEL buttonDraw
   COLON_LABEL buttonDraw
   MIN10_LABEL buttonDraw
     MIN_LABEL buttonDraw
     HR_BUTTON buttonDraw
  MIN10_BUTTON buttonDraw
    MIN_BUTTON buttonDraw
  STATUS_LABEL buttonDraw
  START_BUTTON buttonDraw
   STOP_BUTTON buttonDraw
   BACK_BUTTON buttonDraw
;

\ Update timer status
: updateTimerStatus ( f -- )
  if
    s" Timing" STATUS_LABEL setButtonText
  else
    s" Timer Off" STATUS_LABEL setButtonText
  then
;

0 value _prevMinute
0 value _min
0 value _hrCount
0 value _min10Count
0 value _minCount
0 value _timerMinutes

false value _alarmSounding
false value _alarmToggle
    0 value _alarmDelay
false value _timerEnabled
false value _done

\ Update the timer labels according to _timerMinutes
: updateTimerLabels ( -- )

  0 0 0 { hr min10 min }
  _timerMinutes 60 / to hr
  _timerMinutes hr 60 * - 10 / to min10
  _timerMinutes hr 60 * - min10 10 * - to min

  cr
  ." hr: " hr . cr
  ." min10: " min10 . cr
  ." min: " min . cr

  \ Update the labels
     hr HR_LABEL    setButtonNumber
  min10 MIN10_LABEL setButtonNumber
    min MIN_LABEL   setButtonNumber
;

\ Set the timer minutes count
: setTimerMinutes ( -- )
  _hrCount 60 *
  _min10Count 10 *
  _minCount 
  + + to _timerMinutes
;

\ Display page and do timer function until back button is pressed
: doTimer 

  \ Set timer counts
  0 to _hrCount
  0 to _min10Count
  0 to _minCount
  0 to _timerMinutes

  \ Set the timer labels to zeros
  0 HR_LABEL    setButtonNumber
  0 MIN10_LABEL setButtonNumber
  0 MIN_LABEL   setButtonNumber

  false to _alarmSounding
  false to _alarmToggle
  false to _timerEnabled
  false to _done

  toneDefaultSetup
  displayTimerPage

  begin
    now minute_t to _min

    \ Has the minute changed ?
    _min _prevMinute <>
    if
      _min to _prevMinute

      _timerEnabled
      if
        -1 +to _timerMinutes
        updateTimerLabels
        _timerMinutes 0=
        if
          true  to _alarmSounding
          false to _timerEnabled
          false updateTimerStatus
        then
      then
    then

    \ Check buttons for touch
    getTouchPoint
    if
      xTouch yTouch HR_BUTTON buttonPoll
      if
        _timerEnabled false =
        if 
          1 +to _hrCount
          _hrCount 9 >
          if
            0 to _hrCount
          then
          _hrCount HR_LABEL setButtonNumber
        then
      then

      xTouch yTouch MIN10_BUTTON buttonPoll
      if
        _timerEnabled false =
        if 
          1 +to _min10Count
          _min10Count 5 >
          if
            0 to _min10Count
          then
          _min10Count MIN10_LABEL setButtonNumber
        then
      then

      xTouch yTouch MIN_BUTTON buttonPoll
      if
        _timerEnabled false =
        if 
          1 +to _minCount
          _minCount 9 >
          if
            0 to _minCount
          then
          _minCount MIN_LABEL setButtonNumber
        then
      then

      xTouch yTouch START_BUTTON buttonPoll
      if
        _timerEnabled false =
        _hrCount _min10Count _minCount or or
        and
        if 
          setTimerMinutes
          true to _timerEnabled
          true updateTimerStatus
        then
      then

      xTouch yTouch STOP_BUTTON buttonPoll
      if
        toneOff
        false to _timerEnabled
        false to _alarmSounding
        false updateTimerStatus

        0 to _hrCount
        0 to _min10Count
        0 to _minCount
        0 to _timerMinutes

        updateTimerLabels
      then

      xTouch yTouch BACK_BUTTON buttonPoll
      if
        toneOff
        true to _done
      then
    then
    
    _alarmSounding 
    if 
      _alarmDelay MS-TICKS <
      if
        _alarmToggle
        if
          false to _alarmToggle
          800 playTone
        else
          true to _alarmToggle
          toneOff
        then
        MS-TICKS ALARM_DELAY + to _alarmDelay
      then
    then
    _done
  until
;





