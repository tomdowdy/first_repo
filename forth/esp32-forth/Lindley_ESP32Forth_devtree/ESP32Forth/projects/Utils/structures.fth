\ Simple Structure Definitions

: struct: 0 ;

: field:
  create over , +
  does> @ + ;

\ Example Usage

\ Cell is the size of the field
\ .width and .height are addresses of their positions in the dictionary

\ struct:
\   cell field: .width
\   cell field: .height
\ constant Rect

\ : new-rect: ( "name" -- )
\  Rect create: allot ;

\ : area ( rect -- area )
\  dup .width @ swap .height @ * ;

\ new-rect: r1
\ 3 r1 .width !
\ 5 r1 .height !
\ r1 area .

\ Floating point numbers can also be stored in structs. It is just
\ a matter of using sf! instead of ! when storing values and sf@
\ instead of @ when loading values. This works because the size 
\ of a cell (4 bytes) is the same as the size of a single precision
\ float.

\ A point structure for example

\ struct:
\  cell field: .x
\  cell field: .y
\ constant Point

\ : newPoint: ( "name" -- )
\  Point create allot ;

\ : display { Point }
\  Point .x sf@ f. Point .y sf@ f. ;

\ newPoint: p1

\ 3e p1 .x sf!
\ 5e p1 .y sf!

\ p1 display












