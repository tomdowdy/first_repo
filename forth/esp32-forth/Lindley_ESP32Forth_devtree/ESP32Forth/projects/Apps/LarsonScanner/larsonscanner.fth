\ ESP32 Larson Scanner of ws2812 NeoPixels
\ Written in ESP32forth
\ Written by: Craig A. Lindley
\ Last Update: 08/25/2021

WS2812

: init
  \ Initialize the RMT driver
  WS2812_PIN WS2812.begin

  \ Clear the pixel data
  true clearPixels
;

: scanner

  \ Do 10 times
  10 0
  do 
    \ Scan up
    WS2812_COUNT 0
    do
      0 0 128 i setPixelRGB
      show
      100 MS
      true clearPixels
    loop

    0 WS2812_COUNT
    do
      0 0 128 i setPixelRGB
      show
      100 MS
      true clearPixels
    -1 +loop
  loop
;

Forth
      

