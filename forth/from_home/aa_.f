

: pop here cell - @ cell negate allot ;
: [. s" marker _reset_dict_" evaluate :noname ; \ new way, cleaner.
: .] postpone ; ; immediate
: rst.dic s" _reset_dict_" evaluate ;
: nmap ( i*x n xt ) swap dup >r 0 do dup >r execute , r> loop drop r> 0 do pop loop ;
: each nmap s" _reset_dict_" evaluate ; \ new way.
: npush 0 do , loop ;
: npop 0 do pop loop ;
: npeek cells negate here + @ ;
: peek here cell- @ ;
: allot- cells negate allot ;
: drp 1 allot- ;
: mrk s" marker _auto_mark_" evaluate ;
: rst s" _auto_mark_ marker _auto_mark_" evaluate ;
: cs 0sp ;
: here- here cell- ;
: revn ( n ) dup >r dup 0 do dup pick , 1- loop drop r@ 0 do drop loop r> 0 do pop loop ;
 

\ reverse do, sort of.
\ :  qq dup 0 do dup >r i 1+ - r> loop drop ;
\ better version ( i think this is the shortest version):
\ : qq begin dup 0> while 1-
\              dup . ( the 'dup .' just displays the indice ) repeat ;
\ another one:
\ : qq 1- begin ( backward counting indice on the stack.)
\              dup . 1- dup 0 < until drop ; \ the 'dup .' just displays the indice.
 

\ : get_bytes ( addr ) cell 0 do dup i + c@ swap loop drop ;
\ : get_n_bytes ( addr n m ) \ n and m are zero based.
\              >r >r get_bytes r> 1+ r> 2dup >r >r
\              do i pick , loop
\              cell 0 do drop loop
\              r> r> do pop loop ;

: get_bytes ( addr n ) over + swap do i c@ loop ;
: get_byte ( addr n ) + c@ ;
 
\ : l@ @ 1 cell cells 2 / lshift 1- and ; \ lower half of word.
\ : h@ @ cell cells 2 / rshift ; \ upper half of word.

: l@ ( addr ) 4 + 4 get_bytes ;
: h@ ( addr ) 4 get_bytes ;
: dups ( i*x n -- n*x n*x ) dup >r 0 do , loop r@ 0 do i npeek loop r> 0 do pop loop ;
: make-stack ( n <name> -- ) create cells allocate drop dup , 0 swap ! does> @ dup @ ;   
: psh ( n name -- ) 1+ 2dup swap ! cells + ! ;
: pops ( name -- n ) 2dup 1- swap ! cells + @ ;
: mrkr s" marker _reset" evaluate ;

