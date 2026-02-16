\
\ Hardware Description of ESP32 VROOM hardware for the Desk Gadget
\ Written by: Craig A. Lindley
\ Last Update: 12/13/2021

\ SPI frequency for LCD
20000000 constant LCD_SPI_FREQUENCY

\ SPI frequency for touch screen controller
1000000 constant TS_SPI_FREQUENCY

\ ILI9341 LCD isplay pins using the HSPI interface
13 constant LCD_MOSI
12 constant LCD_MISO
14 constant LCD_SCK
 2 constant LCD_CS
 4 constant LCD_RESET
16 constant LCD_DC
17 constant LCD_BL


\ XPT 2046 Touch Controller
22 constant T_CS
21 constant T_IRQ

\ ESP32 pin 13 connected to MOSI on LCD and T_DIN  on touch controller
\ ESP32 pin 12 connected to MISO on LCD and T_DOUT on touch controller
\ ESP32 pin 14 connected to SCK  on LCD and T_CLK  on touch controller





