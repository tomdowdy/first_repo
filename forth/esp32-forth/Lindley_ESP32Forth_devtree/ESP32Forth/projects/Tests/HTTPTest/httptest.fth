\ HTTP Test to Earthquake Site WORKS !

WiFi

: doLogin z" CraigNet" z" craigandheather" login 1000 ms ;

Forth

700 byteArray buffer

0 buffer 700 erase

HTTP

: run 
  cr
  z" https://www.seismicportal.eu/fdsnws/event/1/query?limit=1&format=json" HTTP.begin 
  if
    HTTP.doGet dup ." Get results: " . cr 0 >
    if 
      0 buffer 700 HTTP.getPayload
      0 buffer z>s dup . cr type
    then
  then

  HTTP.end
;

