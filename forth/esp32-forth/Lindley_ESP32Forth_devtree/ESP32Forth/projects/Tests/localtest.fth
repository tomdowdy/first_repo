
: bytearray ( size -- ) ( i -- addr ) create allot does> + ;


\ Define an array of pixel values
\ Three bytes are required for each pixel
10 3 * bytearray pixels

\ Set a pixel to an RGB color value
\ pixelNum 0 .. MAX_PIXELS
\ red grn blu are 8 bit values
\ Assume color order of GRB 
: setPixelRGB  { red grn blu pixelNum -- }
  pixelNum 3 * pixels >r
  grn r@     c!
  red r@ 1+  c!
  blu r> 2 + c!
;

\ Convert indiviual RGB color components into 24 bit color 
: color24  { r g b }
  r 16 <<
  g  8 <<
  b 
  or or
;

\ Set pixel using a 24 bit color value
: setPixelColor  { color24 pixelNum }
  color24 16 >> 255 and
  color24  8 >> 255 and
  color24       255 and
  pixelNum setPixelRGB
;

