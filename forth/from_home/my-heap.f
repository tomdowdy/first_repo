\ Usage:
\ variable name
\ size alloc name
 
\ Then name + offset @ or !.
\ I see no heap slice overrun checking.
 
0 value nil
variable heap.ptr
variable hndl.ptr
variable free.hndl.ptr
here constant begin.heap.c
40 cells constant heapsize.c
create heap heapsize.c allot
here constant end.heap.c
\ : 2+ 2 + ;
\ : 2- 2 - ;
: heap.reset heap heapsize.c 0 fill
	heap heap.ptr !
	end.heap.c 2 - hndl.ptr !
	nil free.hndl.ptr ! ;
heap.reset
: get.heap.ptr heap.ptr @ ; \ get heap pointer.
: bump.heap.ptr ( n -- ) heap.ptr +! ; \ n bump.heap pointer. Add n to heap pointer.
: get.hndl.ptr hndl.ptr @ ; \ get handle pointer.
: bump.hndl.ptr ( n -- ) hndl.ptr +! ; \ n bump.hndl.ptr. Add n to handle pointer.
: get.free.hndl free.hndl.ptr @ ;
: update.free.hndl free.hndl.ptr ! ;
\ : get.hndl get.free.hndl ?dup 0= if get.hndl.ptr -2 bump.hndl.ptr else dup @ update.free.hndl then ;
: get.hndl ( -- hndl ) free.hndl.ptr @ 
	?dup 0= 
	if hndl.ptr @ 
	-2 hndl.ptr +! 
	else dup @ 
	free.hndl.ptr ! then ;
\ If free.hndl.ptr contents is 0 then get.hndl returns hndl.ptr contents minus 2. First time through, hndl.ptr contents
\ is the end of the heap minus 2 and free.hndl.ptr contents is zero. It is always zero when there are no
\ used handles available. Either it returns an old used handle or zero.
: ?full ( size -- size ) dup get.hndl.ptr get.heap.ptr rot + 2+ - 0< if ." No more heap space." cr abort then ;
: ?neg ( size -- size ) dup 0< if ." Negative allocation." cr abort then ;
: alloc ( size -- hndl or 0; usage size alloc name ) 
	?neg ?full
	get.hndl
	get.heap.ptr 2+ over !
	over get.heap.ptr ! 
	swap 2+ bump.heap.ptr ;
: size? ( hndl -- size ) @ 2- @ ;
: (release.hndl) ( hndl -- ) free.hndl.ptr @ over ! free.hndl.ptr ! ;
: adjust.hndls ( n addr -- ) 
	swap negate end.heap.c
	get.hndl.ptr 2+ .s exit 
	do i @ 2 pick >
	get.hndl.ptr i @ - 0> and
	if i over swap +! then
	2 +loop 2drop ;
: free.hndl  ( hndl -- ) dup size? 2+ over @ 2-
               2dup + dup >r swap get.heap.ptr
               r@ - cmove dup negate bump.heap.ptr
               swap (release.hndl) r> adjust.hndls ;
: ghv ( offset name -- value ) @ @ swap 2 + cells + @ ; \ get heap value
: phv ( value offset name -- ) @ @ swap 2 + cells + ! ; \ put heap value
: heap.alloc ( alloc-units name --- ) variable latest execute >r alloc r> ! ; \ I'm not sure what this is.
: ,hw1 cr cr ." begin.heap.c heap.ptr hndl.ptr free.hndl.ptr heap end.heap.c" ;
: ,hw2 cr ." alloc heap.reset get.heap.ptr bump.heap.ptr get.hndl.ptr " ;
: ,hw3 cr ." bump.hndl.ptr get.free.hndl update.free.hndl adjust.hndls get.hndl" ;
: help.heap ,hw1 ,hw2 ,hw3 cr ." size? free.hndl ghv phv heap.alloc" cr cr ;

variable jj 
10 alloc jj !

 