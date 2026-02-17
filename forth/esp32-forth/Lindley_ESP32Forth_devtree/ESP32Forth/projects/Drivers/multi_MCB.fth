\
\ Multi Multi Click Button Code
\
\ This code allows multiple Multi Click Button instances to exist simultaneously
\ Ported from code written by: Martin Poelstra
\ See: https://github.com/poelstra/arduino-multi-button
\ Written for ESP32forth
\ Ported/Enhanced by Craig A. Lindley
\ Last Update: 04/10/2023
\

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

\ Multi Click Button Instance Data
struct:
  cell field: .buttonPin
  cell field: .lastTransition
  cell field: .state
  cell field: .new
  cell field: .now
  cell field: .diff
  cell field: .next
constant INSTANCE_DATA

\ **************** Support Functions ****************

: _checkIdle ( pressed -- state )
  if
    S_DEBOUNCE
  else
    S_IDLE
  then
;

: _checkDebounce { pressed diff -- state }
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

: _checkPressed { pressed diff -- state }
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

: _checkClickIdle { pressed diff -- state }
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

: _checkDoubleClickDebounce { pressed diff -- state }
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

: isClick { name -- f }
  name .state @ S_PRESSED = name .state @ S_DOUBLECLICK = or name .new @ and
;

: isSingleClick { name -- f }
  name .state @ S_SINGLECLICK = name .new @ and
;

: isDoubleClick { name -- f }
  name .state @ S_DOUBLECLICK = name .new @ and
;

: isLongClick { name -- f }
  name .state @ S_LONGCLICK = name .new @ and
;

: isReleased { name -- f }
  name .state @ S_CLICKUP = name .state @ S_OTHERUP = or name .new @ and
;

\ Update FSM
: _update { name pressed -- }

  false name .new !

  \ If state is IDLE and button not pressed, skip next code block
  name .state @ S_IDLE = pressed not and not
  if
    ms-ticks name .now !
    name .now @ name .lastTransition @ - name .diff !
    S_IDLE name .next !

    name .state @
    case
      S_IDLE                
        of
          pressed _checkIdle name .next ! 
        endof

      S_DEBOUNCE
        of 
          pressed name .diff @ _checkDebounce name .next ! 
        endof

      S_PRESSED
        of
          pressed name .diff @ _checkPressed name .next ! 
        endof

      S_CLICKUP
        of
          S_CLICKIDLE name .next ! 
        endof

      S_CLICKIDLE
        of 
          pressed name .diff @ _checkClickIdle name .next ! 
        endof

      S_SINGLECLICK
        of 
          S_IDLE name .next !
        endof

      S_DOUBLECLICKDEBOUNCE 
        of 
          pressed name .diff @ _checkDoubleClickDebounce name .next ! 
        endof

      S_DOUBLECLICK         
        of
          pressed _checkDoubleClick name .next ! 
        endof

      S_LONGCLICK           
        of
          pressed _checkLongClick name .next ! 
        endof

      S_OTHERUP             
        of
          S_IDLE name .next !
        endof
    endcase

    name .next @ name .state @ <>
    if
      name .now  @ name .lastTransition !
      name .next @ name .state !
      true name .new !
    then
  then
;

\ **************** Button Functions Public Interface ****************

\ Create a new multi click button instance
: newMCBInstance ( "name" -- )
  INSTANCE_DATA create allot
;

\ Initialize button instance for multi click operation
\ It is assumed the GPIO pin associated with the new button
\ has already been configured as input with pullup or
\ as an input with an external pullup
: initMCBInstance { buttonPin name -- }
  buttonPin name .buttonPin !

  \ Prepare state machine for operation
  ms-ticks name .lastTransition !
  S_IDLE   name .state !
  false    name .new !
  0        name .now !
  0        name .diff !
  0        name .next !
;

\ Update the multi click button instance data
: updateMCBButtonInstance { name -- }
  name dup .buttonPin @ digitalRead 0= _update
;

\ Test Code using actual sequencer hardware - WORKS GREAT
\
\ newMCBInstance Switch1
\ newMCBInstance Switch2
\ newMCBInstance Switch3
\ newMCBInstance Switch4
\ newMCBInstance Switch5
\ newMCBInstance Switch6
\ newMCBInstance Switch7
\ newMCBInstance Switch8
\
\ SW1 Switch1 initMCBInstance
\ SW2 Switch2 initMCBInstance
\ SW3 Switch3 initMCBInstance
\ SW4 Switch4 initMCBInstance
\ SW5 Switch5 initMCBInstance
\ SW6 Switch6 initMCBInstance
\ SW7 Switch7 initMCBInstance
\ SW8 Switch8 initMCBInstance
\
\ : run
\  SW1 INPUT_PULLUP pinMode
\  SW2 INPUT_PULLUP pinMode
\  SW3 INPUT_PULLUP pinMode
\  SW4 INPUT_PULLUP pinMode
\  SW5 INPUT_PULLUP pinMode
\  SW6 INPUT_PULLUP pinMode
\  SW7 INPUT_PULLUP pinMode
\  SW8 INPUT_PULLUP pinMode
\
\  begin
\    Switch1 updateMCBButtonInstance
\    Switch2 updateMCBButtonInstance
\    Switch3 updateMCBButtonInstance
\    Switch4 updateMCBButtonInstance
\    Switch5 updateMCBButtonInstance
\    Switch6 updateMCBButtonInstance
\    Switch7 updateMCBButtonInstance
\    Switch8 updateMCBButtonInstance
\
\    Switch1 isSingleClick if cr ." Switch 1 Clicked" cr then
\    Switch2 isSingleClick if cr ." Switch 2 Clicked" cr then
\    Switch3 isSingleClick if cr ." Switch 3 Clicked" cr then
\    Switch4 isSingleClick if cr ." Switch 4 Clicked" cr then
\    Switch5 isSingleClick if cr ." Switch 5 Clicked" cr then
\    Switch6 isSingleClick if cr ." Switch 6 Clicked" cr then
\    Switch7 isSingleClick if cr ." Switch 7 Clicked" cr then
\    Switch8 isSingleClick if cr ." Switch 8 Clicked" cr then
\  
\    Switch1 isDoubleClick if cr ." Switch 1 Double Clicked" cr then
\    Switch2 isDoubleClick if cr ." Switch 2 Double Clicked" cr then
\    Switch3 isDoubleClick if cr ." Switch 3 Double Clicked" cr then
\    Switch4 isDoubleClick if cr ." Switch 4 Double Clicked" cr then
\    Switch5 isDoubleClick if cr ." Switch 5 Double Clicked" cr then
\    Switch6 isDoubleClick if cr ." Switch 6 Double Clicked" cr then
\    Switch7 isDoubleClick if cr ." Switch 7 Double Clicked" cr then
\    Switch8 isDoubleClick if cr ." Switch 8 DoubleClicked" cr then
\  
\    Switch1 isLongClick if cr ." Switch 1 Long Clicked" cr then
\    Switch2 isLongClick if cr ." Switch 2 Long Clicked" cr then
\    Switch3 isLongClick if cr ." Switch 3 Long Clicked" cr then
\    Switch4 isLongClick if cr ." Switch 4 Long Clicked" cr then
\    Switch5 isLongClick if cr ." Switch 5 Long Clicked" cr then
\    Switch6 isLongClick if cr ." Switch 6 Long Clicked" cr then
\    Switch7 isLongClick if cr ." Switch 7 Long Clicked" cr then
\    Switch8 isLongClick if cr ." Switch 8 Long Clicked" cr then
\  
\    false
\  until
\ ;






