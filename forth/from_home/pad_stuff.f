\ marker pad-stuff

: ]pada depth if pad ! then ;
: ]padb depth if pad cell + ! then ;
: ]padc depth if pad 2 cells + ! then ;
: ]padd depth if pad 3 cells + ! then ;
: pada pad @ ;
: padb pad cell + @ ;
: padc pad 2 cells + @ ;
: padd pad 3 cells + @ ;

create tmp 4 cells allot
: ]tmpa depth if tmp ! then ;
: ]tmpb depth if tmp cell + ! then ;
: ]tmpc depth if tmp 2 cells + ! then ;
: ]tmpd depth if tmp 3 cells + ! then ;
: tmpa tmp @ ;
: tmpb tmp cell + @ ;
: tmpc tmp 2 cells + @ ;
: tmpd tmp 3 cells + @ ;
\ increment tmp and leave new value on stack
: tmpa.inc tmpa 1+ dup ]tmpa ; 
: tmpb.inc tmpb 1+ dup ]tmpb ;
: tmpc.inc tmpc 1+ dup ]tmpc ;
: tmpd.inc tmpd 1+ dup ]tmpd ;
\ the following compares tmp variable to limit, increments value, and leaves a flag
: tmpa.cnt ( n -- flag ) tmpa.inc = ;
: tmpb.cnt ( n -- flag ) tmpb.inc = ;
: tmpc.cnt ( n -- flag ) tmpc.inc = ;
: tmpd.cnt ( n -- flag ) tmpd.inc = ;
: tmp.bac tmpa , tmpb , tmpc , tmpd , ;
: tmp.rstr ,p ]tmpd ,p ]tmpc ,p ]tmpb ,p ]tmpa ;
: tmp.dmp tmp dup 4 cells + swap do i @ cell +loop ;
: tmp0 tmp dup 4 cells + swap do 0 i ! cell +loop ;   
\ init tmps to 0
tmp0