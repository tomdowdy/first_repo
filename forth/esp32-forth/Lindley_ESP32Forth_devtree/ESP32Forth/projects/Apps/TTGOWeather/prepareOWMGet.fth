\ Prepare Open Weather Map HTTP GETs

\ Prepare GET to retrieve current weather conditions
: prepareCurrentConditionsGET

  \ Clear the format buffer
  clearFormatBuffer

  s" GET /data/2.5/weather?zip=" addString ZIPCODE addString
  s" &units=" addString UNITS addString
  s" &APPID=" addString APIKEY addString
  s" HTTP/1.1" addString
  addCR
  addLF
  s" Host: " addString HOST addString
  addCR
  addLF
  s" Content-Type: application/json" addString
  addCR
  addLF
  addCR
  addLF
;

\ Prepare GET to retrieve 5 day forecast weather conditions
: prepareForecastGET

  \ Clear the format buffer
  clearFormatBuffer

  s" GET /data/2.5/forecast?zip=" addString ZIPCODE addString
  s" &units=" addString UNITS addString
  s" &APPID=" addString APIKEY addString
  s" HTTP/1.1" addString
  addCR
  addLF
  s" Host: " addString HOST addString
  addCR
  addLF
  s" Content-Type: application/json" addString
  addCR
  addLF
  addCR
  addLF
;

\ Execute prepared GET. Code assumes:
\ 1. Logged in to WiFI
\ 2. GET has been prepared
\ 3. jParser deferred words have been resolved

Networking

\ Buffer for reading a char at a time
variable recvBuffer

: executeGET ( -- )

  0 true 0 false { handle onetime res done }

  \ Reset the JSON parser
  jParserReset

  0 recvBuffer !

  TCP z" api.openweathermap.org" 80 Net.Connect to handle
  handle 500 Net.receiveTimeoutMS!
  handle 3000 Net.readTimeoutMS!

  handle 0 >
  if
    \ Do the GET
    handle getFormatBufferString Net.tcpWrite ERR_OK =
    if
      begin
        handle recvBuffer 1 Net.Read drop
        recvBuffer c@ [char] { =
      until

      begin
        onetime
        if
          false to onetime
          [char] { jParser
        else
          handle recvBuffer 1 Net.Read to res
          res 1 =
          if
            \ Read a char so store it
            recvBuffer c@ jParser 
          else 
            ." res: " res . cr
            handle Net.Dispose
            true to done
          then
        then
        done
      until
    else    
      ." TCP write error" cr
    then
  else
    ." Bad handle" cr  
    handle Net.Dispose
  then
;

Forth
