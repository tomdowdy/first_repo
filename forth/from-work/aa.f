\ push is comma ,
: [. s" marker _reset_nmap_" evaluate :noname ; \ new way, cleaner. 
: .] postpone ; ; immediate
: rst.dic s" _reset_nmap_" evaluate ;
\ : each depth dup >r 0 do >ms loop r> 0 do ms> here 2 cells - @ execute loop here cell - @ here - allot ; 

\ xt can not change stack depth.
: nmap ( i*x xt n -- j*x ) dup >r 0 do dup >r execute , r> loop drop r> 0 do ,pop loop ;

\ Same as nmap but use the [. and .] to create you xt.
: each ( i*x [. stuff .] n -- j*x ) nmap s" _reset_nmap_" evaluate ;
: allot- 0 cells - allot ;
: ,pop here [ 1 cells literal ] - @ [ 0 1 cells - literal ] dp +! ( allot ) ;
: ,npush 0 do , loop ;
: ,npop 0 do ,pop loop ;
: ,peek here cell- @ ;
: ,npeek cells here dup rot - do i @ cell +loop ;
: ,peekn 1+ cells negate here + @ ;
: ,ddrop 1 allot- ; \ dictionary drop
: ,nddrop 0 do ddrop loop ;
: ,swap ,pop ,pop swap , , ;
: ndrop 0 do drop loop ; \ stack multiple drop.
\ allocates memory bytes and compiles address.
: alloc, ( n -- ) allocate 0= if , else cr 10 spaces ." Failed." cr then ;
: mrk s" marker _auto_mark_" evaluate ;
: rst_only s" _auto_mark_" evaluate ;
: rst s" _auto_mark_ marker _auto_mark_" evaluate 0sp ;
: cs 0sp ;
: here- here cell- ;
: nrev ( n ) \ reverse n stack items.
	dup >r dup 0 do dup pick , 1- loop drop 
	r@ 0 do drop loop r> 0 do pop loop ;

\ reverse do, sort of.
\ :  qq dup 0 do dup >r i 1+ - r> loop drop ;
\ better version ( i think this is the shortest version):
\ : qq begin dup 0> while 1- 
\	dup . ( the 'dup .' just displays the indice ) repeat ; 
\ another one:
\ : qq 1- begin ( backward counting indice on the stack.)
\	dup . 1- dup 0 < until drop ; \ the 'dup .' just displays the indice.
\ : get_bytes ( addr ) cell 0 do dup i + c@ swap loop drop ;
\ : get_n_bytes ( addr n m ) \ n and m are zero based.
\	>r >r get_bytes r> 1+ r> 2dup >r >r
\	do i pick , loop 
\	cell 0 do drop loop
\	r> r> do pop loop ;

: get_bytes ( addr n ) over + swap do i c@ loop ;
: get_byte ( addr n ) + c@ ;

\ : l@ @ 1 cell cells 2 / lshift 1- and ; \ lower half of word.
\ : h@ @ cell cells 2 / rshift ; \ upper half of word.

: l@ ( addr ) 4 + 4 get_bytes ;
: h@ ( addr ) 4 get_bytes ;

: get_last_xt latest name> ;
: rsrv_cell cell allot ;
: make-stack ( n <name> -- ) create cells allocate drop dup , 0 swap ! does> @ dup @ ;   
: psh ( n name -- saddr count ) 1+ 2dup swap ! cells + ! ; \ name puts user stack addr and count on the stack
: pops ( name -- tos ) 2dup 1- swap ! cells + @ ; \ pops = pop tos

\ something like each or nmap for items stored in memory
\ xt can not change stack depth, just value of stack.
\ : mem_each ( addr xt n -- ) -rot , , cells peek dup rot + swap do i dup @ 1 peekn execute swap ! cell +loop ddrop ddrop ;
: mem_each ( addr xt n -- ) cells 2 pick + 2 pick do i dup @ 2 pick execute swap ! cell + loop 2 ndrop ;

\ like the dictionary stack, dstack, above but keeps count of items on dstack.
\ do a ddrop when done with dstack to recover memory used for counter.
\ slower than pop and stuff but keeps count of items.
: ,init s" marker _dstack_ " evaluate 0 , ; \ initialize counter to zero.
: ,reset s" _dstack_" evaluate ; \ recovers memory.
\ : ,. ( m -- ) here cell- @ 1+ ddrop swap , , ; \ push
: ,. here cell- @ 1+ cell negate allot swap , , ;
: ,depth here- @ ;
: ,pop here cell- @ 1- 2 cells negate allot here @ swap , ; \ pop
: ,peekn 2 + cells negate here + @ ;
: ,npop 0 ,pop ;
: ds>s ,depth 0 do ,pop loop ,reset ;
: s>ds ,init depth 0 do ,. loop ;
\ 0 value _dstack_cntr_
\ : ,init _dstack_cntr_ 0= if s" marker _dstack_" evaluate else 9898 throw then  ;
\ : ,reset s" _dstack_" evaluate 0 to _dstack_cntr_ ;
\ : ,. _dstack_cntr_ 1+ to _dstack_cntr_ , ;
\ : ,pop _dstack_cntr_ 1- to _dstack_cntr_ pop ; 
\ : ,depth _dstack_cntr_ ;
\ : ,npop 0 do ,pop loop ;
\ : _,buffer-init ,depth dup >r ,npop r> ,reset ;
\ : ,buffer ( <name> -- ) ,depth dup cells allocate drop >r dup >r 0 do i peekn loop r> cells r@ + r> do i ! cell +loop ;
\ : ,restore ( addr -- )
mrk
