\
\ Rotary Encoder Driver
\ Ported from code written by: Ben Buxton
\ See: https://github.com/buxtronix/arduino/tree/master/libraries/Rotary
\ Written for ESP32forth
\ Ported by Craig A. Lindley
\ Last Update: 06/29/2022

$10 constant DIR_CW
$20 constant DIR_CCW

\ State machine states
0 constant R_START
1 constant R_CW_FINAL
2 constant R_CW_BEGIN
3 constant R_CW_NEXT
4 constant R_CCW_BEGIN
5 constant R_CCW_FINAL
6 constant R_CCW_NEXT

\ Local variables
0 value state
0 value plusPin
0 value minusPin

\ Creat FSM state table
create STATE_TABLE

 R_START    c, R_CW_BEGIN  c, R_CCW_BEGIN c, R_START c,
 R_CW_NEXT  c, R_START     c, R_CW_FINAL  c, DIR_CW  c,
 R_CW_NEXT  c, R_CW_BEGIN  c, R_START     c, R_START c,
 R_CW_NEXT  c, R_CW_BEGIN  c, R_CW_FINAL  c, R_START c,
 R_CCW_NEXT c, R_START     c, R_CCW_BEGIN c, R_START c,
 R_CCW_NEXT c, R_CCW_FINAL c, R_START     c, DIR_CCW c,
 R_CCW_NEXT c, R_CCW_FINAL c, R_CCW_BEGIN c, R_START c,

\ Get state from table
: getState ( row col -- state )
  swap     ( row col -- col row ) 
  4 * +    ( col row -- row * 4 + col )
  STATE_TABLE +
  c@       ( addr -- state )
;

\ Initialize driver
: initRE ( plusPin minusPin -- )
  \ Save GPIO pin numbers
  to minusPin
  to plusPin

  \ Configure GPIO pins as inputs
  plusPin  INPUT_PULLUP pinMode
  minusPin INPUT_PULLUP pinMode

  \ Set initial state
  R_START to state
;

\ Poll rotary encoder
\ This should be called as fast as possible
: pollEncoder ( -- val )

  \ Get state table row
  state $F and

  \ Get state table col
  plusPin digitalRead 1 << 
  minusPin digitalRead or

  \ Lookup new state
  getState to state

  state $30 and
;


0 value encoderValue

\ Read and process encoder data
: readEncoder { inc minVal maxVal } ( inc minVal maxVal -- f )

  \ Poll the rotary encoder
  pollEncoder { fsmVal }

  fsmVal DIR_CW =
  if
    inc +to encoderValue
    encoderValue maxVal >
    if maxVal to encoderValue then
    true
  else
    fsmVal DIR_CCW =
    if
      -1 inc * +to encoderValue
      encoderValue minVal <
      if minVal to encoderValue then
      true
    else
      false
    then
  then
;


\ *************** Test code **************

\ Rotary encoder signals
\ 35 constant RE_PLUS_PIN
\ 36 constant RE_MINUS_PIN
\
\ Connections to rotary encoder for testing
\
\ : testRE
\  RE_PLUS_PIN RE_MINUS_PIN initRE
\
\  begin 
\    1 0 12 readEncoder
\    if 
\      encoderValue . cr
\    then
\
\    1 delay
\
\    false
\  until
\ ;

