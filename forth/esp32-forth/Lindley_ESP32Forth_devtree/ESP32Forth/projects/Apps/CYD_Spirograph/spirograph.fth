\
\ Spirograph App
\ Written in ESP32forth
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 05/24/2024
\

\ ***************************************************************************
\ ***                        Constants and Variables                      ***
\ ***************************************************************************

fvariable sx
fvariable sy

0 value x0
0 value x1
0 value yy0
0 value yy1

\ ***************************************************************************
\ ***                          Misc Functions                             ***
\ ***************************************************************************

\ Input a value 0 to 255 to get a color value
\ The colors transition from r to g to b and then back to r
: wheel  { wPos } ( wPos -- color16 )

  255 wPos - to wPos
  wPos 85 <
  if
    255 wPos 3 * - 0 wPos 3 * color565
  else wPos 170 <
    if
      -85 +to wPos
      0 wPos 3 * 255 wPos 3 * - color565
    else
      -170 +to wPos
      wPos 3 * 255 wPos 3 * - 0   color565
    then
  then
;

\ ***************************************************************************
\ ***                                Program                              ***
\ ***************************************************************************

\ App entry point
: main ( -- )
  cr

  \ Seed the random number generator
  randomSeed

  \ Initialize CYD display module
  3 initLCD

  0 0 { n r }

  15 0 
  do
    clearScreen

     2  23 randomNtoM to n
    20 100 randomNtoM to r

    n 360 * 0
    do 
      i s>f n s>f f/ 90 - fdtorad fcos sx sf!
      i s>f n s>f f/ 90 - fdtorad fsin sy sf!
      sx sf@ 120e r s>f f- f* 159e f+ f>s to x0
      sy sf@ 120e r s>f f- f* 119e f+ f>s to yy0
 
      i 360 mod 90 - s>f fdtorad fcos sy sf!
      i 360 mod 90 - s>f fdtorad fsin sx sf! 
      sx sf@ r s>f f* x0 s>f f+ f>s to x1
      sy sf@ r s>f f* yy0 s>f f+ f>s to yy1

      x1 yy1 i 360 mod 0 360 0 255 map wheel pixel
    loop

    
    20 100 randomNtoM to r

    n 360 * 0
    do 

      i s>f n s>f f/ 90 - fdtorad fcos sx sf!
      i s>f n s>f f/ 90 - fdtorad fsin sy sf!
      sx sf@ 120e r s>f f- f* 159e f+ f>s to x0
      sy sf@ 120e r s>f f- f* 119e f+ f>s to yy0
 
      i 360 mod 90 - s>f fdtorad fcos sy sf!
      i 360 mod 90 - s>f fdtorad fsin sx sf! 
      sx sf@ r s>f f* x0 s>f f+ f>s to x1
      sy sf@ r s>f f* yy0 s>f f+ f>s to yy1

      x1 yy1 i 360 mod 0 360 0 255 map wheel pixel

    loop

    2000 delay

  loop
;
