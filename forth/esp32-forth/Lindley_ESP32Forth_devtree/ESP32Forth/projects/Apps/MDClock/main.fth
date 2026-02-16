\ Multi-Display Clock
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 05/30/2022

\ Rotation of time/date will wait for this length of time
                       30 constant ROTATION_WAIT_SECS
ROTATION_WAIT_SECS 1000 * constant ROTATION_WAIT_MS

\ Draw a numeric digit, colon or slash centered on rotated display
: drawDigit { dispNum iconIndex }
  dispNum LARGE_ICON iconIndex numberIcons 40 drawIcon
;

\ Display the time
: displayTime { displayIndex hr min }
  0 { tmp }

  \ Display hours in 1 or 2 digits
  hr 10 >=
  if
    \ We have leading digit to display; otherwise suppress it
    displayIndex 1 drawDigit

    -10 +to hr

    1 +to displayIndex
    displayIndex 5 >
    if 0 to displayIndex then
  then

  \ hr is 0, 1 or 2
  displayIndex hr drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  \ Display a colon
  displayIndex 10 drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  \ Display minutes 0 .. 59 in 2 digits
  min 10 / to tmp  
 
  displayIndex tmp drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  min tmp 10 * - to min
  
  displayIndex min drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then
;

\ Display the date
: displayDate { displayIndex mon day }

  0 { tmp }

  \ Display monthe in 1 or 2 digits
  mon 10 >=
  if
    \ We have leading digit to display; otherwise suppress it
    displayIndex 1 drawDigit

    -10 +to mon

    1 +to displayIndex
    displayIndex 5 >
    if 0 to displayIndex then
  then

  \ mon is 0, 1 or 2
  displayIndex mon drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  \ Display a slash
  displayIndex 11 drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  \ Display day 1 .. 31 in 2 digits
  day 10 / to tmp  
 
  displayIndex tmp drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then

  day tmp 10 * - to day
  
  displayIndex day drawDigit

  1 +to displayIndex
  displayIndex 5 >
  if 0 to displayIndex then
;

1 value _timeDate
0 value _prevHour
0 value _prevMinute
0 value _min
0 value _hour
0 value _hour24
0 value _mon
0 value _day
0 value _rotationWaitMS
1 value displayStartIndex

\ Bring in WiFi vocabulary
wifi

: main
  
  \ Initialize WS2812 library
  initWS2812

  \ Initialize displays
  initI2C drop
  3 initDisplays

  \ Setup timekeeping 
  usMT setTZ

  \ Login to WiFi network
  z" CraigNet" z" craigandheather" login
  
  begin

    now toLocal >r
    r@ minute_t to _min
    r@ hourFormat12_t to _hour
    r@ hour_t to _hour24
    r@ month_t to _mon
    r> day_t to _day

    \ Has the hour changed ?
    _hour _prevHour <>
    if
      _hour to _prevHour
      flashRed
    then

    \ Has the minute changed ?
    _min _prevMinute <>
    if
      \ Minute has just changed, save new value
      _min to _prevMinute

      \ Clear all displays
      clearDisplays   

      \ Check for clock on time between 6AM and 10PM
      _hour24 5 > _hour24 23 < and
      if
        \ Clock is on
        \ Process events
        _min 30 mod 0=
        if
          EVENT_DURATION_MS upDownArrowEventPattern
        else
          _min 15 mod 0=
          if
            EVENT_DURATION_MS peaceEventPattern
          else
            _min 10 mod 0=
            if
              EVENT_DURATION_MS spaceEventPattern
            else
              _min 5 mod 0=
              if
                EVENT_DURATION_MS upArrowEventPattern
              then
            then
          then
        then

        \ Clear all displays
        clearDisplays     

        \ Set rotation wait time before time/date starts to rotate
        MS-TICKS ROTATION_WAIT_MS + to _rotationWaitMS

        \ Toggle display between time and date
        _timeDate 1 =
        if
          0 to _timeDate

          \ Display the time
          displayStartIndex _hour _min displayTime

          \ Flash blue
          flashBlue
        else
          1 to _timeDate

          \ Display the date
          displayStartIndex _mon _day displayDate

          \ Flash green
          flashGreen
        then

        \ Time moves counter clockwise clock
        -1 +to displayStartIndex

        \ Keep index in range
        displayStartIndex 0 <
        if 5 to displayStartIndex then
      then
    else
      _rotationWaitMS MS-TICKS <
      if 
        \ Rotate the display until new time/date displayed
        rotate
        showAllDisplays
      then    
    then
    false
  until
;

only forth definitions

