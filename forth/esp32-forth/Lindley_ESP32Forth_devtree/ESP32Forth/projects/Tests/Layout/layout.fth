\ Layout test program for World Clock app
\ Craig A. Lindley 08/14/2021

33 constant LINE_SPACING
0 value yOffset

: run 
  3 initLCD 
  clearLCD

  \ Draw rounded rect around display
  0 0 _width_ 1- _height_ 1- 8 BLU roundedRect

  3 setTextSize
  5 to yOffset

  WHT to FGColor
  yOffset s" Los Angeles" pCenteredString
  LINE_SPACING +to yOffset
  YEL to FGColor
  yOffset s" Wed" pCenteredString
  LINE_SPACING +to yOffset
  GRN to FGColor
  yOffset s" Jan 18, 2021" pCenteredString
  LINE_SPACING +to yOffset
  BLU to FGColor
  yOffset s" 10:34 PM" pCenteredString
;


