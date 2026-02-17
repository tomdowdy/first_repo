\ NeoPixel Display App
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 09/29/2022

\ Delay controlling scrolling speed
150 constant SCROLL_DELAY

\ Minute interval to awaken the display from sleep
                          12 constant DISPLAY_INTERVAL_MINS
  DISPLAY_INTERVAL_MINS 60 * constant DISPLAY_INTERVAL_SECS
DISPLAY_INTERVAL_SECS 1000 * constant DISPLAY_INTERVAL_MSECS

\ Minute interval for gathering weather data
                          30 constant WEATHER_INTERVAL_MINS
  WEATHER_INTERVAL_MINS 60 * constant WEATHER_INTERVAL_SECS
WEATHER_INTERVAL_SECS 1000 * constant WEATHER_INTERVAL_MSECS

\ State machine (FSM) states
0 constant STATE_CHECK_DISPLAY_STATE
1 constant STATE_DISPLAY_WELCOME
2 constant STATE_DISPLAY_TIMEDATE
3 constant STATE_DISPLAY_WEATHER
4 constant STATE_DISPLAY_SLEEP

\ Local variables
0 value state
0 value futureTimeDO \ Future time to turn display on
0 value futureTimeGW \ Future time to get weather data

\ Time and Date Variables
0 value _year
0 value _month
0 value _day
0 value _dayWeek
0 value _hour
0 value _hour24
0 value _minute
0 value _isPm

wifi

: main
  
  \ Initialize WS2812 library
  WS2812.setup

  \ Setup timezone
  usMT setTZ

  \ Login to WiFi network
  z" CraigNet" z" craigandheather" login

  \ Seed the random number generator
  randomSeed

  \ Set FG and BG colors
   0  0   0 color24 to BGColor
   0  0 255 color24 to FGColor

  \ Set initial FSM state
  STATE_CHECK_DISPLAY_STATE to state

  begin
    \ Select new dynamic colors
    initDynamicColorSelection2

    \ Get local time and date
    now toLocal >r
    r@ year_t to _year
    r@ month_t to _month
    r@ day_t to _day
    r@ weekDay_t to _dayWeek
    r@ hourFormat12_t to _hour
    r@ hour_t to _hour24
    r@ minute_t to _minute
    r> isPM_t to _isPM

    \ Run FSM
    state
    case
      STATE_CHECK_DISPLAY_STATE
      of
        \ Check to see if display should be on.
        \ Display on between 6AM and 10PM
        _hour24 5 > _hour24 22 < and
        if
          \ Display should be on
          STATE_DISPLAY_WELCOME to state
        else
          \ Turn off the display
          true clearPixels
        then
      endof

      STATE_DISPLAY_WELCOME
      of
        \ Calculate future time for display to awaken
        MS-TICKS DISPLAY_INTERVAL_MSECS + to futureTimeDO

        \ Pick a random display pattern
        pickPattern

        \ Display welcome message
        s" Welcome to Craig & Heathers" SCROLL_DELAY COLOR_MODE_CHAR scrollStr

        \ Pick a random display pattern
        pickPattern

        \ Set next state
        STATE_DISPLAY_TIMEDATE to state
      endof

      STATE_DISPLAY_TIMEDATE
      of
        \ Initialize string formatter
        0 to indx

        \ Format time and date string
        _hour #to$ $cat
        s" :" $cat

        \ Add leading 0 if needed
        _minute 10 <
        if
          0 #to$ $cat
        then

        _minute #to$ $cat
        _isPM
        if
          s" pm" $cat
        else
          s" am" $cat
        then
        addSpace
        _dayWeek getDayName $cat 
        addSpace
        _month getMonName $cat
        addSpace
        _day #to$ $cat
        addSpace
        _year #to$ $cat

        \ Display the formatted string
        0 FORMAT_BUFFER indx SCROLL_DELAY COLOR_MODE_STR scrollStr

        \ Pick a random display pattern
        pickPattern

        \ Set next state
        STATE_DISPLAY_WEATHER to state
      endof

      STATE_DISPLAY_WEATHER
      of
        \ Is it time to get new weather data
        MS-TICKS futureTimeGW >
        if
          \ Calculate future time to get weather data
          MS-TICKS WEATHER_INTERVAL_MSECS + to futureTimeGW

          \ Yes, get new weather data
          gatherOWMCCData
        then

        \ Format the weather data string
        \ Initialize string formatter
        0 to indx

        \ Format weather string
        description $cat
        addSpace
        temp $cat
        s" f" $cat
        addSpace 
        s" Wind: " $cat
        windSpeed $cat 
        s" mph" $cat
        addSpace
        s" Hum: " $cat
        humidity $cat
        s" %" $cat

        \ Display the formatted string
        0 FORMAT_BUFFER indx SCROLL_DELAY COLOR_MODE_STR scrollStr

        \ Pick a random display pattern
        pickPattern

        \ Set next state
        STATE_DISPLAY_SLEEP to state
      endof

      STATE_DISPLAY_SLEEP
      of
        MS-TICKS futureTimeDO >
        if
          STATE_CHECK_DISPLAY_STATE to state
        then
      endof
    endcase

    \ Do 1 second delay
    1000 delay

    false
  until
;

