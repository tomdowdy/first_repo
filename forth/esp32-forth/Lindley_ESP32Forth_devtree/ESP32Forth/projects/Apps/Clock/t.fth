\ Time Test
\ and for testing time, timezone and tzrules
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 12/27/2021

\ Represents: Mon Dec 27th 2021 1:12:47 PM
1640635967 constant tt

\ Display time and date. Assumes theTZ set before call
: displayTime&Date

  \ Get the UTC time and convert it to local time
  tt toLocal >r
  cr

  \ Print day of the week
  ." Weekday: " r@ weekDay_t . cr 
  ." Month: "   r@ month_t   . cr
  ." Day: "     r@ day_t     . cr
  ." Year: "    r@ year_t    . cr
  ." Hour: "    r@ hourFormat12_t . cr
  ." Minute: "  r@ minute_t . cr
  ." Second: "  r@ second_t . cr
  ." AMPM: "    r@ isAM_t   . cr cr cr
 
  \ Clean up
  r> drop
;


\ Run the test app
: test

  usMT setTZ

  displayTime&Date
;


