\ World Clock Application
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 08/14/2021

\ Set TRUE for 12 hour format; FALSE for 24 hour format
true constant 12HF

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

\ Show the format buffer
: showFB ( -- )
  0 FORMAT_BUFFER indx type
;

\ Prepare display for formatting
: prepareDisplay ( -- )
  \ Clear display
  clearLCD

  \ Draw rounded rect around display
  0 0 _width_ 1- _height_ 1- 8 BLU roundedRect
;

\ Display time and date. Assumes theTZ set before call
: displayTime&Date

  \ Get the UTC time and convert it to local time
  now toLocal >r

  \ Prepare display
  prepareDisplay

  \ Print using larger text
  3 setTextSize

  \ Print the name of the city
  5 theTZ .index @ tzNameFromIndex pCenteredString

  \ Print day of the week
  38 r@ weekDay_t getDayName pCenteredString
   
  \ Initialize format buffer index
  0 to indx

  \ Format date string like: Jan 18, 2017
  r@ month_t   getMonName $cat addSpace
  r@ day_t     #to$ $cat s" , " $cat
  r@ year_t    #to$ $cat
  \ Print the centered date line
  71 0 FORMAT_BUFFER indx pCenteredString  

  \ Initialize format buffer index
  0 to indx

  \ Format the time string like: 9:59 AM
  r@ 
  12HF
  if
    hourFormat12_t
  else
    hour_t
  then
  #to$ $cat s" :" $cat

  \ If minutes single digit 0..9 add leading zero to string 
  r@ minute_t 10 <
  if
    s" 0" $cat
  then

  r@ minute_t #to$ $cat
  addSpace

  r@ isAM_t if 0 getAMPM else 1 getAMPM then $cat

  \ Print the centered time line
  102 0 FORMAT_BUFFER indx pCenteredString  
 
  \ Clean up
  r> drop
;


WiFi

0 value _tz

\ Run the world clock app
: wc cr cr

  z" CraigNet" z" craigandheather" login cr
  2000 MS

  \ Initialize the LCD controller
  3 initLCD

  prepareDisplay

  \ Draw fixed text
  GRN to FGColor
  2 setTextSize
  5  s" Forth World Clock" pCenteredString
  66 s" Craig A. Lindley"  pCenteredString

  2000 MS

  begin
    _tz
    case
      0 of ausET setTZ endof
      1 of CE    setTZ endof
      2 of UK    setTZ endof
      3 of usET  setTZ endof
      4 of usCT  setTZ endof
      5 of usMT  setTZ endof
      6 of usAZ  setTZ endof
      7 of usPT  setTZ endof
    endcase

    \ Print the time and data for selected time zone
    displayTime&Date

    1 +to _tz
    _tz 7 >
    if
      0 to _tz
    then

    \ Wait 30 seconds
    30000 MS
  again
;

forth
