\
\ I2C 1 to 8 Multiplexer
\ Written for ESP32forth
\ Concept, Design and Implementation by Craig A. Lindley
\ Last Update: 05/11/2022

\ Select Wire vocabulary
Wire

    21 constant I2C_SDA
    22 constant I2C_SCL
400000 constant I2C_FREQ
   $70 constant I2C_MUX_ADDR

\ Initialize the Wire library for using I2C
: initI2C ( -- f )
  I2C_SDA I2C_SCL Wire.begin
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

\ Select which I2C interface of the mux should be selected. 0 .. 7
\ Selection remains in effect until changed
: muxChannelSelect { ch } ( ch -- f )
  ch 0 >= ch 7 <= and
  if 
    I2C_MUX_ADDR Wire.beginTransmission
    1 ch << Wire.write drop
    true Wire.endTransmission 0=
    if 
      true
    else
      ." muxChannelSelect error" cr
      false
    then
  else
    ." Channel out of range error" cr
    false
  then
;
