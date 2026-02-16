\
\ Pocket Watch Code
\ Using a round LCD display with GC9A01 display controller
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 03/17/2023
\

\ Colors used on watch
$0000 constant BLK
$F800 constant RED
$07E0 constant GRN
$001F constant BLU
$FFFF constant WHT

RED constant HOUR_COLOR
GRN constant MIN_COLOR
WHT constant SEC_COLOR

 70 constant HOUR_RADIUS
 10 constant HOUR_INDICATOR_RADIUS

 93 constant MIN_RADIUS
  6 constant MIN_INDICATOR_RADIUS

113 constant SEC_RADIUS
  5 constant SEC_INDICATOR_RADIUS

\ Polar to cartesian transform
: polarToCartesian { radius angle } ( radius angle - x y )
  radius s>f angle s>f fdtorad fcos f* f>s
  radius s>f angle s>f fdtorad fsin f* f>s
;

\ Draw hour circle
: drawHourCircle { angle color }

  HOUR_RADIUS angle 90 - polarToCartesian  ( -- x y )
  120 + swap 120 + swap
  HOUR_INDICATOR_RADIUS color fillCircle
;

\ Draw minute circle
: drawMinCircle { angle color }

  MIN_RADIUS angle 90 - polarToCartesian  ( -- x y )
  120 + swap 120 + swap
  MIN_INDICATOR_RADIUS color fillCircle
;

\ Draw second circle
: drawSecCircle { angle color }

  SEC_RADIUS angle 90 - polarToCartesian  ( -- x y )
  120 + swap 120 + swap
  SEC_INDICATOR_RADIUS color fillCircle
;

0 value _month_
0 value _day_
0 value _hour_
0 value _min_
0 value _sec_

0 value prevHour
0 value prevMin
0 value prevSec

WiFi

\ Program entry point
: main ( -- )
  cr
  0 initLCD

  \ Login to wifi network
  z" CraigNet" z" craigandheather" login

  100 delay

  \ Paint screen white
  WHT fillScreen

  \ Draw 2 red circles
  120 120 HOUR_RADIUS    RED circle 
  120 120 HOUR_RADIUS 1- RED circle 

  \ Draw initial hour circles
  12 0
  do
    i 30 * BLK drawHourCircle
  loop

  \ Draw initial min circles
  60 0
  do
    i 6 * BLK drawMinCircle
  loop

  \ Draw initial sec circles
  60 0
  do
    i 6 * BLK drawSecCircle
  loop

  \ Draw static text
  BLK setFGColor
  WHT setBGColor
  3 setTextSize

  103  65 s" 12" pstring
  160 110 s" 3" pstring
  113 154 s" 6" pstring
   66 110 s" 9" pstring

  \ Set US Mountain timezone
  usMT setTZ

  \ Prime the time
  now toLocal drop

  \ Do forever
  begin

    now toLocal >r
    r@ month_t to _month_
    r@ day_t to _day_
    r@ hourFormat12_t to _hour_
    r@ minute_t to _min_
    r> second_t to _sec_

    _sec_ prevSec <>
    if
      prevSec 6 *       BLK drawSecCircle
      _sec_   6 * SEC_COLOR drawSecCircle
      _sec_ to prevSec
    then

    _min_ prevMin <>
    if
      prevMin 6 *       BLK drawMinCircle
      _min_   6 * MIN_COLOR drawMinCircle
      _min_ to prevMin
    then

    _hour_ prevHour <>
    if
      prevHour 30 *        BLK drawHourCircle
      _hour_   30 * HOUR_COLOR drawHourCircle
      _hour_ to prevHour

      \ Display the date once an hour
       93 _month_ getMonName pCenteredString
      125 _day_ str pCenteredString
    then

    250 delay

    false
  until
;
