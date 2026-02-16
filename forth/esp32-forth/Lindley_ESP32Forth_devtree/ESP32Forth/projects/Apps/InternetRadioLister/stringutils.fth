
\ String Utilities

\ Constants for accessing string store
0 constant capOffset
1 constant lenOffset
2 constant bufOffset

\ String constant that keeps addr n of string available
: s"constant ( addr n -- ) ( -- addr n ) create c, , does> dup c@ swap 1+ @ swap ;

\ String storage - creates space for capacity size string, the capacity itself
\ and the current len of stored string
: stringStore ( capacity -- ) ( "name" -- addr )
  create dup c, 1+ allot does> ; 

\ Put an s" string into a named string store
: putString ( addr n "name" -- )
  >r
  r@ 1+ r@ c@ erase
  dup
  r@ lenOffset + c!
  r> bufOffset + swap cmove
;

\ Retrieve an s" string from a named string store
: getString ( "name" -- addr n )
  >r
  r@ bufOffset + 
  r> lenOffset + c@
;

