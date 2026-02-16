\
\ ESP32Forth Desk Gadget - Alarm Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/17/2022
\

  500 constant ALARM_DELAY
   40 constant LABEL_WIDTH
   27 constant LABEL_HEIGHT
GREEN constant LABEL_COLOR

\ Current time display labels
 30 46 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0"  2 BLACK buttonCreate CT_HR_LABEL
 85 46 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" :"  3 BLACK buttonCreate CT_COLON_LABEL
140 46 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0"  2 BLACK buttonCreate CT_MIN10_LABEL
195 46 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0"  2 BLACK buttonCreate CT_MIN_LABEL
250 46 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" PM" 2 BLACK buttonCreate CT_AMPM_LABEL

\ Alarm time display labels
 30 104 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 12" 2 BLACK buttonCreate AT_HR_LABEL
 85 104 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" :"  3 BLACK buttonCreate AT_COLON_LABEL
140 104 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0"  2 BLACK buttonCreate AT_MIN10_LABEL
195 104 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" 0"  2 BLACK buttonCreate AT_MIN_LABEL
250 104 LABEL_WIDTH LABEL_HEIGHT LABEL_COLOR s" AM" 2 BLACK buttonCreate AT_AMPM_LABEL

\ Define the alarm setting buttons on this page
 30 138 LABEL_WIDTH LABEL_HEIGHT B_D_COLOR s" +" 2 BLACK buttonCreate HR_BUTTON
140 138 LABEL_WIDTH LABEL_HEIGHT B_D_COLOR s" +" 2 BLACK buttonCreate MIN10_BUTTON
195 138 LABEL_WIDTH LABEL_HEIGHT B_D_COLOR s" +" 2 BLACK buttonCreate MIN_BUTTON
250 138 LABEL_WIDTH LABEL_HEIGHT B_D_COLOR s" +" 2 BLACK buttonCreate AMPM_BUTTON

\ Action buttons
 12 172 120 LABEL_HEIGHT B_D_COLOR s" Alarm On"  2 BLACK buttonCreate ALARM_ON_BUTTON
188 172 120 LABEL_HEIGHT B_D_COLOR s" Alarm Off" 2 BLACK buttonCreate ALARM_OFF_BUTTON
123 202  70 30 B_D_COLOR s" Back"  2 BLACK buttonCreate BACK_BUTTON

\ Misc program variables
 0 value _prevMinute
 0 value _min
12 value _hrCount
 0 value _min10Count
 0 value _minCount

 true value _isAM
false value _alarmSounding
false value _alarmToggle
    0 value _alarmDelay
false value _alarmEnabled
false value _done

\ Display the static page content
: displayAlarmPage

  BLUE fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  WHITE setFGColor
  BLUE  setBGColor

  \ Output text strings
  5 s" Alarm Page"   pCenteredString
 26 s" Current Time" pCenteredString
 82 s" Alarm Time"   pCenteredString

  \ Draw current time display labels
   CT_HR_LABEL buttonDraw
CT_COLON_LABEL buttonDraw
CT_MIN10_LABEL buttonDraw
  CT_MIN_LABEL buttonDraw
 CT_AMPM_LABEL buttonDraw

  \ Draw alarm time display labels
   AT_HR_LABEL buttonDraw
AT_COLON_LABEL buttonDraw
AT_MIN10_LABEL buttonDraw
  AT_MIN_LABEL buttonDraw
 AT_AMPM_LABEL buttonDraw

  \ Draw the alarm time setting buttons
     HR_BUTTON buttonDraw
  MIN10_BUTTON buttonDraw
    MIN_BUTTON buttonDraw
   AMPM_BUTTON buttonDraw

  \ Draw the action buttons
 ALARM_ON_BUTTON buttonDraw
ALARM_OFF_BUTTON buttonDraw
    BACK_BUTTON buttonDraw

  \ Set alarm default values
 12 to _hrCount
  0 to _min10Count
  0 to _minCount
  true to _isAM
;

\ Variables used below
0 value __hr
0 value __min10
0 value __min
0 value __isAM

\ Display page and do alarm function until back button is pressed
: doAlarm 

  toneDefaultSetup
  displayAlarmPage

  \ Set the alarm labels to initial values
  _hrCount    AT_HR_LABEL    setButtonNumber
  _min10Count AT_MIN10_LABEL setButtonNumber
  _minCount   AT_MIN_LABEL   setButtonNumber
  _isAM 
  if
    0 getAMPM
  else
    1 getAMPM
  then
  AT_AMPM_LABEL setButtonText

  LABEL_COLOR ALARM_ON_BUTTON setButtonColor

  false to _alarmSounding
  false to _alarmToggle
  false to _alarmEnabled
  false to _done

  begin
    now toLocal >r

    r@ minute_t to _min

    \ Has the minute changed ?
    _min _prevMinute <>
    if
      _min to _prevMinute

      \ Parse the current time
      r@ hourFormat12_t  to __hr
      r@ minute_t 10 /   to __min10
      r@ minute_t 10 mod to __min
      r@ isAM_t          to __isAM

      \ Display the current time
      __hr    CT_HR_LABEL    setButtonNumber
      __min10 CT_MIN10_LABEL setButtonNumber
      __min   CT_MIN_LABEL   setButtonNumber
      __isAM
      if 
        0 getAMPM 
      else 
        1 getAMPM
      then
      CT_AMPM_LABEL setButtonText
    then
    
    \ Clean up
    r> drop 

    \ Conditionally check for alarm time
    _alarmEnabled
    if
      _hrCount    __hr    =
      _min10Count __min10 =
      _minCount   __min   =
      _isAM       __isAM  =
      and and and
      if
        \ Alarm time has been reached
        false to _alarmEnabled
        true  to _alarmSounding
      then
    then

    \ Check buttons for touch
    getTouchPoint
    if
      xTouch yTouch HR_BUTTON buttonPoll
      if
        _alarmEnabled false =
        if 
          1 +to _hrCount
          _hrCount 12 >
          if
            1 to _hrCount
          then
          _hrCount AT_HR_LABEL setButtonNumber
        then
      then

      xTouch yTouch MIN10_BUTTON buttonPoll
      if
        _alarmEnabled false =
        if 
          1 +to _min10Count
          _min10Count 5 >
          if
            0 to _min10Count
          then
          _min10Count AT_MIN10_LABEL setButtonNumber
        then
      then

      xTouch yTouch MIN_BUTTON buttonPoll
      if
        _alarmEnabled false =
        if 
          1 +to _minCount
          _minCount 9 >
          if
            0 to _minCount
          then
          _minCount AT_MIN_LABEL setButtonNumber
        then
      then

      xTouch yTouch AMPM_BUTTON buttonPoll
      if
        _alarmEnabled false =
        if
          _isAM
          if
            false to _isAM
            1 getAMPM
          else
            true to _isAM
            0 getAMPM
          then
          AT_AMPM_LABEL setButtonText
        then
      then

      xTouch yTouch ALARM_ON_BUTTON buttonPoll
      if
        _alarmEnabled false =
        if
          \ Turning alarm on
          true to _alarmEnabled
          RED  ALARM_ON_BUTTON setButtonColor
        then
      then

      xTouch yTouch ALARM_OFF_BUTTON buttonPoll
      if
        \ Turning alarm off
        toneOff
        false to _alarmEnabled
        false to _alarmSounding
        LABEL_COLOR ALARM_ON_BUTTON setButtonColor
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
