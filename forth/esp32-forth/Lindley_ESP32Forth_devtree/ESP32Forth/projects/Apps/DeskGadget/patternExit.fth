\ ESP32Forth Desk Gadget - Display pattern exit support function
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/16/2022
\

\ Return values
69 constant RETURN_TIMEOUT
96 constant RETURN_TOUCH

 0 value futureTimeMS
 0 value returnReason

\ Check for pattern display exit from either timeout or touch
: checkForExit ( -- f )

  MS-TICKS futureTimeMS >
  if
    RETURN_TIMEOUT to returnReason
    true
    exit
  then

  getTouchPoint
  if
    RETURN_TOUCH to returnReason
    true
    exit
  then
  false
;

