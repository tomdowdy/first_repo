
USER >OUT
USER W-CNT

: NLIST ( A -> )
  @
  >OUT 0! CR W-CNT 0!
  BEGIN
    DUP KEY? 0= AND
  WHILE  30 PAUSE
    W-CNT 1+!
    DUP C@ >OUT @ + 74 >
    IF CR >OUT 0! THEN
    DUP 
                          dup .
    ID.
    DUP C@ >OUT +!
    15 >OUT @ 15 MOD - DUP >OUT +! SPACES
    CDR
  REPEAT DROP KEY? IF KEY DROP THEN
  CR CR ." Words: " BASE @ DECIMAL W-CNT @ U. BASE ! CR
;

: wl ( -- ) CR ." ---------SLOW WORDS STOP WITH ESC--------------- " CR \
  CONTEXT @ NLIST
   CR ." ---------------------------------------------------- " CR
;