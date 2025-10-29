: lbl here ; immediate 
: _lp r> drop >r ; 
: lp postpone literal Postpone _lp ; immediate 

\ : qq lbl 22 . lp ; 
  

: _0lp over 0= if 2drop exit then _lp ;    ok 

: 0lp postpone literal postpone _0lp ; immediate 

: qq 22 lbl dup . 1- 0lp ; 