
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