\
\ A simple buffer formatter like strcat
\ Used to build time and date and URL strings
\

\ Size of format buffer
\ Large size need for URL formatting
180 constant FORMAT_BUFFER_SIZE

\ Create format buffer
FORMAT_BUFFER_SIZE byteArray FORMAT_BUFFER

\ Index into format buffer for adding next string
0 value indx

\ Clear the format buffer
: clearFormatBuffer ( -- )

  0 FORMAT_BUFFER FORMAT_BUFFER_SIZE erase
  0 to indx
;

\ Add a char into the format buffer
: addChar ( ch -- )
  indx FORMAT_BUFFER c!
  1 +to indx
;

\ Add a space character for formatting
: addSpace 
  32 addChar
;

\ Add a CR character for formatting
: addCR 
  13 addChar
;

\ Add a LF character for formatting
: addLF 
  10 addChar
;

\ Add a string into the format buffer
: addString  ( addr n -- )  
  indx FORMAT_BUFFER ( addr n -- addr n dAddr )
  swap dup >r
  cmove
  r> +to indx
;

\ Add a single number into the format buffer
: addNumber ( n -- )
  str addString
;

\ Show the string currently in the format buffer
: showFormatBufferString
  cr
  0 FORMAT_BUFFER indx type
  cr
;

\ Retrieve the string currently in the format buffer
: getFormatBufferString ( -- addr n )
  0 FORMAT_BUFFER indx
;

