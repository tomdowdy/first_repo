\
\ Hardware Description for ESP32 MIDI Sequencer
\
\ NOTE: all GPIO pins of ESP32 are used by the sequencer
\       Change pin assignments at your own risk!
\
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 05/11/2023
\

\ Sequencer step button GPIO pins
 2 constant B0_PIN
 4 constant B1_PIN
 5 constant B2_PIN
12 constant B3_PIN
13 constant B4_PIN
14 constant B5_PIN
15 constant B6_PIN
39 constant B7_PIN

\ Sequencer step button LEDs each driven through a 1K ohm resistor
16 constant B0LED_PIN
19 constant B1LED_PIN
21 constant B2LED_PIN
22 constant B3LED_PIN
25 constant B4LED_PIN
26 constant B5LED_PIN
27 constant B6LED_PIN
32 constant B7LED_PIN

\ Rotary encoder signals. Plus and Minus pins pulled up with 10K ohm resistors
34 constant RE_SW_PIN
35 constant RE_MINUS_PIN
36 constant RE_PLUS_PIN

\ LCD display dimensions (unrotated)
128 constant LCD_WIDTH
160 constant LCD_HEIGHT

\ LCD signals
\ LCD display uses the VSPI interface in ESP32Forth
23 constant LCD_MOSI_PIN
18 constant LCD_SCLK_PIN
17 constant LCD_DC_PIN

\ SPI frequency for LCD
4000000 constant LCD_SPI_FREQUENCY

\ PWM ledc constants. LEDC is used to drive the switch LEDs
      8 constant PWM_RESOLUTION
5000000 constant PWM_FREQUENCY

\ MIDI interface signals. MIDI is output only so RX pin is unused
33 constant MIDI_TX_PIN
 0 constant MIDI_RX_PIN

