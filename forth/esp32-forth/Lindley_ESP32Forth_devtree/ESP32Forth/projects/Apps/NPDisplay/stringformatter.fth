\ String Formatting Functions
\ Written in ESP32Forth
\ Written By: Craig A. Lindley
\ Last Update: 09/24/2022

\ Format buffer
50 byteArray FORMAT_BUFFER
 0 value indx

\ Copy a string into format buffer
: _cat  ( addr count -- )
  indx FORMAT_BUFFER ( addr count -- addr count dAddr )
  swap dup >r
  cmove
  r> +to indx
;

: $cat ( addr n -- )
  _cat
;

2 byteArray SPACE_BUFFER
$20 0 SPACE_BUFFER !

\ Add a space character for formatting
: addSpace
  0 SPACE_BUFFER 1 _cat
;

\ Convert single number >= 0 to a string
: #to$ ( n -- addr count )
  <# #s #>
;

