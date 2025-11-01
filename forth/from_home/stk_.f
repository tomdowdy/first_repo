variable stk
base @
decimal
260 allocate drop
stk !
0 1 stk @ 2!
base !
: _psh swap dup >r 1 + swap 2 pick 2! r> 2 + cells + ! ;
: psh stk @ dup 2@ 2dup <= if _psh else 2drop 2drop ." Stack full." then ;

22 1111 1 2 