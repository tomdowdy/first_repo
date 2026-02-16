\
\ XPT2046.fth - Driver for the touch screen controller on the ILI9341 LCD
\ NOTE: HSPI must be initialized before this code runs
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 12/26/2021
\

\ Calibration constants
\ These are the point values with the screen in the portrait mode 
\ with the large connector at bottom
 223 constant X_TOP_LEFT
3879 constant Y_TOP_LEFT
3864 constant X_TOP_RIGHT
3835 constant Y_TOP_RIGHT
 159 constant X_BOT_LEFT
 420 constant Y_BOT_LEFT
3787 constant X_BOT_RIGHT
 400 constant Y_BOT_RIGHT

\ Touch coordinates returned in these values
0 value xTouch
0 value yTouch

\ Local variables
0 value _rotation
0 value _ms

SPI

\ Initialize the touch screen driver
: initTS ( rot -- )
  to _rotation
  T_CS OUTPUT pinMode
  T_CS HIGH digitalWrite
  T_IRQ INPUT_PULLUP pinMode

  \ Do initial reads to clear hardware
  TS_SPI_FREQUENCY HSPI.setFrequency
  T_CS LOW digitalWrite
  $D0 HSPI.transfer8 drop
  $00 HSPI.transfer8 drop
  $00 HSPI.transfer8 drop
  T_CS HIGH digitalWrite
  LCD_SPI_FREQUENCY HSPI.setFrequency
   
  ms-ticks to _ms
;

\ Map raw values to the LCD
: doMapping { rawX rawY }

  \ cr
  \ ." rx: " rawX . cr
  \ ." ry: " rawY . cr

  _rotation
  case
    0 of rawX X_TOP_LEFT X_TOP_RIGHT  0 239 map to xTouch
         rawY Y_TOP_LEFT Y_BOT_LEFT   0 319 map to yTouch
      endof

    1 of rawX X_TOP_RIGHT X_TOP_LEFT  0 239 map to yTouch
         rawY Y_TOP_RIGHT Y_BOT_RIGHT 0 319 map to xTouch
     endof

    2 of rawX X_BOT_RIGHT X_BOT_LEFT  0 239 map to xTouch
         rawY Y_BOT_RIGHT Y_TOP_RIGHT 0 319 map to yTouch
      endof

    3 of rawX X_BOT_LEFT X_BOT_RIGHT  0 239 map to yTouch
         rawY Y_BOT_LEFT Y_TOP_LEFT   0 319 map to xTouch
      endof
  endcase

  xTouch 0 <
  if
    0 to xTouch
  then

  yTouch 0 <
  if
    0 to yTouch
  then
;


\ Poll touch hardware
: updateTS ( -- )

  0 0 0 0 { now rawX rawY tmp }
  
  ms-ticks to now
  now _ms - 50 >=
  if
    TS_SPI_FREQUENCY HSPI.setFrequency
    T_CS LOW digitalWrite

    \ Do sample request for x position
    $D0 HSPI.transfer8 drop
    $00 HSPI.transfer8 5 << to tmp
    $00 HSPI.transfer8 3 >> $1F and tmp or to rawX

    \ Do sample request for y position
    $90 HSPI.transfer8 drop
    $00 HSPI.transfer8 5 << to tmp
    $00 HSPI.transfer8 3 >> $1F and tmp or to rawY

    T_CS HIGH digitalWrite
    LCD_SPI_FREQUENCY HSPI.setFrequency

    rawX rawY doMapping

    now to _ms
  then
;

Forth

\ Has the screen been touched ?
: touched ( -- f )
  T_IRQ digitalRead LOW =
;

\ Return the touch point in xTouch, yTouch when returned flag is true
: getTouchPoint ( -- f )

  \ Has the screen be touched ?
  touched
  if
    \ Screen has been touched
    updateTS

    \ Don't return until touch is removed
    begin
      touched false =
    until
    true
  else
    false
  then 
;

\ Test code

\ : test0
\  0 initLCD clearscreen
\  0 initTS
\  cr cr
\  begin
\    getTouchPoint
\    if
\      ." x: " xTouch . cr
\      ." y: " yTouch . cr
\    then
\    false
\  until
\ ;

\ : test1
\  1 initLCD clearscreen
\  1 initTS
\  cr cr
\  begin
\    getTouchPoint
\    if
\      ." x: " xTouch . cr
\      ." y: " yTouch . cr
\    then
\    false
\  until
\ ;

\ : test2
\  2 initLCD clearscreen
\  2 initTS
\  cr cr
\  begin
\    getTouchPoint
\    if
\      ." x: " xTouch . cr
\      ." y: " yTouch . cr
\    then
\    false
\  until
\ ;

\ : test3
\  3 initLCD clearscreen
\  3 initTS
\  cr cr
\  begin
\    getTouchPoint
\    if
\      ." x: " xTouch . cr
\      ." y: " yTouch . cr
\    then
\    false
\  until
\ ;





