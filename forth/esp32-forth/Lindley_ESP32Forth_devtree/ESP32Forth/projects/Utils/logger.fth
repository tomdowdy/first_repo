\ 
\ Logging Words
\ Read and write log files to SPIFFS or SD card
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 02/03/2022
\

\ Length of log file buffer
256 constant LOG_BUFFER_LENGTH

\ Create buffer for reading/writing log file
LOG_BUFFER_LENGTH byteArray logFileBuffer

\ Delete log file
: deleteLog ( addr n -- )
  delete-file 0=
  cr
  if
    ." File deleted"
  else
    ." File delete failed"
  then
  cr
;

\ Record log file entry
: log { fnAddr fnN leAddr leN } ( fnAddr fnN leAddr leN -- f )
  cr
  0 { fid }

  \ Attempt to open log file for appending log entry
  fnAddr fnN w/o append or open-file 0=
  if
    to fid

    leAddr leN fid write-file 0=
    if
      true
    else
      ." Error writing log entry" cr
      false
    then
    fid close-file drop
  else
    ." File open failed" cr
    false
  then  
;

\ Show the log file
: showLog ( addr n -- f ) 

  cr 0 0 false { fid bytesRead done }

  \ Attempt to open file
  r/o open-file 0=
  if
    to fid

    begin
      \ Read the log file into memory
      0 logFileBuffer LOG_BUFFER_LENGTH fid read-file 0=
      if
        to bytesRead
        \ Check for end of file
        bytesRead LOG_BUFFER_LENGTH <>
        if 
          true to done
        then

        \ Display buffer contents
        bytesRead 0
        do
          i logFileBuffer c@ emit
        loop
      else
        ." File read failed" cr
        true to done
      then
      done
    until
    fid close-file drop
  else
    drop
    ." File open failed" cr
    false
  then
;

\ Test code
\ s" /spiffs/log1" deleteLog
\ s" /spiffs/log1" deleteLog
\ s" /spiffs/log1" s" log entry 1" log . cr
\ s" /spiffs/log1" s" log entry 2" log . cr
\ s" /spiffs/log1" s" log entry 3" log . cr
\ s" /spiffs/log1" s" log entry 4" log . cr

\ s" /spiffs/log1" showLog





