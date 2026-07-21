
: pop here cell - @ cell negate allot ;
: [. s" marker _reset_nmap_" evaluate :noname ; \ new way, cleaner. 
: .] postpone ; ; immediate
: rst.dic s" _reset_nmap_" evaluate ;
\ : each depth dup >r 0 do >ms loop r> 0 do ms> here 2 cells - @ execute loop here cell - @ here - allot ; 

\ xt can not change stack depth.
: nmap ( i*x xt n -- j*x ) dup >r 0 do dup >r execute , r> loop drop r> 0 do pop loop ;

\ Same as nmap but use the [. and .] to create you xt.
: each ( i*x [. stuff .] n -- j*x ) nmap s" _reset_nmap_" evaluate ;
: npush 0 do , loop ;
: npop 0 do pop loop ;
: npeek cells here dup rot - do i @ cell +loop ;
: peekn 1+ cells negate here + @ ;
: peek here cell- @ ;
: allot- cells negate allot ;
\ allocates memory bytes and compiles address.
: alloc, ( n -- ) allocate 0= if , else cr 10 spaces ." Failed." cr then ;
: ddrop 1 allot- ; \ dictionary drop
: nddrop 0 do ddrop loop ;
: dswap pop pop swap , , ;
: ndrop 0 do drop loop ; \ stack multiple drop.
: mrk s" marker _auto_mark_" evaluate ;
: rst_only s" _auto_mark_" evaluate ;
: rst s" _auto_mark_ marker _auto_mark_" evaluate 0sp ;
: cs 0sp ;
: cp cs page ;

\ -------------------------------------------------------
\                                  here buffer

\ words to use a here buffer

\ h0-4 can only be used if a 5 hinit is done first. This allows
\ use of all 5 of the hx words. You can do less, for instance
\ 2 hinit would allow use of h0 and h1, but h3-4 would be meaningless.

\ hx behaves like a value.

: here- here cell- ;

: hp here- @ ; \ Gets pointer stored at 'here - cell' location. See below.
\ hp (= here pointer) can be used to retrieve a pointer stored at 'here - cell'.
\ Intended use case:
\ here 22 cells allot , -------- this creates a 22 cell reserved memory space in the dictionary.
\ The pointer to the start of that space is stored at 'here - cell (here-)'. Thus
\ hp retrieves that pointer from which memory operations can start.
\ do a '0 cell - allot -22 allot' to clean up. Alternately '-23 allot' cleans up.

: hcleanup ( n -- ) 1 + cells 0 swap - allot ; \ releases memory used for buffer
: hoff cells hp + ; \ hoff = here offset
: h0 hp @ ;
: h1 hp cell + @ ;
: h2 2 hoff @ ;
: h3 3 hoff @ ;
: h4 4 hoff @ ;
: h0, hp ! ;
: h1, hp cell + ! ;
: h2, 2 hoff ! ;
: h3, 3 hoff ! ;
: h4, 4 hoff ! ;

\ -------------------------------------------------------------------

\ quick anonymous function

: anon here cell - @ ; \  for anonymous function
\ use like :noname and ; but start of anonymous function is stored
\ at here 2 cells - and xt is stored at here cell -
<<<<<<< HEAD
\ anon pulls xt so 'execute' will run it
: ban here :noname ; \ begin anonymous (create a new anonymous function)
: ean postpone ; swap , , ; immediate \ end anonymous
: dan here 2 cells - @ here - allot ; \ destroy anonymous structure
=======
\ anon pulls xt address so @ execute will run item it
: dan here :noname ; \ for do anonymous (create a new anonymous function)
: ean postpone ; swap , , ; immediate
: ranon here 2 cells - @ here - allot ; \ reset anonymous structure
>>>>>>> 0f9822f018732efcb501c249c81e19512e93b087


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

: rsrv_cell cell allot ;

\                                User stack actions
: make-user-stack ( n <name> -- ) create cells allocate drop dup , 0 swap ! does> @ dup @ ;   
: upsh ( n name -- saddr count ) 1+ 2dup swap ! cells + ! ; \ name puts user stack addr and count on the stack
: upop ( name -- tos ) 2dup 1- swap ! cells + @ ; \ pops = pop tos


\ something like each or nmap for items stored in memory
\ xt can not change stack depth, just value of stack.
\ : mem_each ( addr xt n -- ) -rot , , cells peek dup rot + swap do i dup @ 1 peekn execute swap ! cell +loop ddrop ddrop ;
: mem_each ( addr xt n -- ) cells 2 pick + 2 pick do i dup @ 2 pick execute swap ! cell + loop 2 ndrop ;

\ like the dictionary stack, dstack, above but keeps count of items on dstack.
\ do a ddrop when done with dstack to recover memory used for counter.
\ slower than pop and stuff but keeps count of items at 'here - cell'
\ As items are pushed or poped, the count is moved to tos plus cell.

: ,init s" marker _dstack_ " evaluate 0 , ; \ initialize counter to zero.
: ,reset s" _dstack_" evaluate ; \ recovers memory.
\ \\\\\\\\ : ,. ( m -- ) here cell- @ 1+ ddrop swap , , ; \ push
\ : ,psh here cell- @ 1+ cell negate allot swap , , ;
: ,psh ( n -- ) here cell - dup @ 1 + ( n h- cnt+ ) -rot ! , ;
: ,depth here- @ ;
\ : ,pop here cell- @ 1- 2 cells negate allot here @ swap , ; \ pop
: ,pop here cell - dup cell - @ swap @ 1 - ( n cnt- ) 0 2 cells - allot , ;
: ,peekn 2 + cells negate here + @ ;
: ,npop 0 ,pop ;
: ds>s ,depth 0 do ,pop loop ,reset ; \ dictionary stack to stack
: s>ds ( *y *nx n -- *y ) ,init depth 0 do ,psh loop ; \ entire stack to new dictionary stack

: ,p here cell - @ 0 cell - allot ; \ simple pop, does not use count, used with comma ,
: p@ here cell - @ ;

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
