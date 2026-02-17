\ 8x8 NeoPixel Panel support functions
\ Written in ESP32Forth
\ Written by: Craig A. Lindley
\ Last Update: 09/20/2022

\ Set a pixel by col and row
\ This fixes the bizarre mapping of the stock 8x8 NeoPixel panels
: setPixelColRow { col row color24 } ( col row color24 -- )
  \ Determine if column is even or odd
  col 2 mod 0<>
  if
    \ Column is odd
    color24 col 8 * 7 row - + setPixelColor24
  else
    \ Column is even
    color24 col 8 * row + setPixelColor24
 then
;

\ Get a pixel by col and row
: getPixelColRow { col row } ( col row -- color24 )
  \ Determine if column is even or odd
  col 2 mod 0<>
  if
    \ Column is odd
    col 8 * 7 row - + getPixelColor24
  else
    \ Column is even
    col 8 * row + getPixelColor24
 then
;

\ Shifts NeoPixel matrix data one column to the left
\ by reading pixel at old location and transferring
\ it to the new location.
: shiftMatrixLeft ( -- )
  COL_NUM 1
  do
    ROW_NUM 0
    do
      j i        getPixelColRow ( -- color24 )
      j 1- i rot setPixelColRow
    loop
  loop

  \ Clear the last column
  ROW_NUM 0
  do
    COL_MAX i 0 setPixelColRow
  loop
;

\ Dynamic color variables
0 value colorIndex
0 value colorDivisions

\ Initialize dynamic color selection with specified number of divisions
: initDynamicColorSelection1 (  divisions -- )
  
  to colorDivisions

  \ Then pick a random color index to start with
  colorDivisions random0toN to colorIndex
;

\ Initialize dynamic color selection with random number of divisions
: initDynamicColorSelection2 ( -- )

  \ Pick a random number of color divisions
  6 32 randomNtoM to colorDivisions

  \ Then pick a random color index to start with
  colorDivisions random0toN to colorIndex
;

\ Dynamic Color Selector
: dynamicColorSelector ( -- color24 )
  colorIndex colorDivisions hsvColor
  1 +to colorIndex
  colorIndex colorDivisions >=
  if
    0 to colorIndex
  then
;

