\ Proximity Experiment using the HC-SR04 sensor

0 constant MARKER

\ Hardware Connections
18 constant SENSOR_TRIGGER_PIN
19 constant SENSOR_ECHO_PIN

\ Constants

\ Sensor timeout is 1 second
1000000 constant SENSOR_TIMEOUT_US

\ Distances to active zones
 2 constant ZONE1_DISTANCE_INCHES
 7 constant ZONE2_DISTANCE_INCHES
12 constant ZONE3_DISTANCE_INCHES
16 constant ZONE4_DISTANCE_INCHES

\ +/- distance around zones to include
 2 constant ZONE_TOLERANCE_INCHES

\ Zone ranges
ZONE1_DISTANCE_INCHES ZONE_TOLERANCE_INCHES - constant ZONE1_MIN
ZONE1_DISTANCE_INCHES ZONE_TOLERANCE_INCHES + constant ZONE1_MAX

ZONE2_DISTANCE_INCHES ZONE_TOLERANCE_INCHES - constant ZONE2_MIN
ZONE2_DISTANCE_INCHES ZONE_TOLERANCE_INCHES + constant ZONE2_MAX

ZONE3_DISTANCE_INCHES ZONE_TOLERANCE_INCHES - constant ZONE3_MIN
ZONE3_DISTANCE_INCHES ZONE_TOLERANCE_INCHES + constant ZONE3_MAX

ZONE4_DISTANCE_INCHES ZONE_TOLERANCE_INCHES - constant ZONE4_MIN
ZONE4_DISTANCE_INCHES ZONE_TOLERANCE_INCHES + constant ZONE4_MAX


\ Max detection distance constants
ZONE4_DISTANCE_INCHES ZONE_TOLERANCE_INCHES 2 * + constant MAX_DISTANCE_INCHES
MAX_DISTANCE_INCHES 148 *                         constant MAX_PULSE_WIDTH

10 constant EVENT_THRESHOLD

\ Variables
value zone1Count
value zone2Count
value zone3Count
value zone4Count

\ Reset collection data after out of range eveng
: reset ( -- ) 
  0 to zone1Count
  0 to zone2Count
  0 to zone3Count
  0 to zone4Count

  \ Clear all pixels
  true clearPixels
;

\ Event One
: event1 ( -- )
  \ Clear all pixels
  true clearPixels

  255 0 0 0 setPixelRGB
  showPixels
;

\ Event Two
: event2 ( -- )
  \ Clear all pixels
  true clearPixels

  0 255 0 1 setPixelRGB
  showPixels
;

\ Event Three
: event3 ( -- )
  \ Clear all pixels
  true clearPixels

  0 0 255 2 setPixelRGB
  showPixels
;

\ Event Four
: event4 ( -- )
  \ Clear all pixels
  true clearPixels

  0 128 128 3 setPixelRGB
  showPixels
;

\ Ping for distance
\ Returns -1 if out of range
: ping ( -- inches ) 

  SENSOR_TRIGGER_PIN LOW digitalWrite
  5 delayMicroseconds

  SENSOR_TRIGGER_PIN HIGH digitalWrite
  10 delayMicroseconds

  SENSOR_TRIGGER_PIN LOW digitalWrite

  SENSOR_ECHO_PIN HIGH SENSOR_TIMEOUT_US pulseIn dup
  MAX_PULSE_WIDTH >=
  if
    \ Out of range
    drop
    reset
    -1
  else
    \ In range convert to inches
    148 / 
  then
;

: main

  0 { dist }
  
  \ Clear all pixels
  true clearPixels

  SENSOR_TRIGGER_PIN OUTPUT       pinMode
  SENSOR_ECHO_PIN    INPUT_PULLUP pinMode

  begin

    ping to dist
    dist -1 <>
    if
      \ Distance in range so check active zones

      \ Check zone 1
      dist ZONE1_MIN >= 
      dist ZONE1_MAX <= and
      if 
        1 +to zone1Count
        zone1Count EVENT_THRESHOLD >
        if
          reset
          event1
        then
      then

      \ Check zone 2
      dist ZONE2_MIN >= 
      dist ZONE2_MAX <= and
      if 
        1 +to zone2Count
        zone2Count EVENT_THRESHOLD >
        if
          reset
          event2
        then
      then

      \ Check zone 3
      dist ZONE3_MIN >= 
      dist ZONE3_MAX <= and
      if 
        1 +to zone3Count
        zone3Count EVENT_THRESHOLD >
        if
          reset
          event3
        then
      then


      \ Check zone 4
      dist ZONE4_MIN >= 
      dist ZONE4_MAX <= and
      if 
        1 +to zone4Count
        zone4Count EVENT_THRESHOLD >
        if
          reset
          event4
        then
      then

      ." Dist in Inches: " dist . cr
    then
    100 delay

    false
  until

;










