\ JSON Streaming Parser
\ Based on: https://github.com/squix78/json-streaming-parser
\ Unicode not supported
\ Written by: Craig A. Lindley
\ Last Update: 09/07/2021

\ Create defered words
\ Json applications must implement the defered words defined below
DEFER jParser
DEFER jStartDocument
DEFER jEndDocument
DEFER jStartObject
DEFER jEndObject
DEFER jStartArray
DEFER jEndArray
DEFER jKey
DEFER jValue

\ Parser constants
-1 constant STATE_DONE
 0 constant STATE_START_DOCUMENT
 1 constant STATE_IN_ARRAY
 2 constant STATE_IN_OBJECT
 3 constant STATE_END_KEY
 4 constant STATE_AFTER_KEY
 5 constant STATE_IN_STRING
 6 constant STATE_START_ESCAPE
 7 constant STATE_IN_NUMBER
 8 constant STATE_IN_TRUE
 9 constant STATE_IN_FALSE
10 constant STATE_IN_NULL
11 constant STATE_AFTER_VALUE

\ Stack tokens
 0 constant STACK_OBJECT
 1 constant STACK_ARRAY
 2 constant STACK_KEY
 3 constant STACK_STRING

\ Max length of any Json value string
\ 64 constant BUFFER_MAX_LENGTH
32 constant BUFFER_MAX_LENGTH

\ Parser character arrays
BUFFER_MAX_LENGTH byteArray buffer
BUFFER_MAX_LENGTH byteArray tmp
               20 byteArray stack

\ Parser variables
0 value jState
0 value jStackPos
0 value jBufferPos
0 value jCharCount

0 value _ch
0 value _popped
0 value _addr
0 value _n
0 value _within


\ Compare two s" strings
: s$= { addr1 n1 addr2 n2 } ( addr1 n1 addr2 n2 -- f )
  TRUE { f }
  \ Equal strings must have equal lengths
  n1 n2 =
  if
    \ Len's are equal so check content
    n1 0
    do
      addr1 i + c@ addr2 i + c@ <>
      if 
        FALSE to f
        leave
      then
    loop
  else
    FALSE to f  
  then
  f
;

\ Create and return a temporary string (from buffer) stored in tmp
: createTmpStr ( -- addr n )
  0 buffer 0 tmp jBufferPos cmove
  0 tmp jBufferPos
;

\ Store char into json stack
: storeInStack ( ch -- )
  jStackPos stack c!
  1 +to jStackPos
;

\ Store char in buffer
: storeInBuffer ( ch -- )
  jBufferPos buffer c!

  jBufferPos 1+ BUFFER_MAX_LENGTH 1- min
  to jBufferPos
;

\ Process start of string
: startStr ( -- )
  STACK_STRING storeInStack
  STATE_IN_STRING to jState
;

: endStr ( -- )
  jStackPos 1- stack c@ to _popped 
  -1 +to jStackPos

  createTmpStr to _n to _addr
  0 to jBufferPos

  _popped STACK_KEY =
  if
    \ Call the listener
    _addr _n jKey
    STATE_END_KEY to jState
    exit
  then

  _popped STACK_STRING =
  if
    \ Call the listener
    _addr _n jValue
    STATE_AFTER_VALUE to jState
    exit
  then

  ." Expected end of string"
;

\ Process end of document
: endDoc ( -- )
  \ Call listener
  jEndDocument
  STATE_DONE to jState
;
 
\ Process end of true
: endTrue ( -- )
  createTmpStr s" true" s$=
  if
    \ Call the listener
    s" true" jValue
  else
    ." Expected true"
  then
  0 to jBufferPos
  STATE_AFTER_VALUE to jState
;

\ Process end of false
: endFalse ( -- )
  createTmpStr s" false" s$=
  if
    \ Call the listener
    s" false" jValue
  else
    ." Expected false"
  then
  0 to jBufferPos
  STATE_AFTER_VALUE to jState
;

\ Process end of null
: endNull ( -- )
  createTmpStr s" null" s$=
  if
    \ Call the listener
    s" null" jValue
  else
    ." Expected null"
  then
  0 to jBufferPos
  STATE_AFTER_VALUE to jState
;

\ Process start of array
: startArray
  \ Call listener
  jStartArray
  STATE_IN_ARRAY to jState
  STACK_ARRAY storeInStack
;

\ Process start of object
: startObj
  \ Call listener
  jStartObject
  STATE_IN_OBJECT to jState
  STACK_OBJECT storeInStack
;

\ Process start of number
: startNum ( ch -- )
  storeInBuffer
  STATE_IN_NUMBER to jState
;

\ Determine if ch is a decimal digit
: isDigit { ch } ( ch -- f )
  ch [char] 0 >= 
  ch [char] 9 <=
  and
  ch [char] - =
  or
;

