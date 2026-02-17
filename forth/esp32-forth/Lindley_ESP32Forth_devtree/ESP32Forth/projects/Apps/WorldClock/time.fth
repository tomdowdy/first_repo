\ Time Library
\ Based on Arduino Time library by Michael Margolis & Paul Stoffregen
\ Written for ESP32forth
\ Needs structures.fth loaded
\ By: Craig A. Lindley
\ Last Update: 08/13/20121

\ Jan is month 1 and there is no month 0
: getMonName ( index -- addr n )
  case
    1 of s" Jan" endof
    2 of s" Feb" endof
    3 of s" Mar" endof
    4 of s" Apr" endof
    5 of s" May" endof
    6 of s" Jun" endof
    7 of s" Jul" endof
    8 of s" Aug" endof
    9 of s" Sep" endof
   10 of s" Oct" endof
   11 of s" Nov" endof
   12 of s" Dec" endof
  endcase
;

\ Sun is day 1 and there is no day 0
: getDayName ( index -- addr n )
  case
    1 of s" Sun" endof
    2 of s" Mon" endof
    3 of s" Tue" endof
    4 of s" Wed" endof
    5 of s" Thu" endof
    6 of s" Fri" endof
    7 of s" Sat" endof
  endcase
;

\ 0 == AM; 1 == PM
: getAMPM ( index -- addr n )
  case
    0 of s" AM" endof
    1 of s" PM" endof
  endcase
;

\ Program constants
60                    constant SECONDSPERMINUTE
SECONDSPERMINUTE 60 * constant SECONDSPERHOUR
SECONDSPERHOUR   24 * constant SECONDSPERDAY

\ NTP time refresh interval in seconds -  3600 == 1/hr, 600 == every 10 minutes
\ 3600 constant SYNCINTERVAL
600 constant SYNCINTERVAL

\ Program variables
0 value sysTime
0 value prevMS
0 value nextSync
0 value cacheTime

\ Time element structure - holds time and date
struct:
  cell field: .second
  cell field: .minute
  cell field: .hour
  \ Day of week, sunday is day 1
  cell field: .wday
  cell field: .day
  cell field: .month
  cell field: .year
constant T_ELEMENTS

\ tElements creation
: newTElements
  T_ELEMENTS create allot
;

\ Instantiate T_ELEMENTS objects
newTElements time
newTElements newTime

\ Copy time to newTime - except day of week
: timeToNewTime ( -- )
  time .year   @ newTime .year   !
  time .month  @ newTime .month  !
  time .day    @ newTime .day    !
  time .hour   @ newTime .hour   !
  time .minute @ newTime .minute !
  time .second @ newTime .second !
;

\ Show contents of tElement structure
: showTElement { te }
  cr
  ." Year: "   te .year   @ . cr
  ." Month: "  te .month  @ . cr
  ." Day: "    te .day    @ . cr
  ." WDay: "   te .wday   @ . cr
  ." Hour: "   te .hour   @ . cr
  ." Minute: " te .minute @ . cr
  ." Second: " te .second @ . cr
  cr
;

\ Array of days in each month
31 30 31 30 31 31 30 31 30 31 28 31 12 initializedArray MONTHDAYS

\ Leap year calc expects argument as years offset from 1970
: leapYear?                   ( year -- f )
  1970 +                      ( year -- year+1970 )
  dup dup                    ( year' -- year' year' year' )
  4 mod 0=          ( year year year -- year year f )
  swap                 ( year year f -- year f year )
  100 mod 0<>          ( year f year -- year f f )
  and                     ( year f f -- year f )
  swap                      ( year f -- f year )
  400 mod 0=                ( f year -- f f )
  or                           ( f f -- f )
;

\ Local variables for function below
0 value _year_
0 value _mon_
0 value _monLen_
0 value _days_
0 value _exit_

\ Breakup the seconds since 1970 into individual time elements
: breakTime  { timeSecs }

  timeSecs 60 mod time .second !
  timeSecs 60 / to timeSecs
  timeSecs 60 mod time .minute !
  timeSecs 60 / to timeSecs
  timeSecs 24 mod time .hour   !
  timeSecs 24 / to timeSecs
  timeSecs 4 + 7 mod 1+ time .wday !

  0 to _year_
  0 to _days_

  begin
      _year_ leapYear?
      if
          366 +to _days_
      else
          365 +to _days_
      then

      timeSecs _days_ >=
  while
      1 +to _year_
  repeat

  _year_ time .year !

  _year_ leapYear?
  if
      366 negate +to _days_
  else
      365 negate +to _days_
  then

  _days_ negate +to timeSecs

  0 to _days_
  0 to _mon_
  0 to _monLen_
  FALSE to _exit_

  begin
      _mon_ 12 < _exit_ 0= and
  while
     \ Feb ?
      _mon_ 1 =
      if
          _year_ leapYear?
          if
              29 to _monLen_
          else
              28 to _monLen_
          then
      else
          _mon_ MONTHDAYS to _monLen_
      then

      timeSecs _monLen_ >=
      if
          _monLen_ negate +to timeSecs
      else
          TRUE to _exit_
      then
      1 +to _mon_
  repeat
  _mon_ time .month !
  timeSecs 1+ time .day !
