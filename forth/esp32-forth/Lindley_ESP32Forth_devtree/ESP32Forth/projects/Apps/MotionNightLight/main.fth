\ ESP32 Motion Night Light Application
\
\ This program creates a night light that hangs in a laser cut lamp 
\ that looks like a hot air balloon containing 35 NeoPixels. 
\
\ When motion is detected the ESP32 wakes up and turns all NeoPixels white.
\ Then after a short delay the NeoPixels change to another randomly picked
\ color and after another short delay all NeoPixels are turned off and the
\ ESP32 goes back to sleep.
\
\ Hardware:
\  ESP32 Dev Board
\  NeoPixel Ring with 32 LEDs
\  LED strip with 3 LEDs
\
\ Concept, Design and Implementation By: Craig A. Lindley
\ Last Update: 06/03/2024

12 constant NUMBER_OF_COLORS

20000 constant WHITE_LIGHT_DELAY_MS
 5000 constant COLOR_LIGHT_DELAY_MS
  100 constant LED_DELAY_MS
    2 constant FADE_DELAY_MS

\ Misc Functions

\ Pick a random color
: getARandomColor ( -- color24 )

  0 { theColor }

  NUMBER_OF_COLORS random0ToN
  CASE
    \ Amber
    0 OF 255 100 0 color24 to theColor ENDOF

    \ Aqua
    1 OF 50 255 255 color24 to theColor ENDOF

    \ Blue
    2 OF 0 0 255 color24 to theColor ENDOF

    \ Cyan
    3 OF 0 255 255 color24 to theColor ENDOF

    \ Gold
    4 OF 255 222 30 color24 to theColor ENDOF

    \ Green
    5 OF 0 255 0 color24 to theColor ENDOF

    \ Jade
    6 OF 0 255 40 color24 to theColor ENDOF

    \ Old Lace
    7 OF 253 245 230 color24 to theColor ENDOF

    \ Orange
    8 OF 255 40 0 color24 to theColor ENDOF

    \ Purple
    9 OF 180 0 255 color24 to theColor ENDOF

    \ Yellow
    10 OF 255 150 0 color24 to theColor ENDOF

    \ Red
    11 OF 255 0 0 color24 to theColor ENDOF
  ENDCASE

  \ Return the selected color
  theColor
;

\ Set all LEDs to a specified color with possible show delay
: setAllLEDsToAColor { color doDelay } ( color doDelay -- )
  
  WS2812_COUNT 0
  do
    \ Set an LED
    color i setPixelColor24

    \ Show the LEDs
    showPixels

    doDelay
    if 
      \ Short delay
      LED_DELAY_MS delay
    then
  loop
;

\ Fade between colors
: fadeBetweenColors { startColor endColor fadeDelayMS }

  0 0 0 { red grn blu }

  startColor 16 >> 255 and { startRed }
  startColor  8 >> 255 and { startGreen }
  startColor       255 and { startBlue }

  endColor 16 >> 255 and { endRed }
  endColor  8 >> 255 and { endGreen }
  endColor       255 and { endBlue }

  \ 256 steps for a complete fade
  256 0
  do
    i 0 255 startRed   endRed   map to red
    i 0 255 startGreen endGreen map to grn
    i 0 255 startBlue  endBlue  map to blu

    red grn blu color24 false setAllLEDsToAColor
    showPixels

    fadeDelayMS delay
  loop
;

\ Wake up, run the motion lamp code then go back to sleep
: main

  randomSeed

  0 0 { color white }

  \ Configure PIR input
  PIR_PIN INPUT pinMode

  \ Enable external wakeup from sleep
  PIR_PIN HIGH Sleep.enableExt0Wakeup

   \ Turn off all LEDs to initialize the driver
  true clearPixels

  50 delay

  \ Turn all LEDs white
  192 192 192 color24 to white
  white true setAllLEDsToAColor

  \ White LEDs on for a while
  WHITE_LIGHT_DELAY_MS delay

  \ Pick a color to fade to
  getARandomColor to color

  \ Fade from white to color
  white color FADE_DELAY_MS fadeBetweenColors
  
  \ Colored LEDS on for a while
  COLOR_LIGHT_DELAY_MS delay

  \ Fade from color to black
  color 0 FADE_DELAY_MS fadeBetweenColors

  \ To be sure, turn off all LEDs
  true clearPixels

  \ Go to deep sleep
  Sleep.deepSleep
;
