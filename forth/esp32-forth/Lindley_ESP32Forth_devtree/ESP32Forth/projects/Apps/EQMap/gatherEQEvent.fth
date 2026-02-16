\ Get the Earth Quake Event Data via an HTTPS GET
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 09/10/2021

\ Sizes of the various string buffers needed
20 constant KEY_LENGTH
20 constant ID_LENGTH
10 constant LON_LENGTH
10 constant LAT_LENGTH
10 constant MAG_LENGTH
50 constant LOC_LENGTH

\ Storage for item strings
KEY_LENGTH stringStore KEY_BUF
ID_LENGTH  stringStore NEW_ID_BUF
ID_LENGTH  stringStore OLD_ID_BUF
LON_LENGTH stringStore LON_BUF
LAT_LENGTH stringStore LAT_BUF
MAG_LENGTH stringStore MAG_BUF
LOC_LENGTH stringStore LOC_BUF

\ jParser deferred words to be resolved

: eqeStartDocument ( -- ) ;

: eqeEndDocument ( -- ) ;

: eqeStartObject ( -- ) ;

: eqeEndObject ( -- ) ;

: eqeStartArray ( -- ) ;

: eqeEndArray ( -- ) ;

: eqeKey ( addr n -- )
  KEY_BUF putString
;

\ Create string constants for key values we need
s" id"  s"constant IDStr
s" lon" s"constant LONStr
s" lat" s"constant LATStr
s" mag" s"constant MAGStr
s" flynn_region" s"constant LOCStr

: eqeValue ( addr n -- )

  \ Extract the following items from JSON script
  KEY_BUF getString IDStr  str= if NEW_ID_BUF putString exit then
  KEY_BUF getString LONStr str= if LON_BUF    putString exit then
  KEY_BUF getString LATStr str= if LAT_BUF    putString exit then
  KEY_BUF getString MAGStr str= if MAG_BUF    putString exit then
  KEY_BUF getString LOCStr str= if LOC_BUF    putString exit then
  2drop
;

\ Resolve the necessary deferred words for jParser
' eqeStartDocument is jStartDocument
' eqeEndDocument is jEndDocument
' eqeStartObject is jStartObject
' eqeEndObject is jEndObject
' eqeStartArray is jStartArray
' eqeEndArray is jEndArray
' eqeKey is jKey
' eqeValue is jValue


\ Buffer for holding JSON EQ event data
700 constant EVENT_BUFFER_SIZE

EVENT_BUFFER_SIZE byteArray EVENT_BUFFER


HTTP

: getEvent ( -- f )
  \ Clear buffer in preparation
  0 EVENT_BUFFER EVENT_BUFFER_SIZE erase

  \ URL of data source
  z" https://www.seismicportal.eu/fdsnws/event/1/query?limit=1&format=json" HTTP.begin 
  if
    HTTP.doGet 0 >
    if 
      0 EVENT_BUFFER 700 HTTP.getPayload
      HTTP.end
      true
      exit
    else
      ." doGet returned error" cr
      HTTP.end      
      false
      exit
    then
  else
    ." HTTP begin failed" cr
    false
    exit
  then  
;

Forth

\ Run the JSON parser on the EQ event data
: runParser ( -- )
  \ Reset the parser
  jParserReset

  0 EVENT_BUFFER z"len 0
  do
    i EVENT_BUFFER c@ jParser
  loop
;

\ Check to see if a new event has been reported
: checkNewEvent ( -- f )
  OLD_ID_BUF getString NEW_ID_BUF getString str=
  if
    false
  else
    NEW_ID_BUF getString OLD_ID_BUF putString
    true
  then
;


