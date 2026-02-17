\ ESP32 WS2812 NeoPixel Driver
\
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 08/16/2023

\ NeoPixel LED control
18 constant WS2812_PIN
15 constant WS2812_COUNT

\ Bring in vocabulary
WS2812 

\ Define an array of pixel values
\ Three bytes are required for each WS2812 pixel
WS2812_COUNT 3 * byteArray pixels

\ Initialize WS2812 library
: initWS2812
  WS2812_PIN WS2812.begin
;

\ Set a pixel in the pixel array to an RGB color value
\ pixelNum 0 .. MAX_PIXELS
\ red grn blu are 8 bit values
\ Assume color order of GRB
: setPixelRGB   ( r g b n -- )
  3 * pixels    ( r g b n -- r g b addr )
  >r            ( r g b addr -- r g b )
  swap r@    c! ( r g b -- r b )
  swap r@ 1+ c! ( r b -- b )
  r> 2 +     c! ( b -- )
;

\ Show the WS2812 pixels
: showPixel  ( -- )
  0 pixels WS2812_COUNT WS2812.show
;

Forth

