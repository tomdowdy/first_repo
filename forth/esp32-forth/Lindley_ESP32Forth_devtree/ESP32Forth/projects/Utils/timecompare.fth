
\
\ ESP32Forth Time Compare Words
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/28/2022
\

\ Convert time components to minutes since midnight
: timeToMins { hrs mins isAm } ( hrs mins isAm -- n )
  isAm
  if \ AM
    hrs 12 =
    if
      0 to hrs
    then
  else \ PM
    hrs 12 <
    if
      12 +to hrs
    then
  then
  hrs 60 * mins +
;

\ Compare times
\ Returns true flag if t1 <= t2
: timeCompare { t1Hrs t1Mins t1isAm t2Hrs t2Mins t2isAm }
  t1Hrs t1Mins t1isAm timeToMins
  t2Hrs t2Mins t2isAm timeToMins
  <
;
