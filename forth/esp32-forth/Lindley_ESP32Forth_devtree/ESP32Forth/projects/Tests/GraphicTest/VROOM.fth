\
\ Hardware Description of ESP32 VROOM hardware
\ Connected to RA8876 LCD display
\ Written by: Craig A. Lindley
\ Last Update: 11/03/2024

\ RA8876 LCD display using the HSPI interface
13 constant LCD_MOSI
12 constant LCD_MISO
14 constant LCD_SCK
15 constant LCD_CS
27 constant LCD_RESET
26 constant LCD_BL
25 constant LCD_WAIT

24000000 constant SPI_FREQ

\           GPIO Connections
\   ESP32     Signal Name   LCD Display
\    15        GPIO15         CS
\    13        MOSI          DIN
\    14        CLK           CLK
\    12        MISO          DOUT
\    25       GPIO25         WAIT
\    26       GPIO26         BL
\    27       GPIO27        RESET
\    USB        +5           VCC
\    Gnd        GND          GND
