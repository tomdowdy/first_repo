\ include %swiftforth\lib\options\fpmath

\ Clear stack.
: cs depth 0= if cr ." Empty stack." cr else depth 0 do drop loop then ;

\ Usage: variable-name inc.
: inc 1 swap +! ;

\ Usage: variable-name dec.
: dec -1 swap +! ;

\ Usage: initial-value counter-make variable-name.
\ : counter-make 1 - -? create , does> dup 1 swap +! @ ;

\ Usage: counter-reset variable-name.
\ : counter-reset-zero 0 counter-make ;
