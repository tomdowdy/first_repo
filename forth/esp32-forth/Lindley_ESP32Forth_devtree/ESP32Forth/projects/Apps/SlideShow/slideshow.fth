\ Slide Show App for the ILI9341 LCD on the TTGO T4
\ Run load to load all prerequisites
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 08/25/2021

\ Open SD vocabulary
SD

\ Function called for displaying row data from BMP file
defer ROW_DISPLAYER

\ Buffer is big enough for a row of 320 32 bit pixels
1280 constant BUFFER_SIZE
BUFFER_SIZE bytearray buffer

\ File ID
variable fid

variable readIndex

\ BMP header data
variable fileType
variable fileSize
variable pixelDataOffset

\ DIB header data
variable headerSize
variable imageWidth
variable imageHeight
variable planes
variable bpp
variable compression
variable imageSize

: readByte ( -- n)
  readIndex @ buffer c@ 
  1 readIndex +!
;

: readShort ( -- n )
  readByte
  readByte 8 <<
  or
;

: readLong ( -- n )
  readByte
  readByte  8 <<
  readByte 16 <<
  readByte 24 <<
  or or or
;

\ Open the BMP file and read in all attributes
: readImageAttributes ( addr u -- f )

  0 readIndex !

  \ Attempt to open BMP file
  r/o open-file 0=
  if
    fid !
  else
    ." File open failed" cr
    false
    exit
  then

  \ Read BMP header into buffer
  0 buffer 14 fid @ read-file 0=
  if 
    drop
  else
    ." File read failed" cr
    false
    exit
  then
  
  \ Decode BMP header
  readShort fileType !
  readLong  fileSize !
  readShort drop
  readShort drop
  readLong  pixelDataOffset !

  \ Reset read index
  0 readIndex !

  \ Read DIB header into buffer
  0 buffer 40 fid @ read-file 0=
  if 
    drop
  else
    ." File read failed" cr
    false
    exit
  then

  \ Decode DIB header
  readLong headerSize !
  readLong imageWidth !

  \ if imageHeight is negative the image is stored top to bottom not bottom to top
  readLong imageHeight !

  readShort planes !
  readShort bpp !
  readLong compression !
  readLong imageSize !

  \ Close the BMP file
  fid @ close-file 0 <>
  if
    ." File close failed"
    false
    exit
  then
  true
;

\ Can only process true color BMP files with no compression
: checkBMPFile ( addr u -- f )

  \ Read image attributes into variables
  readImageAttributes
  if 
    \ Make sure this is a BMP file
    fileType @ $4D42 <>
    if 
      ." Not a BMP file" cr
      false
      exit
    then

    32 bpp @ <> 
    if
      ." Image not 32 bpp" cr
      false
      exit
    then
 
    compression @ 0 <>
    if
      ." Image is compressed" cr
      false
      exit
    then
    true
  then
;

0 value __row
0 value __r
0 value __g
0 value __b
0 value __p

\ Function for displaying a row of BMP image data
: displayRow ( row -- )
   to __row
  0 to __p
  320 0
  do
    __p buffer c@ to __b
    1 +to __p
    __p buffer c@ to __g
    1 +to __p
    __p buffer c@ to __r
    2 +to __p

    i __row __r __g __b color565 pixel
  loop
;

\ Initialize hardware to display BMP images
: initImageViewer ( -- )

  \ Initialize the LCD controller to landscape mode
  1 initLCD

  \ Clear the LCD to black
  clearScreen

  \ Initialize SD interface
  SD_CLK SD_MISO SD_MOSI SD_CS SD_FREQUENCY 2 SD.begin . cr

  \ Record callback address
  ['] displayRow is ROW_DISPLAYER
;

variable __rn

\ Display BMP images
: displayBMP { fns fnl }

  fns fnl checkBMPFile
  if
    \ Attempt to open BMP file
    fns fnl r/o open-file 0=
    if
      fid !
    else
      ." File open failed" cr
      false
      exit
    then

    \ Seek to start of image data
    0 buffer pixelDataOffset @ fid @ read-file 0=
    if
      drop
    else
      ." File reposition failed"
      false
      exit
    then

    \ Process each row of BMP data
    240 0
    do
      \ Read row data into buffer
      0 buffer BUFFER_SIZE fid @ read-file 0=
      if 
        drop
      else
        ." File read failed" cr
        false
        exit
      then

      \ Check for orientation of image
      imageHeight @ 0 <
      if
        i __rn !
      else
        239 i - __rn ! 
      then

      \ Do defered callback
      __rn @ ROW_DISPLAYER
    loop

    fid @ close-file 0 <>
    if 
      ." File close failed"
      false
      exit
    then
    true
  then
;

\ Format buffer
20 bytearray FORMAT_BUFFER
variable indx

\ Copy a string into format buffer
: cat$  ( addr count -- )  
  indx @ FORMAT_BUFFER ( addr count -- addr count dAddr )
  swap dup >r
  cmove
  r> indx +!
;

\ Convert single number >= 0 to a string
\ : #to$ ( n -- addr count )
\  s>d <# #s #>
\ ;

\ Main application word
: slideshow ( -- )
  initImageViewer

  begin
    21 1
    do
      0 indx !

      s" /sdcard/I" cat$
      i str         cat$
      s" .bmp"      cat$

      0 FORMAT_BUFFER indx @
      displayBMP
      2000 MS
      clearScreen
    loop
   false
  until
;


















