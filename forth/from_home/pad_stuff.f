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
