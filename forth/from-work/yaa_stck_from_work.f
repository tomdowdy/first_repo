
\ Marker reset

\ : ,peek here cell - @ ;
\ : ,drop here cell - dp ! ;
\ : ,pic 1+ cells here swap - @ ;
\ : ,pop here cell - dup @ swap dp ! ;
 \ ABOVE IS ONLY FOR DEVELOPMENT
 
: times ( xt n -- * ) 0 do dup >r  execute r> loop drop ;
: tims ( n <name> -- * ) bl word find 0= if drop exit then swap times ;
: cs 0sp ;
: cp 0sp page ;

\ Stack map
\    |    count    |    max   |   n cells   |

\ stk.new creates a new stack reserving memory
\ puts stack ID (sid) in stk value
\ :stk does same but first pushes value from stk into dictionary
\ ie also know as compliling the value of stk
\ this lets you do stk.prev that will restore the stack
\ active prior to the :stk command
\ since stk defaults to 0, 0 will be compiled on next :stk
\ stk.prev will stop restoring previous stack when it
\ sees that 0

variable stk 0 stk !
: stk.noname ( n -- sid ) here 0 , over , swap 2+ cells allot ;
        : psh ( x sid -- ) dup 2@ dup >r = if cr ." Full." cr abort then 
                1 over +! ( n sid ) r> 2+ cells + ! ;
        : pop ( sid -- x ) dup @ dup >r 0= if cr ." Empty." cr abort then 
                0 1 -  over +! r> 1+ cells + @ ;

: stk.new ( n -- ) stk.noname stk ! ;
        \ : put ( x -- ) stk dup 2@ = if cr ." Full." cr abort then dup @ 1+ dup >r ( n sid nxt ) over ! r> 1+ cells + ! ;
        : put ( x -- ) stk @ dup 2@ dup >r = if cr ." Full." cr abort then 1 over +! ( n sid ) r> 2+ cells + ! ;
        \ : get ( -- x ) stk dup @ dup 0= if cr ." Empty." cr abort then dup >r 1- over ! r> 1+ cells + @ ; 
        : get ( -- x ) stk @ dup @ dup >r 0= if cr ." Empty." cr abort then 0 1 -  over +! r> 1+ cells + @ ;
        : top stk @ dup @ 1+ cells + @ ;
        : bot stk @ 2 cells + @ ;
        \ : pic ( n -- x ) stk @ dup @ rot - 1+ cells + @ ; 

        : pic ( n--x ) stk @ dup @ ( n sid cnt) rot ( sid cnt n ) dup >r 1+ over 0
                swap between 0= if cr ." Invalid index." cr abort then 
                r> ( sid cnt n ) - 1+ cells + @ ;

        : stk.remaining stk @ 2@ - ;
        : look stk @ dup 0= if drop cr ." No stacks." cr abort then 
                dup 2 cells + swap @ 0 ?do dup >r @ r> cell + loop drop ;
        : cnt stk @ @ ;
        : swp stk @ dup @ cells + dup 2@ swap rot 2! ;
        : rots ['] get 3 times rot ['] put 3 times ;
        : -rots ['] get 3 times -rot ['] put 3 times ;
        : stk.prev stk @ 0= 
                if cr ." No stacks." cr abort else 
                stk @ cell - dup @ stk ! dp ! then ; 

: :stk stk @ , stk.new ;

: stks.lst stk @ 0= if cr ." No stacks." cr abort then 
        0 >r stk @ begin r> 1+ >r dup cell - @ dup 0= until drop    r> ; \ list stacks

: stks.cnt stks.lst dup >r ndrop r> ; \ count stacks

: -a ( addr -- x ) cell - @ ; \ -a = addr - cell look

\ BELOW IS ONLY FOR DEVELOPMENT
\ hex
\ 22 stk.new
\ Aa put bb put

