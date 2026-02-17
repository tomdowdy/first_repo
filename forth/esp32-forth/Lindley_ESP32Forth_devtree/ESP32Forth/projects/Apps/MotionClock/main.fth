\ ESP32 Motion Clock Application
\ Concept, Design and Implementation By: Craig A. Lindley
\ Last Update: 12/10/2022

\ Delay between showing segments of time and date
\ Segments are: Hr:Mn, AM/PM, dow, month, day, year
2 constant DISPLAY_DELAY_SECS
DISPLAY_DELAY_SECS 1000 * constant DISPLAY_DELAY_MS

\ Format buffer
20 byteArray FORMAT_BUFFER
0 value indx

\ Copy a string into format buffer
: $cat  ( addr n -- )  
  indx FORMAT_BUFFER ( addr n -- addr n dAddr )
  swap dup >r
  cmove
  r> +to indx
;

\ Convert single number >= 0 to a string
: #to$ ( n -- addr count )
  <# #s #>
;

\ Prepare display for formatting
: prepareDisplay ( -- )
  \ Clear display
  clearLCD

  \ Draw rounded rect around display
  0 0 _width_ 1- _height_ 1- 8 BLU roundedRect
;

\ Local variables
0 value _hr
0 value _min
0 value _isam
0 value _dow
0 value _mon
0 value _day
0 value _year

\ Display time and date. Assumes theTZ set before call
: displayTime&Date

  \ Get the UTC time and convert it to local time
  now toLocal >r

  \ Extract time and date values
  r@ hourFormat12_t to _hr
  r@ minute_t       to _min
  r@ isAM_t         to _isam
  r@ weekDay_t      to _dow
  r@ month_t        to _mon
  r@ day_t          to _day
  r@ year_t         to _year
  \ Clean up
  r> drop

  prepareDisplay

  \ Initialize format buffer index
  0 to indx

  _hr #to$ $cat
  s" :" $cat

  \ If minutes single digit 0..9 add leading zero to string 
  _min 10 <
  if
    s" 0" $cat
  then

  _min #to$ $cat

  \ Display hr:min
  40 0 FORMAT_BUFFER indx pCenteredString  

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  prepareDisplay

  \ Initialize format buffer index
  0 to indx

  _isam if 0 getAMPM else 1 getAMPM then $cat

  \ Display AM/PM
  40 0 FORMAT_BUFFER indx pCenteredString  

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  prepareDisplay

  \ Display day of the week
  40 _dow getDayName pCenteredString

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  prepareDisplay

  \ Display month
  40 _mon getMonName pCenteredString

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  prepareDisplay

  \ Initialize format buffer index
  0 to indx

  _day #to$ $cat

  \ Display day of month
  40 0 FORMAT_BUFFER indx pCenteredString  

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  prepareDisplay

  \ Initialize format buffer index
  0 to indx

  _year #to$ $cat

  \ Display year
  40 0 FORMAT_BUFFER indx pCenteredString  

  \ Do inner time segment delay
  DISPLAY_DELAY_MS delay

  \ Clear LCD
  clearLCD
;

WiFi

\ Run the motion clock app then sleep
: main

  \ Configure PIR input
  PIR_PIN INPUT pinMode

  \ Enable external wakeup from sleep
  PIR_PIN HIGH Sleep.enableExt0Wakeup
  
  \ Set US Mountain timezone
  usMT setTZ

  \ Login to WiFi network
  z" CraigNet" z" craigandheather" login
  
  \ Initialize the LCD controller into landscape mode
  3 initLCD

  \ Set large text size
  8 setTextSize

  \ Display time and date
  displayTime&Date

  \ Deep sleep
  Sleep.deepSleep
;
