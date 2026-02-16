\ ESP32Forth - Palette Generation Function
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 01/13/2022
\

\ Constants and Variables
256 constant PAL_SIZE
  7 constant NUM_PALETTES
  0 constant PAL_GRAY
  1 constant PAL_SPECTRUM
  2 constant PAL_SIN1
  3 constant PAL_SIN2
  4 constant PAL_SIN3
  5 constant PAL_SIN4
  6 constant PAL_RAND

\ Create storage for the palette
PAL_SIZE array Palette

\ Randomizing factors
0e fvariable f1
0e fvariable f2
0e fvariable f3

\ Generate the specifed palette
: genPalette ( palNum -- )

  \ Create some factors for randomizing palettes
  16 128 randomNtoM s>f f1 sf!
  16 128 randomNtoM s>f f2 sf!
  16 128 randomNtoM s>f f3 sf!
  
  case
    PAL_GRAY  
    of
      \ Grayscale palette
      \ Sometimes the light colors at low index; other times at high index
      2 random0toN 1 =
      if
        PAL_SIZE 0
        do
          i i i color565 i Palette !
        loop
       else
        PAL_SIZE 0
        do
          255 i - 255 i - 255 i - color565 i Palette !
        loop
       then
    endof

    PAL_SPECTRUM
    of
      PAL_SIZE 0
      do
        i PAL_SIZE hsvColor i Palette !
      loop
    endof

    PAL_SIN1
    of
      PAL_SIZE 0
      do
        PI i s>f f* f1 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        PI i s>f f* f2 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        PI i s>f f* f3 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        color565 i palette !
      loop
    endof

    PAL_SIN2
    of
      PAL_SIZE 0
      do
        \ Create Red component
        PI i s>f f* f1 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        PI i s>f f* f2 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        0
        color565 i palette !
      loop
    endof

    PAL_SIN3
    of
      PAL_SIZE 0
      do
        PI i s>f f* f1 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        0
        PI i s>f f* f2 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        color565 i palette !
      loop
    endof

    PAL_SIN4
    of
      PAL_SIZE 0
      do
        0
        PI i s>f f* f1 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        PI i s>f f* f2 sf@ f/ fsin 128.0e f* 128.0e f+ f>s
        color565 i palette !
      loop
    endof
    
    PAL_RAND
    of
      PAL_SIZE 0
      do
        256 random0toN 256 random0toN 256 random0toN color565 i Palette !
      loop
    endof
  endcase
;


