\ marker pad-stuff

\ The ] square bracket is a substitute for the > sign.
\ ] is easier since it is unshifted.
: ]pada pad ! ;
: ]padb pad cell + ! ;
: ]padc pad 2 cells + ! ;
: ]padd pad 3 cells + ! ;
: pada] pad @ ;
: padb] pad cell + @ ;
: padc] pad 2 cells + @ ;
: padd] pad 3 cells + @ ;

