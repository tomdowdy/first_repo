\
\ Multi Click Button Code
\ Ported from code written by: Martin Poelstra
\ See: https://github.com/poelstra/arduino-multi-button
\ Written for ESP32forth
\ Ported by Craig A. Lindley
\ Last Update: 07/01/2022

\ Timing Constants in milliseconds
 20 constant DEBOUNCE_DELAY
250 constant SINGLECLICK_DELAY
300 constant LONGCLICK_DELAY

\ State Constants
0 constant S_IDLE
1 constant S_DEBOUNCE
2 constant S_PRESSED
3 constant S_CLICKUP
4 constant S_CLICKIDLE
5 constant S_SINGLECLICK
6 constant S_DOUBLECLICKDEBOUNCE
7 constant S_DOUBLECLICK
8 constant S_LONGCLICK
9 constant S_OTHERUP

\ Variables
0 value _lastTransition
0 value _state
0 value _new
0 value _now
0 value _diff
0 value _next

\ **************** Support Functions ****************

: _checkIdle ( pressed -- state )
  if
    S_DEBOUNCE
  else
    S_IDLE
  then
;

: _checkDebounce { pressed diff } ( pressed diff -- state )
  pressed not
  if
    S_IDLE
  else
    diff DEBOUNCE_DELAY >=
    if 
      S_PRESSED
    else
      S_DEBOUNCE
    then
  then
;

: _checkPressed { pressed diff } ( pressed diff -- state )
  pressed not
  if
    S_CLICKUP
  else
    diff LONGCLICK_DELAY >=
    if 
      S_LONGCLICK
    else
      S_PRESSED
    then
  then
;

: _checkClickIdle { pressed diff } ( pressed diff -- state )
  pressed
  if
    S_DOUBLECLICKDEBOUNCE
  else
    diff SINGLECLICK_DELAY >=
    if 
      S_SINGLECLICK
    else
      S_CLICKIDLE
    then
  then
;

: _checkDoubleClickDebounce { pressed diff } ( pressed diff -- state )
  pressed not
  if
    S_CLICKIDLE
  else
    diff DEBOUNCE_DELAY >=
    if 
      S_DOUBLECLICK
    else
      S_DOUBLECLICKDEBOUNCE
    then
  then
;

: _checkDoubleClick ( pressed -- state )
  not
  if
    S_OTHERUP
  else
    S_DOUBLECLICK
  then
;

: _checkLongClick ( pressed -- state )
  not
  if
    S_OTHERUP
  else
    S_LONGCLICK
  then
;

: isClick ( -- f )
  _state S_PRESSED = _state S_DOUBLECLICK = or _new and
;

: isSingleClick ( -- f )
  _state S_SINGLECLICK = _new and
;

: isDoubleClick ( -- f )
  _state S_DOUBLECLICK = _new and
;

: isLongClick ( -- f )
  _state S_LONGCLICK = _new and
;

: isReleased ( -- f )
  _state S_CLICKUP = _state S_OTHERUP = or _new and
;

\ Update FSM
: _update { pressed } ( pressed -- )

  false to _new

  \ If state is IDLE and button not pressed, skip next code block
  _state S_IDLE = pressed not and not
  if
    ms-ticks to _now
    _now _lastTransition - to _diff
    S_IDLE to _next

    _state
    case
      S_IDLE                of pressed       _checkIdle                to _next endof
      S_DEBOUNCE            of pressed _diff _checkDebounce            to _next endof
      S_PRESSED             of pressed _diff _checkPressed             to _next endof
      S_CLICKUP             of S_CLICKIDLE                             to _next endof
      S_CLICKIDLE           of pressed _diff _checkClickIdle           to _next endof
      S_SINGLECLICK         of S_IDLE                                  to _next endof
      S_DOUBLECLICKDEBOUNCE of pressed _diff _checkDoubleClickDebounce to _next endof
      S_DOUBLECLICK         of pressed       _checkDoubleClick         to _next endof
      S_LONGCLICK           of pressed       _checkLongClick           to _next endof
      S_OTHERUP             of S_IDLE                                  to _next endof
    endcase

    _next _state <>
    if
      _now  to _lastTransition
      _next to _state
      true to _new
    then
  then
;

\ **************** Button Functions Public Interface ****************

\ GPIO pin number connected to button
0 value _buttonPin

\ Initialize button for multi click operation
: initButton ( buttonPin -- )
  to _buttonPin
  _buttonPin INPUT_PULLUP pinMode

  \ Prepare state machine for operation
  ms-ticks to _lastTransition
  S_IDLE to _state
  false to _new
;

\ Poll the button
: pollButton
  _buttonPin digitalRead 0= _update
;

