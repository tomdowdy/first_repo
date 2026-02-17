\ 7 Segment Display Clock
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 09/19/2022

20000 constant EVENT_DURATION_MS


\ Outer segment array
12 constant NUM_OF_OUTER_SEGMENTS

1 2 5 7 14 21 28 27 24 22 15 8 NUM_OF_OUTER_SEGMENTS 
  initializedArray outerSegments 

\ Horizontal segment array
16 constant NUM_OF_HORIZ_SEGMENTS

2 5 3 6 9 12 10 13 16 19 17 20 23 26 24 27 NUM_OF_HORIZ_SEGMENTS
 initializedArray horizSegments 

\ Vertical segment array
13 constant NUM_OF_VERT_SEGMENTS

1 4 7 8 11 14 0 15 18 21 22 25 28 NUM_OF_VERT_SEGMENTS
 initializedArray vertSegments 

\ Diagonal segment array
10 constant NUM_OF_DIAG_SEGMENTS

1 11 0 21 25 22 18 0 14 4 NUM_OF_DIAG_SEGMENTS
 initializedArray diagSegments 

0 value futureTime

\ 30 minute event
: event30 

  \ Clear all digits of display
  false clearPixels

  \ Initialize dynamic color selection
  NUM_OF_DIAG_SEGMENTS 2 * initDynamicColorSelection1

  ms-ticks EVENT_DURATION_MS + to futureTime

  begin
    NUM_OF_DIAG_SEGMENTS 0
    do
      dynamicColorSelector i diagSegments segmentsArray setPixelColor24
      show
      150 delay
    loop
    ms-ticks futureTime >
  until
  0 to futureTime
;

\ 15 minute event
: event15 

  \ Clear all digits of display
  false clearPixels

  \ Initialize dynamic color selection
  NUM_OF_VERT_SEGMENTS 2 * initDynamicColorSelection1

  ms-ticks EVENT_DURATION_MS + to futureTime

  begin
    NUM_OF_VERT_SEGMENTS 0
    do
      dynamicColorSelector i vertSegments segmentsArray setPixelColor24
      show
      150 delay
    loop
    ms-ticks futureTime >
  until
  0 to futureTime
;

\ 10 minute event
: event10 

  \ Clear all digits of display
  false clearPixels

  \ Initialize dynamic color selection
  NUM_OF_HORIZ_SEGMENTS 2 * initDynamicColorSelection1

  ms-ticks EVENT_DURATION_MS + to futureTime

  begin
    NUM_OF_HORIZ_SEGMENTS 0
    do
      dynamicColorSelector i horizSegments segmentsArray setPixelColor24
      show
      150 delay
    loop
    ms-ticks futureTime >
  until
  0 to futureTime
;

\ 5 minute event
: event5 

  \ Clear all digits of display
  false clearPixels

  \ Initialize dynamic color selection
  NUM_OF_OUTER_SEGMENTS 2 * initDynamicColorSelection1

  ms-ticks EVENT_DURATION_MS + to futureTime

  begin
    NUM_OF_OUTER_SEGMENTS 0
    do
      dynamicColorSelector i outerSegments segmentsArray setPixelColor24
      show
      150 delay
    loop
    ms-ticks futureTime >
  until
  0 to futureTime
;

\ Display the time
: displayTime { hr min }

  \ If flag is a 1 display solid colored digits; if 0 display variegated  is 
  2 random0toN 0 { flag tmp }

  \ Clear all digits of display
  false clearPixels

  \ Display hours in 1 or 2 digits
  hr 10 >=
  if
    \ We have leading digit to display; otherwise suppress it
    flag 
    if 
      0 1 dynamicColorSelector displayANumber1
    else
      0 1 displayANumber2
    then

    -10 +to hr
  then

  \ hr is 0, 1 or 2
  flag 
  if 
    1 hr dynamicColorSelector displayANumber1
  else
    1 hr displayANumber2
  then

  \ Display minutes 0 .. 59 in 2 digits
  min 10 / to tmp  
 
  flag 
  if 
    2 tmp dynamicColorSelector displayANumber1
  else
    2 tmp displayANumber2
  then

  min tmp 10 * - to min
  
  flag 
  if 
    3 min dynamicColorSelector displayANumber1
  else
    3 min displayANumber2
  then
;

\ Display the date
: displayDate { mon day }

  \ If flag is a 1 display solid colored digits; if 0 display variegated  is 
  2 random0toN 0 { flag tmp }

  \ Clear all digits of display
  false clearPixels

  \ Display month in 1 or 2 digits
  mon 10 >=
  if
    \ We have leading digit to display; otherwise suppress it
    flag 
    if 
      0 1 dynamicColorSelector displayANumber1
    else
      0 1 displayANumber2
    then

    -10 +to mon
  then

  \ mon is 0, 1 or 2

  flag 
  if 
    1 mon dynamicColorSelector displayANumber1
  else
    1 mon displayANumber2
  then

  \ Display day 1 .. 31 in 2 digits
  day 10 / to tmp  
 
  flag 
  if 
    2 tmp dynamicColorSelector displayANumber1
  else
    2 tmp displayANumber2
  then

  day tmp 10 * - to day
  
  flag 
  if 
    3 day dynamicColorSelector displayANumber1
  else
    3 day displayANumber2
  then
;

1 value _timeDate
0 value _prevMinute
0 value _min
0 value _hour
0 value _hour24
0 value _mon
0 value _day

\ Bring in WiFi vocabulary
wifi

: main
  
  \ Initialize WS2812 library
  WS2812.setup

  \ Setup timezone
  usMT setTZ

  \ Login to WiFi network
  z" CraigNet" z" craigandheather" login

  \ Initialize dynamic color selection
  initDynamicColorSelection2

  \ Seed the random number generator
  randomSeed
  
  begin
    \ Get the local time
    now toLocal >r
    r@ minute_t to _min
    r@ hourFormat12_t to _hour
    r@ hour_t to _hour24
    r@ month_t to _mon
    r> day_t to _day

    \ Check to see if clock should be on.
    \ Clock on between 6AM and 10PM
    _hour24 5 > _hour24 22 < and
    if
      \ Yes clock should be on
      \ Has the minute changed ?
      _min _prevMinute <>
      if
        \ Minute has just changed, save new value
        _min to _prevMinute

        \ Process events
        _min 30 mod 0=
        if
          EVENT_DURATION_MS event30
        else
          _min 15 mod 0=
          if
            EVENT_DURATION_MS event15
          else
            _min 10 mod 0=
            if
              EVENT_DURATION_MS event10
            else
              _min 5 mod 0=
              if
                EVENT_DURATION_MS event5
              then
            then
          then
        then

        \ Toggle display between time and date
        _timeDate 1 =
        if
          0 to _timeDate

          \ Display the time
          _hour _min displayTime

        else
          1 to _timeDate

          \ Display the date
          _mon _day displayDate
        then

        \ Change dynamic colors
        initDynamicColorSelection2

      else   

        \ Vary separator's color  
        ms-ticks futureTime >
        if 
          ms-ticks 250 + to futureTime 
      
          \ Set separator color dynamically
          dynamicColorSelector setSeparator
        then
      then

    else

      \ Clock is off so ...
      \ Turn off the display completely
      true clearPixels
    then

    false
  until
;

only forth definitions

