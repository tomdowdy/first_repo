\ Lines test program
\ Proved initializedArray and random0toN functions as
\ well as a check on line drawing performance
\ Craig A. Lindley 08/09/2021

\ Put predefined colors into colors array 
RED YEL GRN BLU CYA MAG WHT 7 initializedArray colors


50 constant LINE_COUNT

: lines
  LINE_COUNT 0
  do
    240 random0toN \ x0
    135 random0toN \ y0
    240 random0toN \ x1
    135 random0toN \ y1
      7 random0toN colors
    line
  loop
;

: run 3 initLCD clearLCD lines ;

\ Run the app
run
