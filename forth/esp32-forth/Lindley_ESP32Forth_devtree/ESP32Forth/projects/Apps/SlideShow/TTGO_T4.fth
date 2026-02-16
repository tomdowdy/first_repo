\
\ Hardware Description of TTGO T4 V1.0 hardware
\ Written by: Craig A. Lindley
\ Last Update: 08/25/2021

\ HSPI interface for SD card 
 2 constant SD_MISO
15 constant SD_MOSI
14 constant SD_CLK
13 constant SD_CS
40000000 constant SD_FREQUENCY

\ VSPI hardware interface for LCD display
23 constant LCD_MOSI
12 constant LCD_MISO
18 constant LCD_SCK

\ LCD GPIO connections
 5 constant LCD_RESET
26 constant LCD_DC
27 constant LCD_CS
 4 constant LCD_BL

\ LCD display dimensions
240 constant LCD_WIDTH
320 constant LCD_HEIGHT

\ Buttons connections
38 constant BUTTON_1
37 constant BUTTON_2
39 constant BUTTON_3
