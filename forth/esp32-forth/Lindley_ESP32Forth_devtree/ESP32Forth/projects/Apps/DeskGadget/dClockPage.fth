\
\ ESP32Forth Desk Gadget - Digital Clock Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/17/2022
\

\ Y positions for the various strings
 32 constant DAY_Y
 80 constant DATE_Y
130 constant TIME_Y

\ Display the static page content
: displayDClockPage

  BLUE fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  WHITE setFGColor
  BLUE  setBGColor

  \ Output text
  8 s" Digital Clock Page" pCenteredString
;

0 value _prevMinute
0 value _min
0 value _done

\ Display page and update time/date until back button is pressed
: doDClock 

  false to _done

  displayDClockPage

  begin
    now toLocal >r

    r@ minute_t to _min

    \ Has the minute changed ?
    _min _prevMinute <>
    if
      _min to _prevMinute
      
      \ Print day of the week
      4 setTextSize

      DAY_Y r@ weekDay_t getDayName pCenteredString

      \ Initialize format buffer index
      0 to indx

      \ Format date string like: Jan 18, 2017
      r@ month_t   getMonName $cat addSpace
      r@ day_t     #to$ $cat s" , " $cat
      r@ year_t    #to$ $cat

      \ Print the centered date line
      DATE_Y 0 FORMAT_BUFFER indx pCenteredString  

      \ Initialize format buffer index
      0 to indx

      \ Format the time string like: 9:59 AM
      r@ hourFormat12_t #to$ $cat
      s" :" $cat

      \ If minutes single digit 0..9 add leading zero to string 
      r@ minute_t 10 <
      if
        s" 0" $cat
      then

      r@ minute_t #to$ $cat
      addSpace

      r@ isAM_t if 0 getAMPM else 1 getAMPM then $cat

      \ Print the centered time line
      5 setTextSize
      TIME_Y 0 FORMAT_BUFFER indx pCenteredString  
    then

    \ Clean up
    r> drop

    \ Check for back button
    getTouchPoint
    if
      true to _done
    then
    _done
  until
;





