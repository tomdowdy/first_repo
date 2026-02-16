\ memmove test

10 constant ARRAY_SIZE

create myarray 10 c, 11 c, 12 c, 13 c, 14 c, 15 c, 16 c, 17 c, 18 c, 19 c,


: showArray
  cr
  ARRAY_SIZE 0
  do
    i ." Index: " . ."  Val: " i myarray + c@ . cr
  loop
;


: shiftLeft
  myarray 1 + myarray array_size  memmove
  100 myarray array_size 1- + c!
;

: shiftRight
  myarray myarray 1+ array_size  memmove
  100 myarray c!
;

   


