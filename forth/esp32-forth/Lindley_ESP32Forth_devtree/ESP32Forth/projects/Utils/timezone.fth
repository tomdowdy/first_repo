\ Time Zone and Daylight Savings Time Library
\ Based on Arduino Timezone library by Jack Christensen
\ Written for ESP32forth
\ Needs structures.fth loaded
\ By: Craig A. Lindley
\ Last Update: 08/13/2021

\ Structure for describing a time change rule
struct:
  \ wk (week) - last = 0 first second third fourth
  cell field: .wk
  \ dow (day of week) - Sun = 1 .. Sat
  cell field: .dow
  \ mon (month) - Jan = 1 .. Dec
  cell field: .mon
  \ hr (hour) - 0 .. 23
  cell field: .hr
  \ off (offset) - Offset from UTC in minutes
  cell field: .off
constant TCR

\ Instantiate a new time change rule
: newTCR TCR create allot ;

\ Structure for describing a timezone consisting of
\ a title and two time change rules
struct:
  \ Index of name of timezone
  cell field: .index
  \ Daylight saving time TCR
  TCR field: .dstTCR
  \ Standard time TCR
  TCR field: .stdTCR
constant TZ

\ Instantiate a new timezone
: newTZ TZ create allot ;

\ Program variables
\ DST start for given/current year, given in UTC
0 value dstUTC

\ STD start for given/current year, given in UTC
0 value stdUTC

\ DST start for given/current year, given in local time
0 value dstLoc

\ STD start for given/current year, given in local time
0 value stdLoc

\ Variable holding the current TZ object
0 value theTZ

\ Local variables for function below
0 value _tm_
0 value _year_
0 value _mon_
0 value _week_

\ Convert a time change rule (TCR) to a time_t value for given year
: toTime_t  { aTCR year } ( aTCR year -- time_t )

  year to _year_
  aTCR .mon @ to _mon_
  aTCR .wk  @ to _week_

  _week_ 0= 
  if
    1 +to _mon_
    _mon_ 12 >
    if
      1 to _mon_
      1 +to _year_
    then
    1 to _week_
  then
  aTCR .hr @ 
    newTime .hour   !
  0 newTime .minute !
  0 newTime .second !
  1 newTime .day    !
  _mon_ newTime .month !

  _year_ 1970 - newTime .year !
  makeTime to _tm_

  _week_ 1- 7 *
  aTCR .dow @ _tm_ weekDay_t
  - 7 + 7 mod +
  SECONDSPERDAY * +to _tm_

  aTCR .wk @ 0=
  if
      -7 SECONDSPERDAY * +to _tm_
  then
  _tm_ 
;

\ Calculate the DST and standard time change points for the given
\ given year as local and UTC time_t values.
: calcTC                    ( year -- )
  dup                       ( year -- year year )
  >r                   ( year year -- year )
  theTZ .dstTCR @
  swap                      ( year -- TCR year )
  toTime_t to dstLoc    ( TCR year -- )
  r>                             ( -- year )
  theTZ .stdTCR @
  swap                      ( year -- TCR year )
  toTime_t to stdLoc    ( TCR year -- )

  dstLoc
  theTZ .stdTCR @
  .off @
  SECONDSPERMINUTE *
  -
  to dstUTC

  stdLoc
  theTZ .dstTCR @
  .off @
  SECONDSPERMINUTE *
  -
  to stdUTC
;


\ Determine whether the given UTC time_t is within the DST interval
\ or the Standard time interval
: utcIsDST                     ( utc -- f )
  dup                          ( utc -- utc utc )
  year_t                   ( utc utc -- utc utc_yr )
  dstUTC                ( utc utc_yr -- utc utc_yr utc_dst )
  year_t        ( utc utc_yr utc_dst -- utc utc_yr dst_yr )
  over           ( utc utc_yr dst_yr -- utc utc_yr dst_yr utc_yr )
  <>      ( utc utc_yr dst_yr utc_yr -- utc utc_yr f )
  if
      calcTC
  else
      drop
  then                             ( -- utc )
  dup                          ( utc -- utc utc )
  stdUTC
  dstUTC  >
  if
    \ Northern hemisphere
    dstUTC >=          ( utc utc -- utc f )
    swap                   ( utc f -- f utc )
    stdUTC <
    and
  else
    \ Southern hemisphere
    stdUTC >=          ( utc utc -- utc f )
    swap                   ( utc f -- f utc )
    dstUTC <
    and 0=
  then
;

\ Convert the given UTC time to local time, standard or
\ daylight time, as appropriate
: toLocal                      ( utc -- time_t )
  dup                          ( utc -- utc utc )
  year_t                   ( utc utc -- utc utc_yr )
  dstUTC                ( utc utc_yr -- utc utc_yr utc_dst )
  year_t        ( utc utc_yr utc_dst -- utc utc_yr dst_yr )
  over           ( utc utc_yr dst_yr -- utc utc_yr dst_yr utc_yr )
  <>      ( utc utc_yr dst_yr utc_yr -- utc utc_yr f )
  if
    calcTC              ( utc utc_yr -- utc )
  else
    drop
  then                             ( -- utc )
  dup                          ( utc -- utc utc )
  utcIsDST                 ( utc utc -- utc f )
  if
    theTZ .dstTCR @ .off @
    SECONDSPERMINUTE *
    +
  else
    theTZ .stdTCR @ .off @
    SECONDSPERMINUTE *
    +
  then
;

\ Set the timezone in preparation for time conversion
: setTZ  ( tz -- )

  \ Store tz into global variable
  to theTZ

  \ Clear all local variables for new calculation
  0 to dstLoc
  0 to stdLoc
  0 to dstUTC
  0 to stdUTC
;


