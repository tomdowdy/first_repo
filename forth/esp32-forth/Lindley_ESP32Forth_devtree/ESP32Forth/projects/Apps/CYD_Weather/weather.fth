\
\ CYD Weather Station
\ Written in ESP32forth
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 11/26/2023
\

\ ***************************************************************************
\ ***                        Constants and Variables                      ***
\ ***************************************************************************

\ Color definitions
$001F constant BLUE
$07E0 constant GREEN

\ Minute interval for display update
                           5 constant DISPLAY_INTERVAL_MINS
  DISPLAY_INTERVAL_MINS 60 * constant DISPLAY_INTERVAL_SECS
DISPLAY_INTERVAL_SECS 1000 * constant DISPLAY_INTERVAL_MSECS

\ Minute interval for gathering weather data
                          30 constant WEATHER_INTERVAL_MINS
  WEATHER_INTERVAL_MINS 60 * constant WEATHER_INTERVAL_SECS
WEATHER_INTERVAL_SECS 1000 * constant WEATHER_INTERVAL_MSECS

\ Future times for updates
0 value futureDisplayUpdateTime
0 value futureWeatherUpdateTime

\ State machine (FSM) states
0 constant STATE_WAIT
1 constant STATE_DISPLAY_UPDATE
2 constant STATE_WEATHER_UPDATE

\ FSM state
0 value state


\ ***************************************************************************
\ ***                            Support Words                            ***
\ ***************************************************************************

\ Convert OWM icon string to icon index
: iconToIndex { addr n }

  \ Clear the buffer
  clearFormatBuffer

  \ Copy first 2 chars into buffer
  addr    c@ addChar
  addr 1+ c@ addChar

  getFormatBufferString s>number? drop

  case
     1 of 0 endof
     2 of 1 endof
     3 of 2 endof
     4 of 3 endof
     9 of 4 endof
    10 of 4 endof
    11 of 5 endof
    13 of 6 endof
    50 of 7 endof
  endcase
;

\ Format a time in seconds since the epoch into the format buffer
\ Time is converted to local time before display
: formatLocalTime { secs }

  0 0 { t min0 }

  secs toLocal to t
  t hourFormat12_t addNumber
  [char] : addChar
  t minute_t to min0
  min0 10 <
  if
    s" 0" addString
  then
  min0 addNumber

  t isAM_t 
  if
    0 getAMPM addString
  else
    1 getAMPM addString
  then
;

\ Display the date string at specified location on display
: displayDate ( x y )

  \ Clear format buffer
  clearFormatBuffer

  now toLocal >r
  r@ weekDay_t getDayName addString 
  addSpace
  r@ month_t getMonName addString
  addSpace
  r@ day_t addNumber
  addSpace 
  r> year_t addNumber  

  \ Display the date
  getFormatBufferString pString
;

\ Display the time at specified location on display
: displayTime ( x y -- )

  \ Clear format buffer
  clearFormatBuffer

  now formatLocalTime
  
  getFormatBufferString pString
;

\ Display the current conditions icon at specified location on display
: displayIcon ( x y -- )

  ICON_BUF getString iconToIndex -rot draw50pxIcon
;

\ Display current temp
: displayTemp ( x y -- )

  \ Clear format buffer
  clearFormatBuffer
  s" Temp: " addString

  TEMP_BUF getString addString
  s" F" addString

  getFormatBufferString pString
;

\ Display wind speed
: displayWindSpeed ( x y -- )

  \ Clear format buffer
  clearFormatBuffer

  s" Wind: " addString

  SPEED_BUF getString  addString
  s" MPH" addString

  getFormatBufferString pString
;

\ Display humidity
: displayHumidity ( x y -- )

  \ Clear format buffer
  clearFormatBuffer

  s" Humidity: " addString

  HUM_BUF getString addString
  s" %" addString

  getFormatBufferString pString
;

\ Display sunrise time
: displaySunRiseTime ( x y )

  \ Clear format buffer
  clearFormatBuffer

  s" Sunrise: " addString

  \ Convert time string to a number
  SUNRISE_BUF getString s>number? drop
  
  formatLocalTime

  getFormatBufferString pString
;

\ Display sunset time
: displaySunSetTime ( x y )

  \ Clear format buffer
  clearFormatBuffer

  s" Sunset: " addString

  \ Convert time string to a number
  SUNSET_BUF getString s>number? drop
  
  formatLocalTime

  getFormatBufferString pString
;

