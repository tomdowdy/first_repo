\ BMP File Reader
\ NOTE: This code is hardcoded for 320x240 32 bit image
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 08/29/2021

\ Function called for each row of BMP file
defer ROW_DISPLAYER

\ Buffer is big enough for a row of 320 32 bit pixels
       1280 constant BUFFER_SIZE
BUFFER_SIZE byteArray buffer

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
  readIndex buffer c@ 
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

  \ Attempt to open BMP file
  r/o open-file 0=
  if
    to fid
  else
    ." File open failed" cr
    false
    exit
  then

  \ Read BMP header into buffer
  0 buffer 14 fid read-file 0=
  if 
    drop
  else
    ." File read failed" cr
    fid close-file drop
    false
    exit
  then
  
  \ Decode BMP header
  readShort to fileType
  readLong  to fileSize
  readShort drop
  readShort drop
  readLong  to pixelDataOffset

  \ Reset read index
  0 to readIndex

  \ Read DIB header into buffer
  0 buffer 40 fid read-file 0=
  if 
    drop
  else
    ." File read failed" cr
    fid close-file drop
    false
    exit
  then

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

  \ Seek to start of image data
  pixelDataOffset fid reposition-file 0 <>
  if
    ." File reposition failed"
    fid close-file drop
    false
    exit
  then

  \ Process each row of BMP data
  240 0
  do
    \ Read row data into buffer
    0 buffer BUFFER_SIZE fid read-file 0=
    if 
      drop
    else
      ." File read failed" cr
      fid close-file drop
      false
      exit
    then

    \ Check for orientation of image
    imageHeight 0 <
    if
      i to rn
    else
      239 i - to rn 
    then

    \ Do defered callback
    rn ROW_DISPLAYER
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

: showBMPAttributes ( -- )
  cr

  ." File Type: " fileType . cr
  ." File Size: " fileSize . cr
  ." Pixel Data Offset: " pixelDataOffset . cr
  ." Header Size: " headerSize . cr
  ." Image Width: " imageWidth . cr
  ." Image Height: " imageHeight . cr
  ." Planes: " planes . cr
  ." BPP: " bpp . cr
  ." Compression: " compression . cr
  ." Image Size: " imageSize . cr
cr
;














