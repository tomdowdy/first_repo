\ WS2812 support functions
\ Written in ESP32Forth
\ Written by: Craig A. Lindley
\ Last Update: 09/11/2022

\ Bring in vocabulary
WS2812 

\ Define an array of pixel values
\ Three bytes are required for each WS2812 pixel
WS2812_COUNT 3 * byteArray pixels

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

\ Set pixel using a 24 bit color value
: setPixelColor24 ( color24 pixelNum -- )
  >r              ( color24 pixelNum -- color24 )
  dup dup         ( color24 -- color24 color24 color24 )  
  16 >> 255 and   ( color24 color24 color24 -- color24 color24 R )
  -rot            ( color24 color24 R -- color24 R color24 )
  8 >> 255 and    ( color24 R color24 -- color24 R G )
  -rot            ( color24 R G -- R G color24 )  
  255 and         ( R G color24 -- R G B )
  r>              ( R G B -- R G B pixelNum )
  setPixelRGB     ( R G B pixelNum -- )
;

\ Show the WS2812 pixels
: show  ( -- )
  0 pixels WS2812_COUNT WS2812.show
;

\ Set all pixel data to zero and conditionally push
\ data to the WS2812 strip
: clearPixels  ( showFlag -- )
  0 pixels WS2812_COUNT 3 * 0 fill
  if show then
;

\ Setup the WS2812 pixel strip
: WS2812.setup WS2812_PIN WS2812.begin true clearPixels ;

Forth