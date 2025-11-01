\ [ifundef] ascii
\      : ascii bl parse drop c@ ;
\ [then]

\ [ifundef]
\ : .hex  BASE @ HEX SWAP . BASE ! ;
\ [then]

: notes
page
cr cr ." -------------- Interesting words --------------"
cr cr ." create - makes good stuff"
cr ." dp - for pforth"
cr ." locate - in swiftForh is like help in gforth."
cr ." here - "
cr ." pad - moves too."
cr ." sp0 - variable holding bottom of stack."
cr ." allocate - reserves memory at location."
cr ."     Expects an address and a count of bytes to reserve on the stack."
cr ." ' (comma) returns the xt of the word in the input stream. Usage <word> '."
cr ." >body looks up the body of the xt on the stack."
cr ." [defined] <name> returns false if not found."
cr ." >IN ( — a-addr ) Return the address of a cell containing the offset"
." (in characters) from the start of the input buffer to the start of the parse area."
cr ." token swiftForth."

cr ." : COMPILE, ( xt -- , compile call to xt ) , ; "

cr ." : [COMPILE]  ( <name> -- , compile now even if immediate )"
cr ."     ' compile, ;  IMMEDIATE"

cr ." : (COMPILE) ( xt -- , postpone compilation of token )"
cr ."         [compile] literal       ( compile a call to literal )"
cr ."         ( store xt of word to be compiled )"
cr ."         [ ' compile, ] literal "  \ compile call to compileth
cr ."         compile, ;"
\
cr ." : COMPILE  ( <name> -- , save xt and compile later )"
cr ."     ' (compile) ; IMMEDIATE"
\ Do you reckon there are enough compiles?

cr ." : :NONAME ( -- xt , begin compilation of headerless secondary )"
cr ."         align"
cr ."         here code>   \ convert here to execution token ] ;"
\ As with many things in Forth I've yet to figure out why you would want or how
\ you would use NONAME.

cr cr ;
interpret
