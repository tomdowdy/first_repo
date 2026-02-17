\ Prepare Open Weather Map HTTP GET


\ User Parameters - Change these for your situation
\ CITYID for Colorado Springs Colorado
: CITYID s" 5417598" ;
: APPID  s" 512f63fc90533134388edda77e7beaf5 " ;
: UNITS  s" imperial" ;
: HOST   s" craigandheather.net" ;

\ Buffer for GET
        170 constant BUFFER_SIZE
BUFFER_SIZE byteArray Buffer

0 value _index_

: addString ( addr n -- )
  dup >r
  _index_ Buffer swap cmove
  r> +to _index_
;

: addChar ( ch -- )
  _index_ Buffer c!
  1 +to _index_
;


\ Prepare GET to retrieve current weather conditions
: prepareCurrentConditionsGET

  \ Initialize buffer variables
  0 Buffer BUFFER_SIZE erase
  0 to _index_

  s" GET /data/2.5/weather?id=" addString CITYID addString
  s" &units=" addString UNITS addString
  s" &APPID=" addString APPID addString
  s" HTTP/1.1" addString
  13 addChar
  10 addChar
  s" Host: " addString HOST addString
  13 addChar
  10 addChar
  s" Content-Type: application/json" addString
  13 addChar
  10 addChar
  13 addChar
  10 addChar
;

\ Show the GET string currently in Buffer
: showGET
  0 Buffer _index_ type cr
;

\ Get reference to GET string currently in Buffer
: getGET ( -- addr n )
  0 Buffer _index_ 
;

\ Execute prepared GET. Code assumes:
\ 1. Logged in to WiFI
\ 2. GET has been prepared
\ 3. jParser deferred words have ben resolved

Networking

\ Buffer for reading a char at a time
variable recvBuffer

0 value handle
0 value onetime
0 value res

: executeGET ( -- )

  \ Reset the JSON parser
  jParserReset

  0 recvBuffer !

  true to onetime

  TCP z" api.openweathermap.org" 80 Net.Connect to handle
  handle 3000 Net.receiveTimeoutMS!
  handle 3000 Net.readTimeoutMS!

  handle 0 >
  if
    \ Do the GET
    handle getGET Net.tcpWrite ERR_OK =
    if
      begin
        handle recvBuffer 1 Net.Read drop
        recvBuffer c@ [char] { =
      until
      begin
        onetime
        if
          false to onetime
          [char] { recvBuffer c!
        else
          handle recvBuffer 1 Net.Read to res
          res 1 <
          if ." res: " res . cr exit then
        then
        recvBuffer c@ jParser
        false
      until
    then
    handle Net.Dispose
  then
;

Forth


