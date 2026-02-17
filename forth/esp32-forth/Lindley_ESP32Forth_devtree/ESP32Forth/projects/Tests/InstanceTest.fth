\ Instance Tests

: struct: 
    0
;

: field:
  create over , +
  does> @ +
;


struct:
  cell field: .f1
  cell field: .f2
constant INSTANCE_DATA


\ Create a new instance
: newInstance ( "name" -- )
  INSTANCE_DATA create allot
;

: initInstance { v1 v2 name -- }
  v1 name .f1 !
  v2 name .f2 !
;

: showInstance { name -- }
  cr
  name .f1 @ . cr
  name .f2 @ . cr
;

