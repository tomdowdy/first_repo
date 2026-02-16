\ Pseudo Nixie Clock Hardware

\ LCD display dimensions (unrotated)
 80 constant LCD_WIDTH
160 constant LCD_HEIGHT

\ LCD signals
\ LCD display uses the VSPI interface in ESP32Forth
 5 constant LCD_CS_PIN
18 constant LCD_SCLK_PIN
22 constant LCD_BL_PIN
23 constant LCD_MOSI_PIN
26 constant LCD_DC_PIN
33 constant LCD_RESET_PIN

\ SPI frequency for LCD
4000000 constant LCD_SPI_FREQUENCY

