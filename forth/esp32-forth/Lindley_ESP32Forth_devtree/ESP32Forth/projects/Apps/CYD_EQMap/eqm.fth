\ Earth Quake Mapping Program
\ for the cheap Yellow Display module
\ Design and Implementation by: Craig A. Lindley
\ Last Update: 11/18/2023

\ EQ event data polled every minute
60 1000 * constant ACQ_DISP_TIME_MS

\ Blinks happen every half second
500 constant BLINK_TIME_MS

\ Variables holding future times for action
0 value futureTimeAD
0 value futureTimeBL

0 value blinkToggle
0 value errorCount

0 value scnX
0 value scnY
0 value mag

WiFi

: doLogin z" CraigNet" z" craigandheather" login 3000 ms ;

Forth

\ Row displayer function
0 value __row 
0 value __r
0 value __g 
0 value __b 
0 value __p

\ Function for displaying a row of BMP image data
: displayRow ( row -- )
   to __row
  0 to __p
  imageWidth 0
  do
    __p rowBuffer c@ to __b
    1 +to __p
    __p rowBuffer c@ to __g
    1 +to __p
    __p rowBuffer c@ to __r
    2 +to __p

    i __row MAP_Y_OFFSET + __r __g __b color565 pixel
  loop
;

\ Display the map on the screen
: displayMap
  s" /spiffs/ERP320.bmp" readBMPFile drop
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
  now toLocal >r r@ hourFormat12_t

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
  0 FORMAT_BUFFER indx getStringWidth getLCDWidth swap -
  8 0 FORMAT_BUFFER indx pString  

  \ Clean up
  r> drop
;

\ Format quake magnitude and display
: formatDisplayMagnitude ( -- ) 

  \ Initialize format buffer index
  0 to indx

  s" Mag: " $cat
  MAG_BUF getString $cat

  \ Print the magnitude
  0 8 0 FORMAT_BUFFER indx pString  
;

0 value _addr
0 value _n

\ Display location of quake
\ Text size depends upon length of location text string
: displayLocation ( -- )
  LOC_BUF getString to _n to _addr

  3 setTextSize
  _addr _n getStringWidth getLCDWidth swap - 2 >
  if 
    215 _addr _n pCenteredString
    2 setTextSize 
    exit
  then

  2 setTextSize
  _addr _n getStringWidth getLCDWidth swap - 2 >
  if 
    220 _addr _n pCenteredString
    exit
  then

  1 setTextSize
  220 _addr _n pCenteredString
  2 setTextSize 
;

\ Display indication of severity with color
: displaySeverity ( -- )
  0 { color }
  mag 
  case
    2 of GREEN to color endof
    3 of GREEN to color endof
    4 of YELLOW to color endof
    5 of YELLOW to color endof
    6 of RED to color endof
    7 of RED to color endof
    8 of RED to color endof
    9 of RED to color endof
  endcase
  110 6 100 charSpaceHeight color fillRect2
;

\ Display all EQ events in db
: displayEQEvents ( -- )
  numberOfRecords 0
  do
    i getScnX i getScnY i getMag WHITE circle
  loop
;

\ Convert a string containing a floating point number 
\ without an "e" specifier to a float. This method
\ does not work if the string has an "e" in it. In
\ this application there will never be float strings
\ with "e"s.
: stringToFloat ( addr n -- ) ( -- float )
  false  { negFlag }

  \ Check first char in string for minus sign
  over c@ $2D =
  if
    true to negFlag
  then
  f>number?
  drop
  \ We have a float on the float stack
  negFlag
  if
    -1e f*
  then
;

\ Acquire EQ event data and display results on map
: AcqDisplay ( -- )
  \ Acquire an event
  getEvent
  if
    ." Got event" cr

    \ Reset error count
    0 to errorCount

    \ Parse the returned JSON
    runParser

    \ Is this a new event
    checkNewEvent
    if 
      ." Got new event" cr

      clearScreen

      \ Display the map
      displayMap

      \ Display time upper right
      formatDisplayTime

      \ Display magnitude upper left
      formatDisplayMagnitude

      \ Display location
      displayLocation

      \ Convert lat, long and mag to useful numbers
      LON_BUF getString stringToFloat lonToMapX to scnX
      LAT_BUF getString stringToFloat latToMapY to scnY

      \ Magnitude is rounded to nearest int value
      MAG_BUF getString stringToFloat f>s to mag
      mag 2 < if 2 to mag then

      \ Add event to db
      scnX scnY mag addNewRecord

      \ Display all EQ events in db
      displayEQEvents

      \ Display severity of EQ event in color
      displaySeverity
    then
  else
    ." Error getting event" cr
    1 +to errorCount
    
    errorCount 10 >
    if 
      clearScreen
      3 setTextSize
      RED setFGColor
      40 s" Error Reset" pCenteredString
      bye
    then
  then
;

Forth

\ Blink latest event on map
: blink ( -- )
  blinkToggle
  if
    scnX scnY mag RED circle
    FALSE to blinkToggle
  else
    scnX scnY mag YELLOW circle
    TRUE to blinkToggle
  then
;

\ Setup the app
: setup ( -- )

  0 to errorCount

  3 initLCD
  clearScreen
  cr

  2 setTextSize

  \ Record callback address for map display
  ['] displayRow is ROW_DISPLAYER

  \ Login to WiFi network
  doLogin

  \ Set mountain time zone
  usMT setTZ

  \ Request time to sync ntp to sys time
  now toLocal hourFormat12_t drop

  TRUE to blinkToggle
;


\ Run the app
: run ( -- )
  setup

  \ Loop forever
  begin
    MS-TICKS futureTimeAD >
    if
      MS-TICKS ACQ_DISP_TIME_MS + to futureTimeAD
      AcqDisplay
    then
    MS-TICKS futureTimeBL >
    if
      MS-TICKS BLINK_TIME_MS + to futureTimeBL
      blink
    then
    false
  until
;

\ Make the app persistent
\ startup: run







