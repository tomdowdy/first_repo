\ HTTPS Test

WiFi

: doLogin z" CraigNet" z" craigandheather" login 1000 ms ;

Forth

   0 value     fid
1400 byteArray cert
1000 byteArray buffer

: readCert ( -- f )
  \ Attempt to open cert file
  s" /spiffs/seismicportal-cert.pem" r/o open-file 0=
  if
    to fid
  else
    ." File open failed" cr
    false
    exit
  then

  \ Read cert into buffer
  0 cert 1400 fid read-file 0=
  if
    \ Terminate cert string 
    cert 0 swap c!
  else
    ." File read failed" cr
    fid close-file drop
    false
    exit
  then
  fid close-file drop
  true
;
  
: showCert
  0 cert z>s type
;

HTTPS

: run 
  cr
  readCert ." Read cert result: " . cr
\  showCert
  0 cert HTTPS.setCert
  z" https://seismicportal.eu/fdsnws/event/1/query?limit=1&format=text" HTTPS.begin 
  if ." H1" cr
    HTTPS.doGet dup ." Get results: " . cr 0 >
    if ." H2" cr
      0 buffer 1000 HTTPS.getPayload
      0 buffer z>s type
    then
  then

  HTTPS.end
;

