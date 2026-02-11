\ For ForthWin

: WORDS-LIKE ( -- )
  \ The number of words per line is held at here cell -.
  \ 0 ,
  BL WORD COUNT 2>R
  CONTEXT @ @
  BEGIN
    ?DUP
  WHILE
    \ here cell - @ 20 = if cr 0 here cell - ! then
    DUP COUNT 2R@ SEARCH NIP NIP
    IF
       DUP ID. SPACE
    THEN
    CDR
	1 here cell - +!
  REPEAT
  2R> 2DROP
  CR
  \ 0 cell - allot
;
