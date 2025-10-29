marker mystuff

: allot- cells negate allot ;
\ : ,pop here [ 1 cells literal ] - @ [ 0 1 cells - literal ] dp +! ( allot ) ;
: ,pop 0 cell - dp +! dp @ @ ;
: ,npush 0 do , loop ;
: ,npop 0 do ,pop loop ;
: ,peek dp @ cell - @ ;
: ,peekn cells here dup rot - ?do i @ cell +loop ;
\ : ,pick 1+ cells negate here + @ ;
: ,pick 1+ cells dp @ swap - @ ;
: ,drop 0 cell - dp +! ; \ dictionary drop
: ,ndrop cells negate allot ;
: ,swap ,pop ,pop swap , , ;
: ndrop 0 do drop loop ; \ stack multiple drop.
: ntuck ( s*j x n -- q*j x n*j ) dup depth 3 - > if cr ." Will cause stack underflow." cr throw exit then swap >r dup >r 0 ?do , loop r> r> swap 0 ?do ,pop loop ;
: >bos depth 1 - ntuck ;
: ## base @ >r decimal 0 0 bl word count >number 2drop d>s r> base ! ; \ decimal prefix
: +to postpone +-> ;
: -to negate postpone +-> ;
: narray ( n*items n <name> -- ) create dup 0 do dup i - pick , loop 0 do drop loop does> swap cells + @ ; ( create array of n items named name, to access item m do: m name )
: naddr ( idx <narray name> -- addr ) ' >code 3 cells + swap cells + ; ( idx is the index of the item in the narray )
: mycfa postpone [ here postpone literal ] ; immediate
: myxt postpone [ here code> postpone literal ] ; immediate
: $tolower >r r@ c@ r@ count 0 do dup c@ tolower over c! 1 + loop drop r> drop ;

: $substr? ( $string $substring -- f ) 
	count rot count ( str2 n str1 m ) 
	0 , ( match flag )
	0 pick 0 ( str2 n str1 m n 0 )
	do  ( str2 n str1 m )
		2 pick 0 ( str2 n str1 m n 0 ) ( set up substring loop )
		do ( str2 n str1 m )
			1 pick j + i + c@ tolower
			4 pick i + c@  tolower ( str2 n str1 m ch subch )
			= if
				1 here 1 cells - !
			else
				0 here 1 cells - !
				leave
			then
		loop
		here 1 cells - @ 1 ( get flag )
		= if ( all characters matched? )
			i ( leave character location on stack )
			leave ( if so, done )
		then
	loop  
	here 1 cells - @ 
	>r >r
	4 ndrop ( clean up stack )
	1 ,ndrop ( clean up dictionary ) 
	r> r>
	; 
0 [if]
: dmp $ 80
	base @ >r 
	hex
	cr ." -Address- 00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F  ---chars---" cr
	   ." ------------------------------------------------------------------------------"
	dump
	r> base ! ;
[then]
\ : hdr. 
	\ $ ff and $ f 0 do dup . ( dup 1 + 4 mod 0= if 8 emit $ 21 emit then ) 1 + $ ff and loop .
\ ; 
: _hdr. 
	$ ff and $ f 0 do dup 0 <# # #s #> type space 1 + $ ff and loop 0 <# # #s #> type
; 
: dmp $ 80
	base @ >r 
	hex 
	cr ."           00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F " cr

	." -Address- " over _hdr. ."   ---chars---" cr
	   ." ------------------------------------------------------------------------------"
	dump
	r> base ! ;
: dmpw ' >code dmp ; ( 'name' -- cfa mem dump )
: dmpxt >code dmp ; ( xt --- cfa mem dump )
: name. >name count type ; ( xt -- 'name' )
: find. find 1 = cr if ." Immediate." else ." Not immediate." then cr ; 
: .find bl word find. ;
$ 68 ' #cols >body ! ( change width of words output )
: dw dmpw ;
: dx dmpxt ;
: cs 0sp ;
: wl words.like ;