\ Display future day labels
: displayFutureDayLabels ( -- )

  now toLocal weekDay_t { wd } \ 1 .. 7
  1 +to wd
  wd 7 > if 1 to wd then
  245 27 wd getDayName pString
  1 +to wd
  wd 7 > if 1 to wd then
  245 79 wd getDayName pString
  1 +to wd
  wd 7 > if 1 to wd then
  245 131 wd getDayName pString
  1 +to wd
  wd 7 > if 1 to wd then
  245 183 wd getDayName pString
;

\ Display future day icons
: displayFutureDayIcons ( -- )

  ICON1_BUF getString iconToIndex 292  48 draw20pxIcon
  ICON2_BUF getString iconToIndex 292 100 draw20pxIcon
  ICON3_BUF getString iconToIndex 292 152 draw20pxIcon
  ICON4_BUF getString iconToIndex 292 204 draw20pxIcon
;

\ Display future day noon temps
: displayFutureDayTemps ( -- )

  \ Clear format buffer
  clearFormatBuffer

  TEMP1_BUF getString addString
  s" F" addString
  209 50 getFormatBufferString pString
  
  \ Clear format buffer
  clearFormatBuffer

  TEMP2_BUF getString addString
  s" F" addString
  209 102 getFormatBufferString pString
  
  \ Clear format buffer
  clearFormatBuffer

  TEMP3_BUF getString addString
  s" F" addString
  209 154 getFormatBufferString pString
  
  \ Clear format buffer
  clearFormatBuffer

  TEMP4_BUF getString addString
  s" F" addString
  209 206 getFormatBufferString pString
;

\ Update the display contents
: updateDisplay ( -- )
  clearScreen

  \ Draw surrounding rouded rect
  0 0 320 240 10 GREEN roundedRect

  \ Draw left most rounded rect
  3 2 200 235 10 BLUE roundedRect
  4 3 198 233 10 BLUE roundedRect

  \ Draw right most rounded rect
  204 2 113 235 10 BLUE roundedRect
  205 3 111 233 10 BLUE roundedRect

  \ Display static labels
   77 7 s" Today" pString
  226 7 s" Future" pString

  \ Display the date
  14 27 displayDate

  \ Display the current time
  67 47 displayTime

  \ Display temp
  14 70 displayTemp

  \ Display wind speed
  14 90 displayWindSpeed

  \ Display humidity
  14 110 displayHumidity

  \ Display current conditions icon
  80 135 displayIcon

  \ Display sunrise and sunset time
  14 198 displaySunRiseTime
  14 218 displaySunSetTime

  \ Display future day labels
  displayFutureDayLabels

  \ Display future day icons
  displayFutureDayIcons

  \ Display future day noon temps
  displayFutureDayTemps
;

\ ***************************************************************************
\ ***                            Program Entry                            ***
\ ***************************************************************************

WiFi

\ Test code entry point
: main ( -- )

  \ Initialize CYD display module
  3 initLCD
  clearScreen

  2 setTextSize

  100 delay

  \ Login to WiFi network
  SSID PSWD login

  100 delay

  \ Set US Mountain timezone
  usMT setTZ

  \ Prime the time code
  now toLocal drop

  \ Gather the current conditions weather data
  gatherOWMCCData

  500 delay

  \ Gather forecasted weather data
  gatherOWMFData  
  
  \ Update display with acquired data
  updateDisplay

  \ Initialize time intervals
  MS-TICKS DISPLAY_INTERVAL_MSECS + to futureDisplayUpdateTime
  MS-TICKS WEATHER_INTERVAL_MSECS + to futureWeatherUpdateTime

  \ Initial state machine state
  STATE_WAIT to state

  begin
    state
    case
      STATE_WAIT
      of
        \ Check for display update
        MS-TICKS futureDisplayUpdateTime >
        if
          \ Next state
          STATE_DISPLAY_UPDATE to state
        else
          \ Check for weather update
          MS-TICKS futureWeatherUpdateTime >
          if
            \ Next state
            STATE_WEATHER_UPDATE to state
          then
        then
      endof

      STATE_DISPLAY_UPDATE
      of
        \ Update display with current data
        updateDisplay

        \ Update time interval
        MS-TICKS DISPLAY_INTERVAL_MSECS + to futureDisplayUpdateTime

        \ Next state
        STATE_WAIT to state
      endof

      STATE_WEATHER_UPDATE
      of
        \ Gather the current conditions weather data
        gatherOWMCCData

        500 delay

        \ Gather forecasted weather data
        gatherOWMFData  

        \ Update display with new data
        updateDisplay

        \ Update time intervals
        MS-TICKS DISPLAY_INTERVAL_MSECS + to futureDisplayUpdateTime
        MS-TICKS WEATHER_INTERVAL_MSECS + to futureWeatherUpdateTime

        \ Next state
        STATE_WAIT to state
      endof
    endcase
    1000 delay
    false
  until
;

forth
