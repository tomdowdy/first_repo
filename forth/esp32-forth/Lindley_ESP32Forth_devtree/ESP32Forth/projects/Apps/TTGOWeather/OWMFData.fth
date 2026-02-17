\
\ Parser for Open Weather Map Forecast Data
\

\ Size of various string buffers 
20 constant FKEY_LENGTH
10 constant TEMP_LENGTH
10 constant ICON_LENGTH

\ Storage for item strings
FKEY_LENGTH stringStore FKEY_BUF
TEMP_LENGTH stringStore TEMP1_BUF
TEMP_LENGTH stringStore TEMP2_BUF
TEMP_LENGTH stringStore TEMP3_BUF
TEMP_LENGTH stringStore TEMP4_BUF
ICON_LENGTH stringStore ICON1_BUF
ICON_LENGTH stringStore ICON2_BUF
ICON_LENGTH stringStore ICON3_BUF
ICON_LENGTH stringStore ICON4_BUF

\ Create string constants for key values we need
s" dt"   s"constant DT_STR
s" temp" s"constant TEMP_STR
s" icon" s"constant ICON_STR

\ jParser deferred words resolution

: owmfStartDocument ( -- )
;

: owmfEndDocument ( -- )
;

: owmfStartObject ( -- )
;

: owmfEndObject ( -- )
;

: owmfStartArray ( -- )
;

: owmfEndArray ( -- )
;

: owmfKey ( addr n -- ) 
  FKEY_BUF putString
;

\ FSM current state
0 value fsmState

\ dt offset counts for forecast day 1, 2, 3 and 4
0 value dtOffsetDay1
0 value dtOffsetDay2
0 value dtOffsetDay3
0 value dtOffsetDay4

\ Calculate the initial DT offset from the now time to 12:00:00 tomorrow
: calcInitialDTOffset ( --  )

  now toLocal hour_t ." local hr: " . cr

  \ Get the now UTC time in 24 hour format
  now hour_t 0 { hr cnt }

  ." Hour: " hr . cr

  hr  0  2 between? if 11 to cnt then    
  hr  3  5 between? if 10 to cnt then  
  hr  6  8 between? if  9 to cnt then
  hr  9 11 between? if  8 to cnt then
  hr 12 14 between? if  7 to cnt then
  hr 15 17 between? if  6 to cnt then
  hr 18 20 between? if  5 to cnt then
  hr 21 23 between? if  4 to cnt then

  cnt to dtOffsetDay1
  ." dtOffsetDay1: " cnt . cr
;


\ FSM states
 0 constant S_DT_1_FIND
 1 constant S_DT_1_TEMP
 2 constant S_DT_1_ICON

 3 constant S_DT_2_FIND
 4 constant S_DT_2_TEMP
 5 constant S_DT_2_ICON

 6 constant S_DT_3_FIND
 7 constant S_DT_3_TEMP
 8 constant S_DT_3_ICON

 9 constant S_DT_4_FIND
10 constant S_DT_4_TEMP
11 constant S_DT_4_ICON
12 constant S_DONE

\ FSM current state
0 value fsmState

\ Forecast data parser
: owmfValue { addr n }

  fsmState
  case
    S_DT_1_FIND
    of
      FKEY_BUF getString DT_STR str= 
      if 
        dtOffsetDay1 0=
        if
          S_DT_1_TEMP to fsmState
        else
          -1 +to dtOffsetDay1
        then
      then
    endof
    
    S_DT_1_TEMP
    of
      FKEY_BUF getString TEMP_STR str=
      if 
        addr n TEMP1_BUF putString
        S_DT_1_ICON to fsmState
      then
    endof
    
    S_DT_1_ICON
    of
      FKEY_BUF getString ICON_STR str=
      if 
        addr n ICON1_BUF putString
        S_DT_2_FIND to fsmState
      then
    endof
    
    S_DT_2_FIND
    of
      FKEY_BUF getString DT_STR str= 
      if 
        dtOffsetDay2 0=
        if
          S_DT_2_TEMP to fsmState
        else
          -1 +to dtOffsetDay2
        then
      then
    endof
    
    S_DT_2_TEMP
    of
      FKEY_BUF getString TEMP_STR str=
      if 
        addr n TEMP2_BUF putString
        S_DT_2_ICON to fsmState
      then
    endof
    
    S_DT_2_ICON
    of
      FKEY_BUF getString ICON_STR str=
      if 
        addr n ICON2_BUF putString
        S_DT_3_FIND to fsmState
      then
    endof
    
    S_DT_3_FIND
    of
      FKEY_BUF getString DT_STR str= 
      if 
        dtOffsetDay3 0=
        if
          S_DT_3_TEMP to fsmState
        else
          -1 +to dtOffsetDay3
        then
      then
    endof
    
    S_DT_3_TEMP
    of
      FKEY_BUF getString TEMP_STR str=
      if 
        addr n TEMP3_BUF putString
        S_DT_3_ICON to fsmState
      then
    endof
    
    S_DT_3_ICON
    of
      FKEY_BUF getString ICON_STR str=
      if 
        addr n ICON3_BUF putString
        S_DT_4_FIND to fsmState
      then
    endof
    
    S_DT_4_FIND
    of
      FKEY_BUF getString DT_STR str= 
      if 
        dtOffsetDay4 0=
        if
          S_DT_4_TEMP to fsmState
        else
          -1 +to dtOffsetDay4
        then
      then
    endof
    
    S_DT_4_TEMP
    of
      FKEY_BUF getString TEMP_STR str=
      if 
        addr n TEMP4_BUF putString
        S_DT_4_ICON to fsmState
      then
    endof
    
    S_DT_4_ICON
    of
      FKEY_BUF getString ICON_STR str=
      if 
        addr n ICON4_BUF putString
        S_DONE to fsmState
      then
    endof

    S_DONE
    of
    endof
  endcase 
;

\ Retrieve OWM data and store in structure
: gatherOWMFData cr
  \ Resolve the necessary deferred words for jParser
  ['] owmfStartDocument is jStartDocument
  ['] owmfEndDocument is jEndDocument
  ['] owmfStartObject is jStartObject
  ['] owmfEndObject is jEndObject
  ['] owmfStartArray is jStartArray
  ['] owmfEndArray is jEndArray
  ['] owmfKey is jKey
  ['] owmfValue is jValue

  \ Prepare the HTTP GET
  prepareForecastGET

  \ Initialize dt counters
  7 to dtOffsetDay2
  7 to dtOffsetDay3
  7 to dtOffsetDay4

  \ Calculate DT offset to forecast items
  calcInitialDTOffset

  \ Initial state of FSM
  S_DT_1_FIND to fsmState

  \ Execute the HTTP GET
  executeGET 
;

