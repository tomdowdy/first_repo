\ marker pad-stuff

: ]pada depth 0<> if pad ! then ;
: ]padb depth 0<> if pad cell + ! then ;
: ]padc depth 0<> if pad 2 cells + ! then ;
: ]padd depth 0<> if pad 3 cells + ! then ;
: pada] pad @ ;
: padb] pad cell + @ ;
: padc] pad 2 cells + @ ;
: padd] pad 3 cells + @ ;
