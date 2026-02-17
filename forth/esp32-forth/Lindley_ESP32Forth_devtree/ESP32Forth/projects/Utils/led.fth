\ 
\ Onboard LED control words
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 02/03/2022
\

\ GPIO pin controlling onboard LED
2 constant BUILTIN_LED

\ Initialization for operation
: initLED
  BUILTIN_LED OUTPUT pinMode
;

\ Turn onboard LED on
: LED_ON
  BUILTIN_LED HIGH digitalWrite
;

\ Turn onboard LED off
: LED_OFF
  BUILTIN_LED LOW digitalWrite
;

\ Do the LED initialization
initLED
