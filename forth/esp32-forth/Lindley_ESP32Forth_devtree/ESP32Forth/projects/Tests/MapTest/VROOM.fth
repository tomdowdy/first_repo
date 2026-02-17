\
\ Hardware Description of ESP32 VROOM hardware
\ Written by: Craig A. Lindley
\ Last Update: 09/16/2021

\ RA8876 LCD display using the VSPI interface
23 constant LCD_MOSI
19 constant LCD_MISO
18 constant LCD_SCK
 5 constant LCD_CS
 4 constant LCD_RESET
26 constant LCD_BL
27 constant LCD_WAIT

\ SD card using the HSPI interface
13 constant SD_MOSI
12 constant SD_MISO
14 constant SD_SCK
15 constant SD_CS

4000000 constant SPI_FREQ


\                 GPIO Connections
\   ESP32     Signal Name   LCD Display     SD Card
\    15        GPIO5                          CS
\    13        H_MOSI                         DIN
\    14        H_CLK                          CLK
\    12        H_MISO                         DOUT
\    23        V_MOSI          SDI
\    19        V_MISO          SDO 
\    18        V_CLK           CLK
\     5        GPIO15          CS
\    27        GPIO27          WAIT
\     4        GPIO4           RESET
\    26        GPIO26          BL
\    VIn                       VCC            VCC
\    Gnd                       GND            GND