;

0 value _secs_

\ Convert newTime to seconds since 1970
: makeTime ( -- timeSecs )

  \ Seconds from 1970 till 1 jan 00:00:00 of the given year
  newTime .year @ SECONDSPERDAY * 365 * to _secs_ 
  newTime .year @ 0
  do
    i leapYear?
    if 
      SECONDSPERDAY +to _secs_
    then
  loop
  \ Add days for this year, months start from 1
  newTime .month @ 1
  ?do
    i 2 = newTime .year @ leapYear? and
    if
      SECONDSPERDAY 29 * +to _secs_
    else
      SECONDSPERDAY i 1- MONTHDAYS * +to _secs_
    then
  loop
  newTime .day @ 1- SECONDSPERDAY * +to _secs_
  newTime .hour @ SECONDSPERHOUR *  +to _secs_
  newTime .minute @ SECONDSPERMINUTE * +to _secs_
  newTime .second @ +to _secs_
  _secs_ 
;

\ Return the current system time syncing with NTP as appropriate
: now			( -- sysTime )
  \ Calculate number of seconds since last call to now
  begin
    ms-ticks prevMS - abs 1000 >=
  while
    \ Advance system time by one second
    1 +to sysTime
    1000 +to prevMS
  repeat

  \ Is it time to sync with NTP ?
  nextSync sysTime <=
  if
    ." Syncing with NTP" cr
    getTime
    dup
    to sysTime
    SYNCINTERVAL +
    to nextSync
    ms-ticks to prevMS
  else 
    sysTime SYNCINTERVAL + to nextSync
  then
  sysTime 
;

\ Check and possibly refresh time cache
: refreshCache  ( timeSecs -- )
  dup dup
  cacheTime <>
  if
    breakTime to cacheTime
  else
    2drop
  then
;

\ Given time in seconds since 1970 return hour
: hour_t ( timeSecs -- hour )
  refreshCache
  time .hour @
;

\ Return the now hour
: hour  ( -- hour )
  now hour_t
;

\ Given time in seconds since 1970 return hour in 12 hour format
: hourFormat12_t ( timeSecs -- hour12 )
  refreshCache
  time .hour @ dup
  0=
  if
    drop 
    12
  else
    dup
    12 >
    if
      12 -
    then
  then
;

\ Return now hour in 12 hour format
: hourFormat12 ( -- hour12 )
  now hourFormat12_t
;

\ Given time in seconds since 1970 return PM status
: isPM_t ( timeSecs -- f )
  refreshCache	    
  time .hour @ 12 >=
;

\ Determine if now time is PM
: isPM  ( -- f )
  now isPM_t
;

\ Given time in seconds since 1970 return AM status
: isAM_t  ( timeSecs -- f )
  refreshCache	    
  time .hour @ 12 <
;

\ Determine if now time is AM
: isAM  ( -- f ) 
  now isAM_t
;

\ Given time in seconds since 1970 return minute
: minute_t  ( timeSecs -- minute )
  refreshCache
  time .minute @
;

\ Return the now minute
: minute  ( -- minute )
  now minute_t
;

\ Given time in seconds since 1970 return second
: second_t  ( timeSecs -- second )
  refreshCache
  time .second @
;

\ Return the now second
: second  ( -- second )
  now second_t
;

\ Given time in seconds since 1970 return day
: day_t  ( timeSecs -- day )
  refreshCache
  time .day @
;

\ Return the now day
: day  ( -- day )
  now day_t
;

\ Given time in seconds since 1970 return the week day with Sun as day 1
: weekDay_t  ( timeSecs -- weekDay )
  refreshCache
  time .wday @
;

\ Return the now week day with Sun as day 1
: weekDay  ( -- weekDay )
  now weekDay_t
;

\ Given time in seconds since 1970 return month
: month_t  ( timeSecs -- month )
  refreshCache
  time .month @
;

\ Return the now month
: month	( -- month )
  now month_t
;

\ Given time in seconds since 1970 return year in full 4 digit format
: year_t  ( timeSecs -- year )
  refreshCache
  time .year @ 1970 +
;

\ Return the now year in full 4 digit format
: year  ( -- year )
  now year_t
;

