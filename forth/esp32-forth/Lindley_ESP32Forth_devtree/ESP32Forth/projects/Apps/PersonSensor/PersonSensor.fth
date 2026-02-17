\ Person(s) Detector App
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 07/14/2023

\ Program entry point
: main ( -- )
  cr

  \ Initialize LCD driver into landscape mode with connector on right
  3 initLCD
  clearLCD

  \ Initialize I2C interface for person sensor
  initI2C

  \ Configure interrupt pin
  \ A read returns 1 when seeing a face; 0 otherwise
  PS_INT_PIN INPUT_PULLUP pinMode

  begin
    PS_INT_PIN digitalRead
    1 =
    if
      clearLCD

      \ Clear the data buffer
      0 PS_DATA PS_PACKET_SIZE erase
 
      ." Attempting read from sensor"
      cr

      \ Attempt data read
      psRead
      if
        ." Read successful"
      else
        ." Read failed"
      then
      cr

      \ Show returned data in buffer
      \ showBuffer
      \ cr

      0 0 0 0 0 0 { faceOffset color x0 y0 x1 y1 }

      getNumberOfFaces 0 >
      if
        getNumberOfFaces 0
        do
          i
          case
            0 of OFFSET_F1 to faceOffset BLU to color endof
            1 of OFFSET_F2 to faceOffset GRN to color endof
            2 of OFFSET_F3 to faceOffset YEL to color endof
            3 of OFFSET_F4 to faceOffset RED to color endof
          endcase

          faceOffset getBoxConfidence 85 >
          if
            \ Map sensor values to LCD values
            faceOffset getBoxLeft   128 * 256 / to x0
            faceOffset getBoxTop    128 * 256 / to y0
            faceOffset getBoxRight  128 * 256 / to x1
            faceOffset getBoxBottom 128 * 256 / to y1

            \ Draw rect on LCD
            \ 16 + is to skip unused horiz portion of LCD
            x0 16 + y0 x1 16 + y1 color fillRect

            \ If face is facing draw black line in rect
            faceOffset getIsFacing 1 =
            if
              x0 x1 + 2 / 16 +
              y0 
              y1 y0 - BLK vLine
            then
          then
        loop
        10000 delay
      then
    then
    false
  until
;

Forth


