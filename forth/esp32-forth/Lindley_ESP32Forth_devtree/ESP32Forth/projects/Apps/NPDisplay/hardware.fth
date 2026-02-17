\ Hardware Description for chained NeoPixel Displays

\ GPIO pin definitions
25 constant PB_SW
18 constant WS2812_PIN

\ Number of 8x8 NeoPixel displays chained together
 3 constant NUM_DISPLAYS

\ LED count
64 NUM_DISPLAYS * constant WS2812_COUNT

\ Misc variables and constants
 8 constant ROW_NUM
 7 constant ROW_MAX
 0 constant ROW_MIN

8 NUM_DISPLAYS * constant COL_NUM
      COL_NUM 1- constant COL_MAX
 0 constant COL_MIN
