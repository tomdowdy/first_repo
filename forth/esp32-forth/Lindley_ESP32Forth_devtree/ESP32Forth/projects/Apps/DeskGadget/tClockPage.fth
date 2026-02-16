\
\ ESP32Forth Desk Gadget - Star Trek like Clock Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/18/2022
\

\ Display the static page content
: displayTClockPage

  clearscreen

  \ Draw graphics on top of display
    0   0 319 115 40 PURPLE fillRoundedRect 
   40  20 280  80 20 BLACK  fillRoundedRect
    0  45  50   7    BLACK  fillRect2
    0  70  50   7    BLACK  fillRect2
  160   0   4  20    BLACK  fillRect2

  2 setTextSize
  YELLOW setFGColor
  PURPLE setBGColor
  170 2 s" Power:110%" pString
 
  100   1  24  17 DARKCYAN fillRect2

  \ Draw the backing graphics on bottom of display
    0 125 319 115 40 MAROON fillRoundedRect
   40 141 280  93 20 BLACK  fillRoundedRect
    0 168  50  35    BLACK  fillRect2

  BLACK setBGColor
  55 150 s" Temp:" pString
 
  \ Draw gauge
  130 152 40 10 YELLOW fillRect2
  172 152 40 10 GREEN  fillRect2
  214 152 40 10 RED    fillRect2

  \ Guage indicator
  208 157 3 BLACK fillCircle

  \ Creeper background
  188 208 130 30 15 DARKCYAN fillRoundedRect
;

0 value _prevMin
0 value _prevSec
0 value _mon
0 value _day
0 value _year
0 value _hr
0 value _min
0 value _sec
0 value _secmod
0 value _done

\ Display page and update time/date until back button is pressed
: doTClock 

  false to _done

  displayTClockPage

  begin
    now toLocal >r

    r@ minute_t to _min
    r@ second_t to _sec

    \ Has the minute changed ?
    _min _prevMin <>
    if
      _min to _prevMin

      r@ month_t to _mon
      r@ day_t   to _day
      r@ year_t  to _year
      r@ hour_t  to _hr
      
      5 setTextSize
      WHITE setFGColor
      BLACK setBGColor

      \ Initialize format buffer index
      0 to indx

      \ Format time string like: 17 : 19
      _hr #to$  $cat 
      s"  : "   $cat

      \ If minutes single digit 0..9 add leading zero to string 
      _min 10 <
      if
        s" 0" $cat
      then

      _min #to$ $cat

      \ Print the time string
      76 44 0 FORMAT_BUFFER indx pString

      \ Display the month
      2 setTextSize
      0 179 _mon getMonName pString 

      \ Display the date
      \ Initialize format buffer index
      0 to indx
      _day #to$  $cat
      s"  - "    $cat
      _year #to$ $cat

      4 setTextSize
      58 173 0 FORMAT_BUFFER indx pString 
    then

    \ Has the second changed ?
    _sec _prevSec <>
    if
      _sec to _prevSec
    
      \ Build a bargraph every 10 seconds
      _sec 10 mod to _secmod
      _secmod 0 <>
      if
        200 _secmod 10 * + 216 6 15 ORANGE fillRect2
      else
        \ Clear display area
        188 208 130 30 15 DARKCYAN fillRoundedRect
      then
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





