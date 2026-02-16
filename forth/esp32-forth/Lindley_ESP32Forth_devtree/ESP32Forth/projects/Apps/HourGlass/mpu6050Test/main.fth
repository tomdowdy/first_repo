\ MPU6050 Test Code
\ Written in ESP32Forth
\
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 07/19/2022

100 constant NUM_OF_SAMPLES

\ ********************* Support Functions ******************

\ Select Wire vocabulary
Wire

\ Initialize the Wire library in ESP32Forth for using I2C
: initI2C ( -- f )
  MPU_SDA MPU_SCL Wire.begin
  0=
  if 
    \ Initialization Error
    ." Initialization error occurred" cr
    false
  else
    I2C_FREQ Wire.setClock
    true
  then
;

fvariable XTotal
fvariable YTotal

\ Take numerous samples for average
: takeSamples
  0.0e XTotal sf!
  0.0e YTotal sf!

  NUM_OF_SAMPLES 0
  do
    mpuUpdate
    10 delay

    angleX sf@ XTotal sf@ f+ XTotal sf!
    angleY sf@ YTotal sf@ f+ YTotal sf!
  loop
  XTotal sf@ NUM_OF_SAMPLES s>f f/ ." angleX: " f. cr
  YTotal sf@ NUM_OF_SAMPLES s>f f/ ." angleY: " f. cr
;


\ ********************* Program Entry ******************

: main
  cr

  \ Initialize I2C interface
  initI2C drop

  \ Initialize MPU6050
  initMPU6050
  calcGyroOffsets

  begin

    mpuUpdate

\    ." AngleX: " angleX sf@ f. ."  AngleY: " angleY sf@ f. ."  AngleZ: " angleZ sf@ f. cr
    takeSamples

\    100 delay
    false
  until
;

only forth
