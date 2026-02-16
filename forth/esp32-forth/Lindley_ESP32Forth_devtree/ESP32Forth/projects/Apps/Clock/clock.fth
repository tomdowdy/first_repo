\ Simple Clock Application for testing NTP access to Internet
\ and for testing time, timezone and tzrules
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 09/10/2021

\ Test time representing: Mon Dec 27th 2021 1:12:47 PM
1640635967 constant tt

\ Update the time every 30 seconds
30 1000 * constant TIME_UPDATE_MS
0 value futureTime


\ Display time and date. Assumes theTZ set before call
: displayTime&Date

  \ Get the UTC time and convert it to local time
  now toLocal >r

  \ Print day of the week
  ." Weekday: " r@ weekDay_t . cr 
  ." Month: "   r@ month_t   . cr
  ." Day: "     r@ day_t     . cr
  ." Year: "    r@ year_t    . cr
  ." Hour: "    r@ hourFormat12_t . cr
  ." Minute: "  r@ minute_t . cr
  ." AMPM: "    r@ isAM_t   . cr cr cr
 
  \ Clean up
  r> drop
;

\ Format buffer
20 byteArray FORMAT_BUFFER
 0 value     indx

\ Copy a string into format buffer
: $cat  ( addr n -- )  
  indx FORMAT_BUFFER ( addr n -- addr n dAddr )
  swap dup >r
  cmove
  r> +to indx
;

2 byteArray SPACE_BUFFER
$20 0 SPACE_BUFFER !

\ Add a space character for formatting
: addSpace 
  0 SPACE_BUFFER 1 $cat
;

\ Convert single number >= 0 to a string
: #to$ ( n -- addr count )
  <# #s #>
;

\ Format time and display
: formatDisplayTime ( -- ) 

  \ Initialize format buffer index
  0 to indx

  \ Get the UTC time and convert it to local time
  now toLocal >r

  \ Format the time string like: 9:59 AM
  r@
  hourFormat12_t
  #to$ $cat s" :" $cat

  \ If minutes single digit 0..9 add leading zero to string 
  r@ minute_t 10 <
  if
    s" 0" $cat
  then

  r@ minute_t #to$ $cat
  addSpace

  r@ isAM_t if 0 getAMPM else 1 getAMPM then $cat

  \ Print the time right justified
  0 FORMAT_BUFFER indx type cr cr cr

  \ Clean up
  r> drop
;

WiFi

\ Run the clock app
: clock
  cr cr
  Wifi.disconnect
  z" CraigNet" z" craigandheather" login
  4000 MS

  usMT setTZ
  0 to futureTime

  \ Loop forever
  begin
    MS-TICKS futureTime >
    if
      MS-TICKS TIME_UPDATE_MS + to futureTime

      \ Print the time and data for selected time zone
      displayTime&Date

      formatDisplayTime
    then
    false
  until
;

forth