\ Process start of value
: startVal ( ch -- )
  to _ch
  _ch [char] [ = if startArray exit then
  _ch [char] { = if startObj exit then
  _ch [char] " = if startStr exit then
  _ch isDigit    if _ch startNum exit then
  _ch [char] t = 
  if
    STATE_IN_TRUE to jState
    _ch storeInBuffer
    exit
  then
  _ch [char] f = 
  if
    STATE_IN_FALSE to jState
    _ch storeInBuffer
    exit
  then
  _ch [char] n = 
  if
    STATE_IN_NULL to jState
    _ch storeInBuffer
    exit
  then
  ." Unexpected char for value: " _ch . cr
;

: endArray ( -- ) 
  jStackPos 1- stack c@ to _popped 
  -1 +to jStackPos

  _popped STACK_ARRAY <>
  if ." Unexpected end of array" then
  \ Call listener
  jEndArray
  STATE_AFTER_VALUE to jState
  jStackPos 0=
  if endDoc then
;

: endObj ( -- ) 
  \ CAL - added missing 1-
  jStackPos 1- stack c@ to _popped 
  -1 +to jStackPos

  _popped STACK_OBJECT <>
  if ." Unexpected end of object" then
  \ Call listener
  jEndObject
  STATE_AFTER_VALUE to jState
  jStackPos 0=
  if endDoc then
;

: startKey ( -- )
  STACK_KEY storeInStack
  STATE_IN_STRING to jState
;

: stateInStr ( ch -- )
  to _ch
  _ch [char] " = if endStr exit then
  _ch [char] \ = if  STATE_START_ESCAPE to jState exit then
  _ch $1F < _ch $7F = or if ." Unescaped control char" exit then
  _ch storeInBuffer
;

: stateInArray { ch }
  ch [char] ] =
  if
    endArray
  else
    ch startVal
  then
;

: stateInObj ( ch -- )
  to _ch
  _ch [char] } = if endObj    exit then
  _ch [char] " = if startKey  exit then
  ." Start of string expected"
;

: stateEndKey ( ch -- )
  [char] : <>
  if ." Expected : after key" then
  STATE_AFTER_KEY to jState
;

: processEscChars ( ch -- )
  to _ch
  STATE_IN_STRING to jState

  _ch [char] " = if [char] " storeInBuffer exit then
  _ch [char] \ = if [char] \ storeInBuffer exit then
  _ch [char] / = if [char] / storeInBuffer exit then
  _ch [char] b = if      $08 storeInBuffer exit then
  _ch [char] f = if [char] f storeInBuffer exit then
  _ch [char] n = if      $0A storeInBuffer exit then
  _ch [char] r = if      $0D storeInBuffer exit then
  _ch [char] t = if      $09 storeInBuffer exit then
  _ch [char] u = 
  if
    ." No unicode support" exit
  else
    ." Expected escaped char after \"
  then
;

: stateAfterVal  ( ch -- )
  to _ch
  jStackPos 1- stack c@ to _within

  _within STACK_OBJECT =
  if
    _ch [char] } =
    if 
      endObj exit
    then
    _ch [char] , =
    if
      STATE_IN_OBJECT to jState exit
    then
    ." Expected , or } while parsing object"
    exit
  then

  _within STACK_ARRAY =
  if
    _ch [char] ] =
    if 
      endArray exit
    then
    _ch [char] , =
    if
      STATE_IN_ARRAY to jState exit
    then
    ." Expected , or ] while parsing array"
    exit
  then
  ." Finished literal but unsure of what state to move to"
;  

: endNum  ( -- )
  createTmpStr
  \ Call listener
  jValue

  0 to jBufferPos
  STATE_AFTER_VALUE to jState
;

: stateInNum  ( ch -- )
  to _ch
  _ch isDigit 
  if
    _ch storeInBuffer exit
  then
  _ch [char] . =
  if
    _ch storeInBuffer exit
  then

  _ch [char] e = _ch [char] E =
  _ch [char] + = _ch [char] - = 
  or or or
  if
    _ch storeInBuffer exit
  then

  \ We have consumed one beyond the end of the number
  endNum
  _ch jParser
;

: stateInTrue  ( ch -- )
  storeInBuffer
  jBufferPos 4 =
  if endTrue then
;

: stateInFalse  ( ch -- )
  storeInBuffer
  jBufferPos 5 =
  if endFalse then
;

: stateInNull  ( ch -- )
  storeInBuffer
  jBufferPos 4 =
  if endNull then
;

0 value _ch

: stateStartDoc  ( ch -- )
  to _ch
  \ Call listener
  jStartDocument
  _ch [char] [ = if startArray exit then
  _ch [char] { = if startObj   exit then
  ." Document must start with object or array"
;

\ Reset parser in preparation for operation
: jParserReset ( -- ) 
  
  STATE_START_DOCUMENT to jState
  0 to jStackPos
  0 to jBufferPos
  0 to jCharCount
;

0 value _state

\ JSON stream parser processes a char at a time
: _jParser ( ch -- )
  to _ch

  jState to _state

  \ Valid whitespace characters in JSON include:
  \ space, tab, line feed and carriage return
  _ch $20 =
  _ch $09 =
  _ch $0A =
  _ch $0D = 
  or or or

  _state STATE_IN_STRING =
  _state STATE_START_ESCAPE =
  _state STATE_IN_NUMBER =  
  _state STATE_START_DOCUMENT =
  or or or not
  and
  if
    exit
  then

  _state
  CASE
    STATE_START_DOCUMENT OF _ch stateStartDoc   ENDOF
    STATE_IN_ARRAY       OF _ch stateInArray    ENDOF
    STATE_IN_OBJECT      OF _ch stateInObj      ENDOF
    STATE_IN_STRING      OF _ch stateInStr      ENDOF
    STATE_END_KEY        OF _ch stateEndKey     ENDOF
    STATE_AFTER_KEY      OF _ch startVal        ENDOF
    STATE_START_ESCAPE   OF _ch processEscChars ENDOF
    STATE_AFTER_VALUE    OF _ch stateAfterVal   ENDOF
    STATE_IN_NUMBER      OF _ch stateInNum      ENDOF
    STATE_IN_TRUE        OF _ch stateInTrue     ENDOF
    STATE_IN_FALSE       OF _ch stateInFalse    ENDOF
    STATE_IN_NULL        OF _ch stateInNull     ENDOF
    STATE_DONE           OF exit                ENDOF
  ENDCASE
  1 +to jCharCount
;

\ Resolve defered word
' _jParser is jParser
 


