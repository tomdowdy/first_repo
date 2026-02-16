\
\ Parser for Open Weather Map Current Conditions Data
\

\ Size of various string buffers 
20 constant CCKEY_LENGTH
20 constant SUNRISE_LENGTH
20 constant SUNSET_LENGTH
10 constant TEMP_LENGTH
10 constant HUMIDITY_LENGTH
10 constant SPEED_LENGTH
10 constant ICON_LENGTH
30 constant CITY_LENGTH

\ Storage for item strings
CCKEY_LENGTH    stringStore CCKEY_BUF
SUNRISE_LENGTH  stringStore SUNRISE_BUF
SUNSET_LENGTH   stringStore SUNSET_BUF
TEMP_LENGTH     stringStore TEMP_BUF
HUMIDITY_LENGTH stringStore HUM_BUF
SPEED_LENGTH    stringStore SPEED_BUF
ICON_LENGTH     stringStore ICON_BUF
CITY_LENGTH     stringStore CITY_BUF

\ Create string constants for key values we need
s" sunrise"  s"constant SUNRISE_STR
s" sunset"   s"constant SUNSET_STR
s" temp"     s"constant TEMP_STR
s" humidity" s"constant HUM_STR
s" speed"    s"constant SPEED_STR
s" icon"     s"constant ICON_STR
s" name"     s"constant NAME_STR

\ jParser deferred words resolution

: owmccStartDocument ( -- ) ;

: owmccEndDocument ( -- ) ;

: owmccStartObject ( -- ) ;

: owmccEndObject ( -- ) ;

: owmccStartArray ( -- ) ;

: owmccEndArray ( -- ) ;

: owmcckey ( addr n -- )
  CCKEY_BUF putString
;

\ Current conditions data parser
: owmccValue ( addr n -- )

  CCKEY_BUF getString SUNRISE_STR str= if SUNRISE_BUF putString exit then
  CCKEY_BUF getString SUNSET_STR  str= if SUNSET_BUF  putString exit then
  CCKEY_BUF getString TEMP_STR    str= if TEMP_BUF    putString exit then
  CCKEY_BUF getString HUM_STR     str= if HUM_BUF     putString exit then
  CCKEY_BUF getString SPEED_STR   str= if SPEED_BUF   putString exit then
  CCKEY_BUF getString ICON_STR    str= if ICON_BUF    putString exit then
  CCKEY_BUF getString NAME_STR    str= if CITY_BUF    putString exit then
  2drop
;

\ Retrieve OWM data and store in structure
: gatherOWMCCData
  \ Resolve the necessary deferred words for jParser
  ['] owmccStartDocument is jStartDocument
  ['] owmccEndDocument is jEndDocument
  ['] owmccStartObject is jStartObject
  ['] owmccEndObject is jEndObject
  ['] owmccStartArray is jStartArray
  ['] owmccEndArray is jEndArray
  ['] owmcckey is jKey
  ['] owmccValue is jValue

  \ Prepare the HTTP GET
  prepareCurrentConditionsGET

  \ Execute the HTTP GET
  executeGET
;

