\
\ Hardware Description of Adafruit MagTag ESP32 Module
\ ESP32-S2 WROVER with 4MB flash and 2MB PSRAM
\ EPD refers to E-Paper-Display
\ Written by: Craig A. Lindley
\ Last Update: 03/01/2023

\ EPD display dimensions unrotated
128 constant EPD_WIDTH
296 constant EPD_HEIGHT

\ SPI frequency for EPD
4000000 constant EPD_SPI_FREQUENCY

\ EPD display pins using the HSPI interface - 296x128
 5 constant EPD_BUSY
 6 constant EPD_RESET
 7 constant EPD_DC
 8 constant EPD_CS
35 constant EPD_MOSI
36 constant EPD_SCK
37 constant EPD_MISO

\ NeoPixels
\ GPIO21 must set set to output and set LOW
 1 constant NEOPIXEL_PIN
21 constant NEOPIXEL_POWER

\ Built in LED
13 constant LED_BUILTIN

\ Light sensor
 3 constant LIGHT_SENSOR

\ Buttons
15 constant BUTTON_A
14 constant BUTTON_B
12 constant BUTTON_C
11 constant BUTTON_D

\ Speaker
17 constant SPEAKER
16 constant SPEAKER_ENABLE

\ Voltage monitor
 4 constant VOLTAGE_MONITOR

\ Accelerometer interrupt
 9 constant ACC_INT

\ Left front connector (L->R)
\ Pin 1 GND
\ Pin 2 VCC
\ Pin 3 GPIO18

\ Center front connector
\ Pin 1 SCL GPIO34
\ Pin 2 SDA GPIO33
\ Pin 3 3.3V
\ Pin 4 GND

\ Right front connector
\ Pin 1 GND
\ Pin 2 VCC
\ Pin 3 GPIO10


