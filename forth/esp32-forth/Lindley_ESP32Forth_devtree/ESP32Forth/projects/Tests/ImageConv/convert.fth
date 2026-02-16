\ BMP File Converter
\ NOTE: This code is hardcoded for 800 pixel wide 32 bit images
\ Converts 800x503 32 bit BMP image to a data block of 16 bit (565) pixels
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 09/18/2021


\ SD card using the HSPI interface
13 constant SD_MOSI
12 constant SD_MISO
14 constant SD_SCK
15 constant SD_CS

4000000 constant SPI_FREQ

\ Pass 8-bit (each) R,G,B, get back 16-bit packed color
: color565 { r g b } ( r g b -- color16 )
  r $F8 and 8 <<
  g $FC and 3 <<
  b $F8 and 3 >>
  or or
;

\ Function called for each row of BMP file
defer ROW_WRITER

\ Buffer is big enough for a row of 800 32 bit pixels
       3200 constant ROW_BUFFER_SIZE
ROW_BUFFER_SIZE byteArray rowBuffer

\ File ID
0 value fid

0 value readIndex

\ BMP header data
0 value fileType
0 value fileSize
0 value pixelDataOffset

\ DIB header data
0 value headerSize
0 value imageWidth
0 value imageHeight
0 value planes
0 value bpp
0 value compression
0 value imageSize
0 value rn

: readByte ( -- n)
  readIndex rowBuffer c@ 
  1 +to readIndex
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

\ Open the BMP file and extract in all attributes
: readBMPFile ( addr u -- f )

  0 to readIndex

2dup type

  \ Attempt to open BMP file
  r/o open-file 0=
  if
    to fid
  else
    ." File open failed" cr
    false
    exit
  then

." Y0" cr

  \ Read BMP header into buffer
  0 rowBuffer 14 fid read-file 0=
  if 
    drop
." Y0a" cr
  else
    ." File read failed" cr
    fid close-file drop
." Y0b" cr
    false
    exit
  then

." Y1" cr
  
  \ Decode BMP header
  readShort to fileType
  readLong  to fileSize
  readShort drop
  readShort drop
  readLong  to pixelDataOffset

  \ Reset read index
  0 to readIndex

  \ Read DIB header into buffer
  0 rowBuffer 40 fid read-file 0=
  if 
    drop
  else
    ." File read failed" cr
    fid close-file drop
    false
    exit
  then

." Y2" cr

  \ Decode DIB header
  readLong to headerSize
  readLong to imageWidth

  \ if imageHeight is negative the image is stored
  \ top to bottom not bottom to top
  readLong to imageHeight

  readShort to planes
  readShort to bpp
  readLong to compression
  readLong to imageSize

  \ Make sure this is a BMP file
  fileType $4D42 <>
  if 
    ." Not a BMP file" cr
    fid close-file drop
    false
    exit
  then

." Y3" cr 

  32 bpp <> 
  if
    ." Image not 32 bpp" cr
    fid close-file drop
    false
    exit
  then
 
  compression 0 <>
  if
    ." Image is compressed" cr
    fid close-file drop
    false
    exit
  then

." Y4" cr

  \ Seek to start of image data
  pixelDataOffset fid reposition-file 0 <>
  if
    ." File reposition failed"
    fid close-file drop
    false
    exit
  then

." Y5" cr

  \ Process each row of BMP data
  imageHeight abs 0
  do
    \ Read row data into buffer
    0 rowBuffer ROW_BUFFER_SIZE fid read-file 0=
    if 
      drop
    else
      ." File read failed" cr
      fid close-file drop
      false
      exit
    then

." Y6" cr


    \ Check for orientation of image
    imageHeight 0 <
    if
      i to rn
    else
      imageHeight 1- i - to rn 
    then

    \ Do defered callback
    rn ROW_WRITER
  loop

." Y7" cr

  \ Success, close the file
  fid close-file 0 <>
  if 
    ." File close failed"
    false
    exit
  then
  true
;

10 byteArray outBuf

\ Convert image
: convertImage
  s" /sdcard/ERP800.bmp" readBMPFile . cr ;

0 value fid2

: writePixel ( color16 row -- )
  403 <
  if 
   dup
   8 >>    0 outBuf c!
   $ff and 1 outBuf c!

   0 outBuf 2 fid2 write-file drop
  then
;

\ Row writer function
0 value __r
0 value __g 
0 value __b 
0 value __p

\ Function for displaying a row of BMP image data
: writeRow { row } ." Row: " row . cr
  0 to __p
  imageWidth 0
  do
    __p rowBuffer c@ to __b
    1 +to __p
    __p rowBuffer c@ to __g
    1 +to __p
    __p rowBuffer c@ to __r
    2 +to __p

    __r __g __b color565 row writePixel
  loop
;

SD also

: run
  cr
." H0" cr

  \ Initialize SD card
  SD_SCK SD_MISO SD_MOSI SD_CS SPI_FREQ 2 SD.begin not
  if ." Problem initializing SD card" exit then

." H1" cr

  \ Record callback address for map display
  ['] writeRow is ROW_WRITER
." H2" cr

  \ Delete file if it exists
  s" /sdcard/imgfile" delete-file . cr

  \ Attempt to create the output image file
  s" /sdcard/imgfile" w/o create-file 0=
  if
    to fid2
  else
    ." File create failed" cr
    false
    exit
  then
." H3" cr

  s" /sdcard/ERP800.bmp" readBMPFile . cr

." H4" cr

  fid2 close-file . cr
." H5" cr

;










