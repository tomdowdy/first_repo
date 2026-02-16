
0 value len

\ Get length of z" string
: zStrLen ( addr -- n)
  0 to len
  begin
    dup      ( addr -- addr addr )
    c@  ( addr addr -- addr ch )
    0 <>  ( addr ch -- addr f )
    if     ( addr f -- addr )
      1 +to len
      1+     ( addr -- addr + 1 )
      false
    else
      drop
      true
    then
  until
  len
;
