\
\ ESP32Forth Desk Gadget - Mode Selection Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/17/2022
\

\ Define the buttons on this page
\ Row 1
 12  80 90 30 B_D_COLOR s" D Clock" 2 BLACK buttonCreate D_CLOCK_BUTTON
115  80 90 30 B_D_COLOR s" A Clock" 2 BLACK buttonCreate A_CLOCK_BUTTON
218  80 90 30 B_D_COLOR s" T Clock" 2 BLACK buttonCreate T_CLOCK_BUTTON

\ Row 2
 12 130 90 30 B_D_COLOR s" Alarm"   2 BLACK buttonCreate ALARM_BUTTON
115 130 90 30 B_D_COLOR s" Timer"   2 BLACK buttonCreate TIMER_BUTTON
218 130 90 30 B_D_COLOR s" Fun"     2 BLACK buttonCreate FUN_BUTTON


\ Display the main UI page
: displayMainPage

  BLUE fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  WHITE setFGColor
  BLUE  setBGColor

  \ Output text
   8 s" Craig Lindley's" pCenteredString
  32 s" ESP32 Forth"     pCenteredString
  52 s" Desktop Gadget"  pCenteredString

  \ Draw the buttons
  D_CLOCK_BUTTON buttonDraw
  A_CLOCK_BUTTON buttonDraw
  T_CLOCK_BUTTON buttonDraw
    ALARM_BUTTON buttonDraw
    TIMER_BUTTON buttonDraw
      FUN_BUTTON buttonDraw

  178 s" Select Mode of Operation" pCenteredString
  215 s" Version: 0.5" pCenteredString
;

\ Bring in WiFi vocabulary
wifi

\ Program entry point
: main

  \ Initialize hardware
  3 initLCD 3 initTS

  \ Setup timekeeping 
  usMT setTZ

  \ Login to WiFi network
  z" CraigNet" z" craigandheather" login

  \ Bring up page
  displayMainPage

  begin
    \ Was screen touched ?
    getTouchPoint
    if
      xTouch yTouch D_CLOCK_BUTTON buttonPoll
      if 
        doDClock
        displayMainPage
      then

       xTouch yTouch A_CLOCK_BUTTON buttonPoll
       if
         doAClock
         displayMainPage
       then

       xTouch yTouch T_CLOCK_BUTTON buttonPoll
       if
         doTClock 
         displayMainPage
       then

       xTouch yTouch ALARM_BUTTON buttonPoll
       if
         doAlarm
         displayMainPage
       then

       xTouch yTouch TIMER_BUTTON buttonPoll
       if 
         doTimer 
         displayMainPage
       then

       xTouch yTouch FUN_BUTTON buttonPoll
       if
         doFun
         displayMainPage
       then
    then
    false
  until
;



