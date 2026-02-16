\
\ ESP32Forth Desk Gadget - Analog Clock Page
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/17/2022
\

\ Program Constants

224 constant DATE_Y

\ Center of 320x240 display in landscape mode
160 constant XCENTER
120 constant YCENTER

 98 constant CLOCK_RADIUS

 \ 5 mnute marks
 98 constant FMM_OUT_RADIUS
 81 constant FMM_IN_RADIUS

 \ 1 minute marks
 98 constant MM_OUT_RADIUS
 88 constant MM_IN_RADIUS

 \ Center circle radius
  5 constant CC_RADIUS
  3 constant HAND_RADIUS

 \ Hand lengths
 70 constant MIN_HAND_LEN
 50 constant HR_HAND_LEN

 \ Colors
 BLUE  constant PG_COLOR
 WHITE constant MIN_HAND_COLOR
 BLACK constant HR_HAND_COLOR 

\ Display the static page content
: displayACP

  PG_COLOR fillscreen
  3 3 getLCDWidth 6 - getLCDHeight 6 - GREEN drawRect

  2 setTextSize
  GREEN setFGColor
  BLUE  setBGColor

  \ Draw text
       1 s" Analog Clock Page" pCenteredString
  \ DATE_Y s" Mon Dec 28, 2021"  pCenteredString

  \ Declare some local variables
  0 0 0 0 { x1 y1 x2 y2 }

  \ Draw 1 minute marks
  360 0
  do
    i s>f fdtorad fsin MM_IN_RADIUS  s>f f* YCENTER s>f f+ f>s to y1
    i s>f fdtorad fcos MM_IN_RADIUS  s>f f* XCENTER s>f f+ f>s to x1
    i s>f fdtorad fsin MM_OUT_RADIUS s>f f* YCENTER s>f f+ f>s to y2
    i s>f fdtorad fcos MM_OUT_RADIUS s>f f* XCENTER s>f f+ f>s to x2
    x1 y1 x2 y2 WHITE line
    6
  +loop

  \ Draw 5 minute marks
  360 0
  do
    i s>f fdtorad fsin FMM_IN_RADIUS  s>f f* YCENTER s>f f+ f>s to y1
    i s>f fdtorad fcos FMM_IN_RADIUS  s>f f* XCENTER s>f f+ f>s to x1
    i s>f fdtorad fsin FMM_OUT_RADIUS s>f f* YCENTER s>f f+ f>s to y2
    i s>f fdtorad fcos FMM_OUT_RADIUS s>f f* XCENTER s>f f+ f>s to x2
    x1 y1 x2 y2 WHITE line
    30
  +loop

  \ Draw clock outline
  XCENTER YCENTER CLOCK_RADIUS     BLACK circle
  XCENTER YCENTER CLOCK_RADIUS 1 + BLACK circle
  XCENTER YCENTER CLOCK_RADIUS 2 + BLACK circle
;

\ Draw or erase the minute hand at the aDegrees angle
: drawMinHand { aDegrees draw }
  \ Create some temps
  0 0 0 0 0 0 0 { x y x1 y1 x2 y2 color }

  aDegrees s>f fdtorad fsin MIN_HAND_LEN s>f f* YCENTER s>f f+ f>s to y
  aDegrees s>f fdtorad fcos MIN_HAND_LEN s>f f* XCENTER s>f f+ f>s to x

  aDegrees 90 - s>f fdtorad fsin HAND_RADIUS s>f f* YCENTER s>f f+ f>s to y1
  aDegrees 90 - s>f fdtorad fcos HAND_RADIUS s>f f* XCENTER s>f f+ f>s to x1

  aDegrees 90 + s>f fdtorad fsin HAND_RADIUS s>f f* YCENTER s>f f+ f>s to y2
  aDegrees 90 + s>f fdtorad fcos HAND_RADIUS s>f f* XCENTER s>f f+ f>s to x2

  draw
  if
    MIN_HAND_COLOR
  else
    PG_COLOR
  then
  to color
    
  XCENTER YCENTER x y color line
  x y x1 y1 color line
  x y x2 y2 color line
;

\ Draw or erase the hour hand at the aDegrees angle
: drawHrHand { aDegrees draw }
  \ Create some temps
  0 0 0 0 0 0 0 { x y x1 y1 x2 y2 color }

  aDegrees s>f fdtorad fsin HR_HAND_LEN s>f f* YCENTER s>f f+ f>s to y
  aDegrees s>f fdtorad fcos HR_HAND_LEN s>f f* XCENTER s>f f+ f>s to x

  aDegrees 90 - s>f fdtorad fsin CC_RADIUS s>f f* YCENTER s>f f+ f>s to y1
  aDegrees 90 - s>f fdtorad fcos CC_RADIUS s>f f* XCENTER s>f f+ f>s to x1

  aDegrees 90 + s>f fdtorad fsin CC_RADIUS s>f f* YCENTER s>f f+ f>s to y2
  aDegrees 90 + s>f fdtorad fcos CC_RADIUS s>f f* XCENTER s>f f+ f>s to x2

  draw
  if
    HR_HAND_COLOR
  else
    PG_COLOR
  then
  to color
    
  XCENTER YCENTER x y color line
  x y x1 y1 color line
  x y x2 y2 color line
;

0 value _prevMinute
0 value _prevMinAngle
0 value _prevHrAngle
0 value _hr
0 value _min
0 value _done

\ Display page and update time/date until back button is pressed
: doAClock 

  false to _done

  displayACP

  begin
    now toLocal >r

    r@ minute_t to _min

    \ Has the minute changed ?
    _min _prevMinute <>
    if
      _min to _prevMinute

      \ Erase minute hand position
      _prevMinAngle false drawMinHand

      \ Calculate new minute hand position
      _min 6 * 90 - to _prevMinAngle      

      \ Draw minute hand position
      _prevMinAngle true drawMinHand

      \ Get hours
      r@ hourFormat12_t to _hr
 
      \ Erase hour hand position
      _prevHrAngle false drawHrHand

      \ min / 70 moves the hr hand slowly forward as mins approach an hr
      _min s>f 70e f/ _hr s>f f+ 30e f* 90e f- f>s to _prevHrAngle

      \ Draw hour hand position
      _prevHrAngle true drawHrHand

      \ Draw circle at center
      XCENTER YCENTER CC_RADIUS BLACK fillCircle

      \ Format date string like: Jan 18, 2017  
      \ Initialize format buffer index
      0 to indx

      r@ weekDay_t getDayName $cat addSpace
      r@ month_t   getMonName $cat addSpace
      r@ day_t     #to$ $cat s" , " $cat
      r@ year_t    #to$ $cat

      \ Print the centered date line
      DATE_Y 0 FORMAT_BUFFER indx pCenteredString  
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





