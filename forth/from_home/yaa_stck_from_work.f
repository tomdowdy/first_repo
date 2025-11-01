
Marker reset

: ,peek here cell - @ ;
: ,drop here cell - dp ! ;
: ,pic 1+ cells here swap - @ ;
: ,pop here cell - dup @ swap dp ! ;
 \ ABOVE IS ONLY FOR DEVELOPMENT
 
: times ( xt n -- * ) 0 do dup >r  execute r> loop drop ;
: tims ( n <name> -- * ) bl word find 0= if drop exit then swap times ;
: cs 0sp ;
: cp 0sp page ;

0 value stk
: stk.noname ( n -- sid ) here 0 , over , swap 2+ cells allot ;
: psh ( x sid -- ) dup 2@ = if cr ." Full." cr abort then 1 over +! ( n sid ) r> 2+ cells + ! ;
: pop ( sid -- x ) dup @ dup 0= if cr ." Empty." cr abort then 0 1 -  over +! r> 1+ cells + @ ;

: stk.new ( n -- ) stk.noname to stk ;
\ : put ( x -- ) stk dup 2@ = if cr ." Full." cr abort then dup @ 1+ dup >r ( n sid nxt ) over ! r> 1+ cells + ! ;
: put ( x -- ) stk dup 2@ dup >r = if cr ." Full." cr abort then 1 over +! ( n sid ) r> 2+ cells + ! ;
\ : get ( -- x ) stk dup @ dup 0= if cr ." Empty." cr abort then dup >r 1- over ! r> 1+ cells + @ ; 
: get ( -- x ) stk dup @ dup >r 0= if cr ." Empty." cr abort then 0 1 -  over +! r> 1+ cells + @ ;
: top stk dup @ 1+ cells + @ ;
: bot stk 2 cells + @ ;
: pic ( n -- x ) 2+ cells stk + @  ;
: stk.remaining stk 2@ - ;
: look stk dup 2 cells + swap @ 0 ?do dup >r @ r> cell + loop drop ;
: cnt stk @ ;
: swp stk dup @ cells + dup 2@ swap rot 2! ;
: rots ['] get 3 times rot ['] put 3 times ;
: -rots ['] get 3 times -rot ['] put 3 times ;
: stk.prev stk dp ! ,pop to stk ;
: :stk stk , stk.new ;

\ BELOW IS ONLY FOR DEVELOPMENT
hex
22 stk.new
Aa put bb put

