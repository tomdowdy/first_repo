\ String Table Functions
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 08/26/2021

\ Define required/maximum storage for strings
50 constant NUM_OF_STRS
20 constant MAX_STR_LEN

\ Create string array
NUM_OF_STRS MAX_STR_LEN * byteArray STRARRAY

\ Current string index
0 value _indx

\ Given a string index return address in string array
: stringAddressFromIndex ( index -- offset )
  MAX_STR_LEN * 0 STRARRAY +
;

\ Initialize string table for use
: stInit
  0 to _indx
  0 STRARRAY NUM_OF_STRS MAX_STR_LEN * erase
;

\ Add a s" string to the array
: stAdd { addr n } ( addr n -- index | -1 )
  _indx NUM_OF_STRS <
  if
    _indx stringAddressFromIndex ( -- addrd )
    dup        ( addrd -- addrd addrd )
    n swap c!  ( addrd addrd -- addrd )
    addr       ( addrd -- addrd addrs )
    swap       ( addrd addrs -- addrs addrd )
    1+         ( addrs addrd -- addrs addrd+1 )
    n          ( addrs addrd+1 -- addrs addrd+1 n )
    cmove      ( addrs addrd+1 n -- )
    1 +to _indx
    _indx 1-
  else
    ." String array full" cr
    -1
  then
;

\ Return address of s" string at specified index
: stGet { index } ( index -- addr n )
  index _indx <
  if
    index stringAddressFromIndex ( -- addrs )
    dup            ( addrs -- addrs addrs )
    c@             ( addrs addrs -- addrs n )
    swap 1+ swap   ( addrs n -- addr n )
  else
    ." String index out of range" cr
  then
;

\ Show s" string at specified index
: stShow { index } 
  index _indx <
  if 
    cr index stGet ." '" type ." '" cr
  else
    ." String index out of range" cr
  then
;







