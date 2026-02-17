\ Compare two s" strings
: s$= { addr1 n1 addr2 n2 } ( addr1 n1 addr2 n2 -- f )

  TRUE { f }

  \ Equal strings must have equal lengths
  n1 n2 =
  if
    \ Len's are equal so check content
    n1 0
    do
      addr1 i + c@ addr2 i + c@ <>
      if 
        FALSE to f
        leave
      then
    loop
  else
    FALSE to f  
  then
  f
;

