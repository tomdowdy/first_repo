\ Hardware Description for 7 Segment Display

\ GPIO pin definitions
25 constant PB_SW
18 constant WS2812_PIN

\ LED count
29 constant WS2812_COUNT

\ Segments Array
\ This maps the unusual physical wiring between
\ the WS2812 LEDs in the display and indices
\ they are assigned.
\ index 0 is the middle LED separator between the
\ two sets of two 7 segment displays.
\ The 7 segment displays are numbered 0 .. 3 from left to right
\ Indices 1  ..  7 are the a b c d e f g segments for display 0
\ Indices 8  .. 14 are the a b c d e f g segments for display 1
\ Indices 15 .. 21 are the a b c d e f g segments for display 2
\ Indices 22 .. 28 are the a b c d e f g segments for display 3

27 28 22 26 25 23 24
20 21 15 19 18 16 17
12 13  7 11 10  8  9
 0  6  1  5  4  2  3 
14
29 
initializedArray segmentsArray
