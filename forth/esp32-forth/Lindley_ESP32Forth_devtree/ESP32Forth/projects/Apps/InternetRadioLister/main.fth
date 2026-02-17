\ Internet Radio Lister
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 11/11/2022

\ Working radio-browser servers
s" nl1.api.radio-browser.info" s"constant RBServer1
s" de1.api.radio-browser.info" s"constant RBServer2
s" fr1.api.radio-browser.info" s"constant RBServer3


\ Buffer for building URL
80 constant URL_BUFFER_SIZE
URL_BUFFER_SIZE byteArray URLBuffer

0 value _index_

: addString ( addr n -- )
  dup >r
  _index_ URLBuffer swap cmove
  r> +to _index_
;

: addChar ( ch -- )
  _index_ URLBuffer c!
  1 +to _index_
;

\ Prepare GET to retrieve radio stations by genre
: prepareRSLGET ( addr n -- )

  \ Initialize buffer variables
  0 URLBuffer URL_BUFFER_SIZE erase
  0 to _index_

  s" GET /json/stations/bytag/" addString 
  \ Add genre string
  addString
  s" ?hidebroken=true" addString
  s" HTTP/1.1" addString
  13 addChar
  10 addChar
  13 addChar
  10 addChar
;

\ Show the GET string currently in Buffer
: showGET
  cr 0 URLBuffer _index_ type cr
;

\ Get reference to GET string currently in Buffer
: getGET ( -- addr n )
  0 URLBuffer _index_ 
;

\ Key storage length
100 constant KEY_LENGTH

\ Storage for key
KEY_LENGTH stringStore KEY_BUF

\ Create string constants for key values we need
s" name"         s"constant NAMEStr
s" url_resolved" s"constant URLStr
s" country"      s"constant COUNTRYStr
s" codec"        s"constant CODECStr
s" bitrate"      s"constant BITRATEStr

\ jParser deferred words to be resolved

: irlStartDocument ( -- ) ;

: irlEndDocument ( -- ) exit ;

: irlStartObject ( -- ) ;

: irlEndObject ( -- ) ;

: irlStartArray ( -- ) ;

: irlEndArray ( -- ) ;

: irlKey ( addr n -- )
  KEY_BUF putString
;

: irlValue ( addr n -- ) 

  \ Extract the following items from JSON script
  KEY_BUF getString NAMEStr    str= if s" Name: "     type type exit then
  KEY_BUF getString URLStr     str= if s"  URL: "     type type exit then
  KEY_BUF getString COUNTRYStr str= if s"  COUNTRY: " type type exit then
  KEY_BUF getString CODECStr   str= if s"  CODEC: "   type type exit then
  KEY_BUF getString BITRATEStr str= if s"  BITRATE: " type type cr exit then
  2drop
;

\ Resolve the necessary deferred words for jParser
' irlStartDocument is jStartDocument
' irlEndDocument is jEndDocument
' irlStartObject is jStartObject
' irlEndObject is jEndObject
' irlStartArray is jStartArray
' irlEndArray is jEndArray
' irlKey is jKey
' irlValue is jValue

WiFi

: login z" CraigNet" z" craigandheather" login 1000 ms ;

Forth

\ Code assumes:
\ 1. Logged in to WiFI
\ 2. GET has been prepared
\ 3. jParser deferred words have ben resolved

Networking

\ Buffer for reading a char at a time
variable recvBuffer

0 value handle
0 value res

: stationsByGenre ( addr u -- )

  \ Prepare GET
  prepareRSLGET

  \ Show prepared GET 
  \ showGET

  \ Reset the JSON parser
  jParserReset

  0 recvBuffer !
  0 to handle

  TCP RBServer1 s>z 80 Net.Connect to handle
  handle 3000 Net.receiveTimeoutMS!
  handle 3000 Net.readTimeoutMS!

  handle 0 >
  if 
    \ Do the GET
    handle getGET Net.tcpWrite ERR_OK =
    if 
      begin
        handle recvBuffer 1 Net.Read to res
        res 1 <
        if ." res: " res . cr exit then
        recvBuffer c@ jParser
        false
      until
    else
      ." tcpWrite error" cr
    then
    handle Net.Dispose
  then
;

Forth

\ Music Genres
\ 60s, 70s, 80s, 90s, metal, rock, pop, disco, trance, techno, house, dance, reggae
\ funk, top, synth, fantasy, rain, ambient, meditation, lounge, chill

\ Execute the code like this
\ login (done just once)
\ s" rock" stationsByGenre




