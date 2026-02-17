\
\ MAX7219 Weather and Clock App
\ Written in ESP32forth
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 01/24/2026
\

\ ***************************************************************************
\ ***                        Constants and Variables                      ***
\ ***************************************************************************

\ Microseconds in a minute
60000000 constant MIN_TO_USECS

\ Sleep time in minutes
5 constant SLEEP_DURATION_MINS

SLEEP_DURATION_MINS MIN_TO_USECS * constant SLEEP_DURATION

\ ***************************************************************************
\ ***                            Support Words                            ***
\ ***************************************************************************

\ Function to scroll display left the specified number of times
: scrollLeftNTimes ( n -- )

  0 
  do
    shiftRBLeft
    renderBufferContents
    SCROLL_DELAY delay
  loop
;

\ Format a time in seconds since the epoch into the format buffer
\ Time is converted to local time before display
: formatTime { secs }

  0 { min0 }

  secs hourFormat12_t addNumber
  [char] : addChar
  secs minute_t to min0
  min0 10 <
  if
    s" 0" addString
  then
  min0 addNumber

  secs isAM_t 
  if
    0 getAMPM addString
  else
    1 getAMPM addString
  then
;

\ Display the date and time
: displayDateTime ( -- )

  \ Clear format buffer
  clearFormatBuffer

  \ Format the date

  now toLocal >r
  r@ weekDay_t getDayName addString 
  addSpace
  r@ month_t getShortMonthName addString
  addSpace
  r@ day_t addNumber
  addSpace 
  r@ year_t addNumber 
  addSpace

  \ Format the time

  r> formatTime

  \ Display the created string
  getFormatBufferString scrollString
;

\ Display SunRise and SunSet times
: displaySunRiseSunSet ( -- )

  \ Clear format buffer
  clearFormatBuffer

  s" SunRise:" addString
  \ Convert time string to a number
  SUNRISE_BUF getString s>number? drop toLocal formatTime
  addSpace

  s" SunSet:" addString
  \ Convert time string to a number
  SUNSET_BUF getString s>number? drop toLocal formatTime

  \ Display the created string
  getFormatBufferString scrollString
;

\ Display weather current conditions
: displayWeatherCC ( -- )

  \ Clear format buffer
  clearFormatBuffer

  \ Format temperature

  s" T:" addString
  TEMP_BUF getString addString
  s" F " addString

  \ Format wind speed

  s" W:" addString
  SPEED_BUF getString addString
  s" MPH " addString

  \ Format humidity

  s" H:" addString
  HUM_BUF getString addString
  s" %" addString

  \ Display the created string
  getFormatBufferString scrollString
;

\ ***************************************************************************
\ ***                            Program Entry                            ***
\ ***************************************************************************

WiFi

\ Test code entry point
: main ( -- )

  cr

  \ Initialize MAX7219 display
  max7219_Init

  100 delay

  \ Login to WiFi network
  SSID PSWD login

  100 delay

  \ Check for Internet availability by pinging google DNS
  z" 8.8.8.8" WiFi.hostByName 1 =
  if
    \ Internet is available

    \ Set US Mountain timezone
    usMT setTZ

    \ Prime the time code
    now toLocal drop

    \ Gather the current conditions weather data
    gatherOWMCCData

    \ Display the date & time
    displayDateTime

    32 scrollLeftNTimes

    \ Display SunRise & SunSet times
    displaySunRiseSunSet

    32 scrollLeftNTimes

    \ Display current weather conditions
    displayWeatherCC

    32 scrollLeftNTimes
  then

  \ Clear the display
  clearDisplay

  \ Prepare to go to sleep
  SLEEP_DURATION Sleep.timerWakeupUS

  \ Go to sleep
  Sleep.deepSleep
;

forth
