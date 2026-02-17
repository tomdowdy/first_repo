\ Triangle Clock
\ Built into a 3D printed box
\ Original idea from: https://www.instructables.com/A-Linear-LED-Clock-for-Your-Desktop/
\ Concept, Design and Implementation in ESP32Forth by: Craig A. Lindley
\ Last Update: 11/08/2024

9 constant UNIT_MINUTES_LED_COUNT
6 constant TENS_MINUTES_LED_COUNT
9 constant UNIT_HOURS_LED_COUNT
8 constant SECONDS_LED_COUNT

0 value secondsIndex

\ Create arrays of LED numbers

\ Minutes LED array
22 12 13 20 14 15 18 16 17 0 UNIT_MINUTES_LED_COUNT 1+ initializedArray unitMinutes

\ Tens of minutes LED array
26 8 9 24 10 11 0            TENS_MINUTES_LED_COUNT 1+ initializedArray tensMinutes

\ Hours LED array
32 2 3 30 4 5 28 6 7 0       UNIT_HOURS_LED_COUNT   1+ initializedArray unitHours

\ Tens of hours treated differently since only 1 LED is required

\ Seconds LED array
19 21 23 25 27 29 31 33      SECONDS_LED_COUNT         initializedArray seconds 

\ Misc Functions

\ Update seconds indication by lighting top LEDs
: updateSeconds ( -- )

  \ Clear previous second LED to black or off
  0 0 0 secondsIndex seconds setPixelRGB
  1 +to secondsIndex
  secondsIndex SECONDS_LED_COUNT mod to secondsIndex

  \ Set next second LED to dim white or on
  64 64 64 secondsIndex seconds setPixelRGB
;

\ Set minute 0 .. 9
\ If 0 erase all minute LEDs
: setMinute { min }
  min 0=
  if
    \ Turn off all minute LEDs
    UNIT_MINUTES_LED_COUNT 0
    do
      0 0 0 i 1+ unitMinutes setPixelRGB
    loop
  else
    \ Light the appropriate LEDs
    \ Minute LEDs are blue
    min 0
    do
      0 0 255 i 1+ unitMinutes setPixelRGB
    loop
  then
;

\ Set 10's of minutes 0 .. 6
\ If 0 erase all 10's of minutes LEDs
: setTensOfMinutes { min10 }
  min10 0=
  if
    \ Turn off all minute LEDs
    TENS_MINUTES_LED_COUNT 0
    do
      0 0 0 i 1+ tensMinutes setPixelRGB
    loop
  else
    \ Light the appropriate LEDs
    \ Minute LEDs are green
    min10 0
    do
      0 255 0 i 1+ tensMinutes setPixelRGB
    loop
  then
;

\ Set hour 0 .. 9
\ If 0 erase all hour LEDs
: setHour { hr }
  hr 0=
  if
    \ Turn off all hour LEDs
    UNIT_HOURS_LED_COUNT 0
    do
      0 0 0 i 1+ unitHours setPixelRGB
    loop
  else
    \ Light the appropriate LEDs
    \ Minute LEDs are red
    hr 0
    do
      255 0 0 i 1+ unitHours setPixelRGB
    loop
  then
;

\ Set 10's of hours 0 .. 1
\ If 0 erase 10's of hour LED else light it
: setTensOfHours { hr10 }
  hr10 0=
  if
    \ Turn off 10's of hour LED
    0 0 0 1 setPixelRGB
  else
    \ Turn on 10's of hour LED
    \ 10's of hour LED is yellow
    255 255 0 1 setPixelRGB
  then
;

\ Display the time
: displayTime { hr min }

  hr 10 /    setTensOfHours
  hr 10 mod  setHour
  min 10 /   setTensOfMinutes
  min 10 mod setMinute

  \ Make time visible
  showPixels
;

0 value _hour24 
0 value _hour12
0 value _min
0 value _sec

0 value _prevSec

\ Bring in WiFi vocabulary
wifi

: main
  
  \ Clear all pixels
  true clearPixels

  \ Setup timekeeping 
  usMT setTZ

  \ Login to WiFi network
  SSID PSWD login

  \ Seed the random number generator 
  randomSeed
  
  begin

    \ Get the local time
    now toLocal >r

    \ Extract and store the components
    r@ hour_t         to _hour24
    r@ hourFormat12_t to _hour12
    r@ minute_t       to _min
    r> second_t       to _sec

    \ Check for clock on time between 6AM and 10PM
    _hour24 5 > _hour24 22 < and
    if
      \ Clock should be on
      _sec _prevSec <>
      if

        \ depth . cr

        _sec to _prevSec

        \ Is it time to run a pattern ?
        _min 10 mod 0=
        if
           \ Yes it is
           pickPattern
        else
          \ Update seconds display
          updateSeconds

          \ Update current time
          _hour12 _min displayTime

          \ Display the pixels
          showPixels
        then
      then
    else
      \ Clock should be off
      true clearPixels
    then

    100 delay
    false
  until
;

only forth definitions

