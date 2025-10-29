\ Simplest array
\ a lot like an array and a little bit like a stack


create bfr 64 cells allot
variable nxt bfr nxt !

: times ( xt n -- various ) 0 do dup >r  execute r> loop drop ;

\ uses predefined array named bfr and variable nxt
	: put ( m -- ) nxt dup >r @ ! cell r> +! ; \ like push
	: get ( -- m ) nxt dup >r @ cell - @ cell negate r> +! ; \ like pop
	: pic ( n -- m )cells bfr + @ ;
	: bot ( -- m ) bfr @ ; \ same as 0 pic
	: top ( -- m ) nxt @ cell - @ ;
	: pic1 ( -- m ) 1 cells bfr + @ ; \ same as 1 pic
	: pic2 ( -- m ) 2 cells bfr + @ ;
: pic3 ( -- m ) 3 cells bfr + @ ;
	: is0 ( -- flg ) nxt @ bfr - 0= if true else false then ; \ is bfr empty
: set-nxt ( n --- ) cells bfr + nxt ! ;
	: acount ( -- n ) nxt @ bfr - cell / ;
	: from-arr acount >r 0 r@ 1- do get -1 +loop r> ;
	: to-arr 0 do put loop ;
	: get-arr acount >r 0 r@ 1- do i cells bfr + @ -1 +loop r> ;
	
	: _pack ( -- ) bfr dup >r @ put acount r> ! ;
	: _unpack ( -- ) bfr dup >r @ cells r@ + nxt ! Get r> ! ;
	: _pack-count ( -- n ) bfr @ ;
	 
	: aback ( to-addr -- save-array) _pack bfr swap _pack-count cells move ;
	: arestore ( from-addr -- load-array ) dup >r @ cells r> swap bfr swap move _unpack ;
	
 \ need to supply destination address. You must keep track of index (n) yourself.
	: pop ( addr n -- m addr n-1  ) 2dup >r >r cells + @ r> r> 1- ; \ traverse down the array
	: pull ( addr n -- m addr n+1  ) 2dup >r >r cells + @ r> r> 1+ ; \ same as pop but traverse up the array
	: push ( addr n m -- addr n+1 ) -rot 2dup >r >r cells + ! r> r> 1+ ;
	: pickk ( addr n -- m ) cells + @ ;

\ destination address is in stk. Setup stk before using these. You must keep track of index (n) yourself. 
	bfr value stk
	: apop ( n -- m n-1) stk swap dup >r cells + @ r> 1- ;
	: apull ( n -- m n+1 ) stk swap dup >r cells + @ r> 1+ ;
	: apush ( n m -- n+1 ) swap stk swap dup >r cells + ! r> 1+ ;
	: apickk ( n -- m ) stk swap cells + @ ;

