\ ESP32Forth Desk Gadget - Plasma Display Pattern
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/16/2022
\

\ Program constants
320 constant WIDTH
240 constant HEIGHT
WIDTH  2 / constant XMID
HEIGHT 2 / constant YMID

 4 constant NUM_PLASMAS

fvariable f1
fvariable f2
fvariable f3
fvariable val

\ Draw a plasma pattern 
: drawPlasma { pType pNum }

  \ Generate random factors to alter plasma
  2 32 randomNtoM s>f f1 sf!
  2 64 randomNtoM s>f f2 sf!
  2 32 randomNtoM s>f f3 sf!

  \ Generate the specified palette
  pNum genPalette

  WIDTH 0
  do
    HEIGHT 0
    do
      pType
      case
        0
        of
          j XMID - j XMID - * i YMID - i YMID - * + s>f fsqrt f1 sf@ f/ fsin val sf!
        endof

        1
        of
          j s>f f1 sf@ f/ fsin i s>f f1 sf@ f/ fsin f+ 2.0e f/ val sf!
        endof

        2 
        of
          j s>f f1 sf@ f/ fsin i s>f f2 sf@ f/ fsin j i + s>f fsin f3 sf@ f/ f+ f+ 3.0e f/ val sf!
        endof

        3
        of
          j s>f f1 sf@ f/ fsin i s>f f2 sf@ f/ fsin f+ 
          j XMID - j XMID - * i YMID - i YMID - * + s>f fsqrt f3 sf@ f/ fsin f+ 3.0e f/ val sf!
        endof
      endcase

      \ Scale -1 .. +1 value to 0 .. 255
      val sf@ 128.0e f* 128.0e f+ f>s 256 mod palette @
      i swap j -rot pixel
    loop
  loop
;

\ Plasma display pattern
: doPlasma ( -- returnReason )


  BLACK fillScreen

  begin

    \ Draw plasma pattern
    NUM_PLASMAS random0toN NUM_PALETTES random0toN drawPlasma
    1000 ms

    \ Check for pattern exit
    checkForExit

  until
  returnReason
;
