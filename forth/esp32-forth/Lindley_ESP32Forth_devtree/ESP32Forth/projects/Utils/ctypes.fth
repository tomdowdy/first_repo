\ Character Type Words
\ 
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 01/24/2022
\

\ Determine if char passed in is a numeric digit
: isDigit { c } ( c -- f )
   c $30 >= c $39 <= and
;

\ Determine if char pass in is alphabetic
: isAlpha { c }	( c -- f )
  c $61 >= c $7A <= and
  c $41 >= c $5A <= and
  or
;