hex

: times ( xt n -- * ) 0 do dup >r  execute r> loop drop ;
: cp 0sp page ;

\ Very simple array system 
\ Structure:     | count/max (sid)   |    n cells    |
\ Supports two types of array. 
\ One is name based, arr.new, where array is created using create and is referred to by name.
\ The other, arr.noname,  is address based where array is created using allot.
\ 
\ The name based array used the words that require an sid to be put on the stack done by inputing the array name
\ The address based can be used with the name based words (putt, gett, peekk, etc.) but is really inteded 
\ to be used with the put, get, pic, etc. words. In order to use these words, the address (sid) of the desired array is 
\ first stored in the variable arra .

\ A support array, arrs, is created to store the array addresses for those without a name.

Marker array.stuff

0 Value arra \ variable to hold address of active array

: arr.noname ( n -- ) here dup >r 0 swap w! dup r@ cell 2 / + w! 1+ cells allot r> ; \ like arr.new but with no name, just address
: arr.new ( n <name> -- ) create latest name> >body ( n sid ) dup >r 0 swap w! ( n ) dup r> cell 2 / + w! 2 + cells allot ; 
: arr.stats ( sid -- count max ) @ dup $ ffff and swap $ 10 >> ; 
: arr.full.err ( count max -- ) over = if abort" Array full." then ;
: arr.empty.err ( count max -- count ) over 0= if abort" Array empty." then drop ; 
: arr.count ( sid -- n ) w@ ;
: arr.reset ( sid -- ) 0 swap w! ;

: gett ( sid -- x ) dup ( arr.stats arr.empty.err ) w@ (  sid count ) 2dup 2>r cells + @ 2r> 1 - swap  w! ;
: putt ( x sid -- ) dup ( arr.stats arr.full.err ) w@ ( x sid count ) 2dup 2>r 1+ cells + ! 2r> 1+ swap w! ;
: peekk ( sid -- x) dup arr.stats arr.empty.err cells + @ ;
\ : picc ( n sid -- x ) dup arr.stats over 1- 4 pick swap > if Abort" Index exceeds array count." then arr.empty.err ( n sid count ) rot - cells + @ ;
: picc ( n sid -- x ) dup arr.stats over 1- 4 pick swap > if Abort" Index exceeds array count." then arr.empty.err ( n sid count ) drop swap 1+ cells + @ ;
: arr.dump ( sid -- x** ) dup arr.count 0= if abort" Array empty." then dup , w@ 0 do dp @ cell - @ i 1+ cells + @ loop ,drop ;
: arr.load ( n*x n sid -- ) , 0 do dp @ cell - @ putt Loop ,drop ;
\ : arr.load ( n*x n sid -- ) 2dup w! ,  0 do i 1+ cells dp @ cell - @ + ! loop 0 cell - dp +! ;
\ : arr.load ( n*x n sid -- ) , dup >r 0 do i pick ,peek putt loop ,drop r> ndrop ;

\ prior to using these set arra  to sid
: get ( -- x ) arra  dup ( arr.stats arr.empty.err ) w@ (  sid count ) 2dup 2>r cells + @ 2r> 1 - swap  w!  ;
: put ( x -- ) arra  dup ( arr.stats arr.full.err ) w@ ( x sid count ) 2dup 2>r 1+ cells + ! 2r> 1+ swap w! ;
: pic arra picc ;
: pek 0 pic ;
: arr.dmp arra  arr.dump ;
: arr.lod ( n*x n -- ) arra  arr.load ;
: arr.cnt arra arr.count ;

22 arr.new arrs \ array to store array addresses in, 22 hex max

: reset s" _reset" evaluate s" marker _reset" evaluate ;
: 0reset 0sp reset ;
: mrk s" marker mrk" evaluate ;
marker _reset

hex

