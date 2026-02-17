\ String Table Code
\
\ Last Update: 04/17/2023
\

\ Given address of a counted string return its address and length
: count ( addr -- addr n )
  dup
  1+ swap c@
;

\ Start definition of named stringtable
: startStringTable  ( name -- stdata ) ( n -- addr n )
  create
    here
    cell allot
    here
  does>
    @ 
    swap cells + 
    @ count  
;

\ Add a double quote delimited string to the stringtable
: +"  ( "ccc<quote>" -- = Parse ccc delimited by double quote and place the string as counted string in the stringtable )
  [char] " parse 
  here 
  over 1+ allot
  2dup c!
  1+ swap cmove
  align
;

\ End definition of stringtable and log string addresses
: endStringTable  ( stData -- )
  here rot !
  here swap
  BEGIN
    2dup <>
  WHILE
    dup ,           \ Store the start of the strings
    count + aligned \ Move to the next string
  REPEAT
  2drop
;

\ Test Code Example

\ startStringTable months 
\  +" January" +" February" +" March" +" April" 
\  +" May" +" June" +" July" +" August" +" September" 
\  +" October" +" November" +" December"
\ endStringTable
\
\ Fetch strings from the stringtable
\
\ 0 months type cr \ January
\ 11 months type cr \ December
