\ Pocket Watch Code


\ BMP row display function
: rowDisplayer { rn }

  0 0 0 0 { p r g b }
  
  240 0
  do
    p buffer c@ to b
    1 +to p
    p buffer c@ to g
    1 +to p
    p buffer c@ to r
    2 +to p
    i rn r g b color565 pixel
  loop
;

' rowDisplayer is ROW_DISPLAYER

\ Program entry point
: main ( -- )
  cr
  0 initLCD

  s" /spiffs/Elgin-Dial.bmp" readBMPFile
  if 
    ." success" cr
  else
    ." failure" cr
  then




;
