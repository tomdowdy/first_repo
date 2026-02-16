\
\ Hardware Description for the Cheap-Yellow-Display or CYD
\ Actual device: ESP32-2432S028R
\ See: https://github.com/witnessmenow/ESP32-Cheap-Yellow-Display/tree/main
\ Written by: Craig A. Lindley
\ Last Update: 11/10/2023
\

\ ILI9341 LCD isplay pins using the HSPI interface
13 constant LCD_MOSI
12 constant LCD_MISO
14 constant LCD_SCK
15 constant LCD_CS
 2 constant LCD_DC
21 constant LCD_BL

\ Touch Screen XPT2046
25 constant XPT2046_CLK
32 constant XPT2046_MOSI
33 constant XPT2046_CS
36 constant XPT2046_IRQ
39 constant XPT2046_MISO

\ SD card
 5 constant SD_CS
18 constant SD_SCK
19 constant SD_MISO
23 constant SD_MOSI

\ RGB LED
 4 constant LED_RED
16 constant LED_GRN
17 constant LED_BLU

\ Light Sensor
34 constant LIGHT_SENSOR

\ Broken Out GPIO pins

\ Connector P3
\  GND
35 constant IO35
22 constant IO22
21 constant IO21 \ Used for LCD_BL

\ Connector CN1
\ GND
\ 22 constant IO22 \ Also in P3 above
27 constant IO27
\ 3.3V

\ Connector P1
 1 constant IO1 \ TX might be usable as GPIO pin
 3 constant IO3 \ RX might be usable as GPIO pin
\ GND

\ Button
 0 constant BOOT_Button

\ Speaker
26 constant SPEAKER_OUT \ Used to drive Amp so not usable







