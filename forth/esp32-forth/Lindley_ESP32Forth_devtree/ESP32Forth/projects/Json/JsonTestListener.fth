\ JSON Streaming Listener Words Example
\ Based on: https://github.com/squix78/json-streaming-parser
\ This needs to be implemented for each Json application
\ Written by: Craig A. Lindley
\ Last Update: 08/25/2021

\ jParser callbacks

: _jStartDocument ( -- )
  ." start document" cr
;

: _jEndDocument ( -- )
  ." end document" cr
;

: _jStartObject ( -- )
  ." start object" cr
;

: _jEndObject ( -- )
  ." end object" cr
;

: _jStartArray ( -- )
  ." start array" cr
;

: _jEndArray ( -- )
  ." end array" cr
;

: _jKey ( addr n -- )
  ." key: " type cr
;

: _jValue ( addr n -- )
  ." value: " type cr
;

\ Resolve the necessary deferred words for the jParser
' _jStartDocument is jStartDocument
' _jEndDocument is jEndDocument
' _jStartObject is jStartObject
' _jEndObject is jEndObject
' _jStartArray is jStartArray
' _jEndArray is jEndArray
' _jKey is jKey
' _jValue is jValue


\ Define your application code here
: testJApp  ( -- )

  cr

  \ Reset the JSON parser
  jParserReset

  s' {"a":3, "b":{"c":"d"}}'

\  s' {"widget": {
\    "debug": "on",
\    "window": {
\        "title": "Sample Konfabulator Widget",
\        "name": "main_window",
\        "width": 500,
\        "height": 500
\    },
\    "image": { 
\        "src": "Images/Sun.png",
\        "name": "sun1",
\        "hOffset": 250,
\        "vOffset": 250,
\        "alignment": "center"
\    }
\ }}'


  ( -- addr count )
  { addr count }

  count 0
  do
    addr i + c@ dup ." char: " . cr
    jParser
  loop
;





