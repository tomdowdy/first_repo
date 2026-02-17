\
\ Hourglass Hardware Description 
\ ESP32 D1 Mini
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 07/10/2022

\ ESP32 D1 Mini  LED Matrix  Rotary Encoder  MPU6050
\ ==================================================== 
\   0               
\   2
\   4
\   5               CS
\   16
\   17
\   18          CLK (VSPI)
\   19
\   21                                         SDA
\   22                                         SCL
\   23          DIN (VSPI)
\   25                         + PIN
\   26                         - PIN
\   27                           SW
\   32
\   33
\   34
\   35
\   VCC (5V)     VCC                          VCC
\   3.3V                                      
\   GND          GND            GND           GND

\ Forth Constants

\ SPI frequency
400000 constant SPI_FREQ

\ I2C frequency
400000 constant I2C_FREQ

\ LED matrix pins using the VSPI interface
23 constant LED_DIN
18 constant LED_CLK
 5 constant LED_CS

\ Rotary Encoder GPIO pins
25 constant RE_PLUS
26 constant RE_MINUS
27 constant RE_SW

\ MPU6050 pins using the I2C interface
\ I2C address $68
$68 constant MPU_ADDR
 21 constant MPU_SDA
 22 constant MPU_SCL




