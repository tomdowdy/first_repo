\ I2C Scanner Test Code
\ Written for ESP32Forth
\ Last Update: 05/09/2022

: doI2CScan
  cr
  \ Initialize the I2C interface
  initI2C drop
  if
    cr
    ." Scanner Ready" 
    cr
    \ 8 possible I2C interfaces on multiplexer
    8 0
    do
      ." Selecting interface: " i . cr
      \ Select a multiplexer interface
      i muxChannelSelect
      if
        \ Select successful
        \ 128 possible I2C addresses
        128 0
        do
          \ Skip the multiplexer's address
          i I2C_MUX_ADDR <>
          if
            i Wire.beginTransmission
            true Wire.endTransmission 0=
            \ 0 return is success
            if
              ." Found device at addr: " i .hex cr
            then
          then
        loop
      then
    loop
    ." Scanning done" cr
  then
;

