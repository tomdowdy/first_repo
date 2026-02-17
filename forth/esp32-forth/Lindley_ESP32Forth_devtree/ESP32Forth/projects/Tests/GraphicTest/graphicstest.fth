

: run
  
  \ Initialize display
  RA8876.begin not
  if ." Problem initializing display" exit else ." Success" cr then
  clearScreen

  50 50 12 5 drawFilledCircle


;
 



