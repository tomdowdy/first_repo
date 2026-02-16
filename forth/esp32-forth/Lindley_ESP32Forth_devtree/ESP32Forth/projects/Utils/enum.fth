\
\ A simple implementation of a C enum that
\ creates a new constant for each enum entry
\

: enum
  create 0 ,
  does> dup @ 1 rot +! constant
;

\ It works like this
\ enum State
\ State s1 State s2 State s3
\
\ Then if you do s1 . == 0 s2 . == 1 s3 . == 2
