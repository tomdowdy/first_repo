
\ Screen dimensions
1024 constant SCREEN_WIDTH
 600 constant SCREEN_HEIGHT

\ Equirectangular map dimensions
800 constant MAP_WIDTH
403 constant MAP_HEIGHT

MAP_WIDTH 2* byteArray rowBuffer


SCREEN_WIDTH  MAP_WIDTH  - 2 / constant MAP_X_OFFSET
SCREEN_HEIGHT MAP_HEIGHT - 2 / constant MAP_Y_OFFSET

MAP_WIDTH 2* constant BUFFER_SIZE
BUFFER_SIZE byteArray

0 value fid
0 value p
0 value bH
0 value bL

\ Display the processed image
: displayMap

  s" /sdcard/imgfile" 

  \ Attempt to open image file
  r/o open-file 0=
  if
    to fid
  else
    ." File open failed" cr
    false
    exit
  then

  MAP_HEIGHT MAP_Y_OFFSET + MAP_Y_OFFSET
  do
    \ Read row data into buffer
    0 rowBuffer BUFFER_SIZE fid read-file 0=
    if 
      drop
    else
      ." File read failed" cr
      fid close-file drop
      false
      exit
    then

    0 to p

    MAP_WIDTH MAP_X_OFFSET + MAP_X_OFFSET 
    do
      p rowBuffer c@ to bH
      1 +to p
      p rowBuffer c@ to bL
      1 +to p
      i j bH 8 << bL or drawPixel
    loop
  loop

  \ Success, close the file
  fid close-file 0 <>
  if 
    ." File close failed"
    false
    exit
  then
  true
;

  
SD also 

: run

  \ Initialize SD card
  SD_SCK SD_MISO SD_MOSI SD_CS SPI_FREQ 2 SD.begin not
  if ." Problem initializing SD card" exit then
  
  \ Initialize display
  begin not
  if ." Problem initializing display" exit then
  clearScreen

  50 50 s" Display in on" drawTextString

  displayMap
;

Forth



