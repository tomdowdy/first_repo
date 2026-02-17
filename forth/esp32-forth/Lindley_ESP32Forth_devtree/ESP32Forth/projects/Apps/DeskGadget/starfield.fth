\ Star Field Animation
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/02/2022
\

getLCDWidth  constant WIDTH
getLCDHeight constant HEIGHT
           0 constant MINX
           0 constant MINY
    WIDTH 1- constant MAXX
   HEIGHT 1- constant MAXY
          50 constant NUM_STARS


\ Coordinates of the stars in 3D
NUM_STARS farray starX
NUM_STARS farray starY
NUM_STARS farray starZ

\ Location of stars on screen
NUM_STARS array starScreenX
NUM_STARS array starScreenY

\ Velocity of stars
NUM_STARS farray starZV



