
\ the following needed for testing

: ,p here cell - dup @ swap dp ! ;
: ,peek here cell - @ ;
: ,1peek here 2 cells - @ ;

\ previous lines ---------- end test code

create tmpa 100 allot

: send-to ( from-addr cnt to-addr -- ) 
	2dup ! 1 + swap cmove ;

\ the send-to word and tmpa are needed because the 'bl word'
\ combination puts the text in a very temporary
\ location

: wl
    \ an attempt to make an equivalent to pforth
    \ words.like
    \ uses code from gforth 'words'
	
	bl word count tmpa send-to tmpa count , ,
	
    cr 0 context @ wordlist-id
    BEGIN
		@ dup
		WHILE
		dup name>string 
		2dup ,peek ,1peek search swap drop swap drop if \ new
		type space \ original
		else 2drop then \ new
		1 >r r> rot + swap
    REPEAT
    2drop 
	,p ,p 2drop \ new
;