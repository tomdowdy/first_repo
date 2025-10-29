
22 cells allocate drop value ww
: inc-cntr peek 1+ here- ! ;
: qq 13 word count ww 2dup >r >r 1+ swap cmove r> r> c! ;
\ : $stop-start ( c-addr -- caddr+n caddr+1 n ) dup c@ dup >r over + swap 1+ r> ;
: $stop-start ( c-addr -- caddr+n caddr+1 n ) dup c@ dup >r swap 1+ dup rot + swap r>  ;
: $find ( caddr ascii -- addrs count) , 0 , $stop-start drop do i dup c@ 2 npeek <> if drop else inc-cntr then loop pop pop drop ;
: ndrop ( n -- ) 0 do drop loop ;
: n2pop ( n -- n*dstack n*dstack-1) 0 do pop pop loop ;
: _gw1 ( used by get_words ) dup 1+ pick 1+ over 1+ pick over - ; \ gets string address and counts of a words
: _gw2 ( used by get_words ) dup c@ + 2 pick - 2 pick 1+ swap ; \ same as gw1 but only for last word
: get_words ( caddr -- i*caddr i*n n ) dup dup >r bl $find dup >r dup 0 do _gw1 , , 1- loop drop r> r> _gw2 , , 1+ dup , ndrop pop dup >r n2pop r> ; 


