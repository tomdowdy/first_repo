\
\ Rotary Encoder Driver
\ Written for ESP32forth
\ Written by Craig A. Lindley
\ Last Update: 04/29/2023
\

$10 constant FCODE
$20 constant BCODE

\ State machine states
0 constant START
1 constant F1
2 constant F2
3 constant F3
4 constant B1
5 constant B2
6 constant B3
7 constant ERROR

\ Local variables
0 value _rePlusPin
0 value _reMinusPin
0 value _reState
0 value _reValue

\ Initialize driver
: initRE ( plusPin minusPin -- )
  \ Save GPIO pin numbers
  to _reMinusPin
  to _rePlusPin

  \ Configure GPIO pins as inputs
  _rePlusPin  INPUT_PULLUP pinMode
  _reMinusPin INPUT_PULLUP pinMode

  \ Set initial state
  START to _reState
;

\ Read the encoder pins
: _readEncoderPins
  _rePlusPin digitalRead 1 << 
  _reMinusPin digitalRead or
  invert $0003 and
; 

\ This should be called as fast as possible
\ to update the FSM
: _updateRE ( -- n )

  0 to _reValue

  \ Read the encoder
  _readEncoderPins { in }
  
  _reState
  case
    START
    of
      in
      case
        2 of F1 to _reState endof
        1 of B1 to _reState endof
      endcase
    endof

    F1
    of
      in
      case
        3 of F2 to _reState endof
        2 of endof
        ERROR to _reState
      endcase
    endof

    F2
    of
      in
      case
        1 of F3 to _reState endof
        3 of endof
        ERROR to _reState
      endcase
    endof

    F3
    of
      in
      case
        0 of FCODE to _reValue START to _reState endof
        1 of endof
        ERROR to _reState
      endcase
    endof

    B1
    of
      in
      case
        3 of B2 to _reState endof
        1 of endof
        ERROR to _reState
      endcase
    endof

    B2
    of
      in
      case
        2 of B3 to _reState endof
        3 of endof
        ERROR to _reState
      endcase
    endof

    B3
    of
      in
      case
        0 of BCODE to _reValue START to _reState endof
        2 of endof
        ERROR to _reState
      endcase
    endof

    ERROR
    of
      in
      0=
      if
        START to _reState
      then
    endof
  endcase
  _reValue
;

0 value encoderValue

\ Set encoder value
: setEncoderValue ( val -- )
  to encoderValue
;

\ Get encoder value 
: getEncoderValue ( -- val )
  encoderValue
;

\ Read and process encoder data
: readEncoder { inc minVal maxVal -- f }

  \ Update FSM
  _updateRE { fsmVal }

  fsmVal FCODE =
  if
    inc +to encoderValue
    encoderValue maxVal >
    if maxVal to encoderValue then
    true
  else
    fsmVal BCODE =
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




