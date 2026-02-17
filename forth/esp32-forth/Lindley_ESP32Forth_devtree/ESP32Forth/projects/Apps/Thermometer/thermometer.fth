\ Vertical Thermometer Temperature Gauge
\ Written for ESP32forth
\ NOTE: slow down upload rate or code will not upload
\ Written by: Craig A. Lindley
\ Last Update: 09/11/2021

\ Fudge factor introduced to make temp align with other thermometers
2 constant T_FUDGE_FACTOR

WS2812

WS2812_COUNT constant NUM_OF_PIXELS

\ Setup the WS2812 pixel strip for temperature display
: WS2812.setup WS2812_PIN WS2812.begin true clearPixels ;

TempSensor

\ Setup the DS18B20 temperature sensor
: TempSensor.setup TEMPSENSOR_PIN tempSensor.begin ;

: getTemp TempSensor.getTempF T_FUDGE_FACTOR - ;

WiFi

\ Login to WiFi
: doLogin 
  z" CraigNet" z" craigandheather" login
  2000 ms
;

\ Check access to internet, reboot if internet not available
: checkInternet ( -- )
  z" google.com" WiFi.hostByName 1 <>
  if
    \ Reboot application
    bye
  then
;

Forth

\ Variables for keeping track of hi/lo temp
  0 value HIGH_TEMP
100 value LOW_TEMP

\ Array of color24 values for the 25 WS2812 pixels
NUM_OF_PIXELS Array pixelColors

\ Misc functions

\ Given a temp, return the index ( 0 .. 24) into pixelsColors and pixel
\ Returns index 0 if temp out of range 
: getIndexFromTemp { temp }
  temp 46 >= temp 94 <= and
  if
    temp 46 - 2 /
  else
    0
  then

  dup ." Index: " . cr 
;

: showTemp ( temp -- )
  getIndexFromTemp dup
  pixelColors @ swap setPixelColor24
  show
;

\ Update thermometer slowly
: updateThermometer ( temp -- )
  \ Clear previous reading
  FALSE clearPixels
  getIndexFromTemp 0
  do 
    i pixelColors @ i setPixelColor24
    250 ms
    show
  loop
;

\ Fade the thermometer to black
: fadeThermometer ( -- )
  0 9
  do
    NUM_OF_PIXELS 3 * 0
    do
      i pixels c@ j * 10 / i pixels c!
    loop
    show
    500 ms
    -1
  +loop
  TRUE clearPixels
;

\ Get the UTC time and extract the current hour
: getHour
    now toLocal hour_t
;

\ Get the UTC time and extract the current minute
: getMin
    now toLocal minute_t
;

\ Event One - Rainbow
: event1
  TRUE clearPixels

  NUM_OF_PIXELS 0
  do
    i 25 hsvColor i setPixelColor24
    show
    300 ms 
  loop
  NUM_OF_PIXELS 0
  do
    0 i setPixelColor24
    show
    150 ms 
  loop
  TRUE clearPixels
;

\ Event Two - Show high and low temps
: event2
  TRUE clearPixels
  HIGH_TEMP showTemp
  2000 ms
  LOW_TEMP  showTemp
  2000 ms
  TRUE clearPixels
;

\ Program Setup
: setup

  \ Hardware setup
  WS2812.setup
  TempSensor.setup

  \ Build an array of color24 values which describes the colors of each
  \ pixel on the thermometer

  \ Dark blues
  000 000 255 color24  0 pixelColors !
  000 000 255 color24  1 pixelColors !
  000 000 255 color24  2 pixelColors !
  000 000 255 color24  3 pixelColors !
  000 000 255 color24  4 pixelColors !
  000 000 255 color24  5 pixelColors !

  \ Light blues
  000 128 255 color24  6 pixelColors !
  000 128 255 color24  7 pixelColors !
  000 128 255 color24  8 pixelColors !

  \ Greens
  000 128 000 color24  9 pixelColors !
  000 255 000 color24 10 pixelColors !
  000 255 000 color24 11 pixelColors !
  000 255 000 color24 12 pixelColors !
  000 255 000 color24 13 pixelColors !

  \ Yellows
  255 255 000 color24 14 pixelColors !
  255 255 000 color24 15 pixelColors !
  255 255 000 color24 16 pixelColors !

  \ Reds
  064 000 000 color24 17 pixelColors !
  128 000 000 color24 18 pixelColors !
  255 000 000 color24 19 pixelColors !
  255 000 000 color24 20 pixelColors !
  255 000 000 color24 21 pixelColors ! 

  \ Whites meaning hot as hell indoors
  140 140 140 color24 22 pixelColors ! 
  160 160 160 color24 23 pixelColors ! 
  180 180 180 color24 24 pixelColors ! 

  \ Login to WiFi
  doLogin 

  \ Set the local timezone
  usMT setTZ

  1000 ms
;

\ Run the thermometer app
: run
  
  \ Do initial setup
  setup

  \ Locals
  0 0 0 { hr min t }

  getTemp to t
  50 ms
  getTemp to t

  \ Loop forever
  begin
    20 ms

    \ Get the current hour and minute
    getHour to hr
    getMin  to min
    ." Hr: " hr . ." Min: " min . cr

    \ Check for internet access every 5 minutes
    min 5 mod 0= if checkInternet then

    \ Check for daily temp reset at 12 noon
    hr 12 = min 0= and
    if
      100 to LOW_TEMP
        0 to HIGH_TEMP
    then

    \ Read the current temperature
    getTemp to t

    ." Temp: " t . cr

    \ Updates high and low temps
    t LOW_TEMP  < if t to LOW_TEMP  then
    t HIGH_TEMP > if t to HIGH_TEMP then

    \ Display should be on between 6 AM and 9:59 PM
    hr 6 >= hr 22 < and 
    if
      \ Check for events
      min  5 mod 0= if event1 then
      min 10 mod 0= if event2 then

      \ Alternate between temp display and display fading 
      min 2 mod 0=
      if 
        \ Display the temp 
        t updateThermometer
      else
        \ Fade thermometer to black
        fadeThermometer
      then
    else
      \ Display should be off
      TRUE clearPixels
    then

." done" cr cr cr

    \ Delay until minute changes
    begin
      10 ms
      getMin min <>
    until
    false
  until
;



