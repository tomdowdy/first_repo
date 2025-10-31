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
\ \ : hdr. 
\ 	\ $ ff and $ f 0 do dup . ( dup 1 + 4 mod 0= if 8 emit $ 21 emit then ) 1 + $ ff and loop .
\ \ ; 
\ : _hdr. 
\ 	$ ff and $ f 0 do dup 0 <# # #s #> type space 1 + $ ff and loop 0 <# # #s #> type
\ ; 
\ : dmp $ 80
\ 	base @ >r 
\ 	hex 
\ 	cr ."           00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F " cr

\ 	." -Address- " over _hdr. ."   ---chars---" cr
\ 	   ." ------------------------------------------------------------------------------"
\ 	dump
\ 	r> base ! ;

include C:\GitHub\first_repo\forth\from-work\dmp.f

: dmpw ' >code dmp ; ( 'name' -- cfa mem dump )
: dmpxt >code dmp ; ( xt --- cfa mem dump )
: name. >name count type ; ( xt -- 'name' )
: find. find 1 = cr if ." Immediate." else ." Not immediate." then cr ; 
: .find bl word find. ;
$ 68 ' #cols >body ! ( change width of words output )
: dw dmpw ;
: dx dmpxt ;
: wl words.like ;

hex
 
: times ( xt n -- * ) 0 do dup >r  execute r> loop drop ;
: tims ( n <name> -- * ) bl word find 0= if drop exit then swap times ;
: cs 0sp ;
: cp 0sp page ;

0 value stk
: stk.noname ( n -- sid ) here 0 , over , swap 2+ cells allot ;
: psh ( x sid -- ) dup 2@ = if cr ." Full." cr abort then 1 over +! ( n sid ) r> 2+ cells + ! ;
: pop ( sid -- x ) dup @ dup 0= if cr ." Empty." cr abort then 0 1 -  over +! r> 1+ cells + @ ;

: stk.new ( n -- ) stk.noname to stk ;
\ : put ( x -- ) stk dup 2@ = if cr ." Full." cr abort then dup @ 1+ dup >r ( n sid nxt ) over ! r> 1+ cells + ! ;
: put ( x -- ) stk dup 2@ dup >r = if cr ." Full." cr abort then 1 over +! ( n sid ) r> 2+ cells + ! ;
\ : get ( -- x ) stk dup @ dup 0= if cr ." Empty." cr abort then dup >r 1- over ! r> 1+ cells + @ ; 
: get ( -- x ) stk dup @ dup >r 0= if cr ." Empty." cr abort then 0 1 -  over +! r> 1+ cells + @ ;
: top stk dup @ 1+ cells + @ ;
: bot stk 2 cells + @ ;
: pic ( n -- x ) 2+ cells stk + @  ;
: stk.remaining stk 2@ - ;
: look stk dup 2 cells + swap @ 0 ?do dup >r @ r> cell + loop drop ;
: cnt stk @ ;
: swp stk dup @ cells + dup 2@ swap rot 2! ;
: rots ['] get 3 times rot ['] put 3 times ;
: -rots ['] get 3 times -rot ['] put 3 times ;
: stk.prev stk dup @ 0<> if cr ." No more stacks." cr abort then dp ! ,pop to stk ;
: :stk stk , stk.new ;

\ The ] square bracket is a substitute for the > sign.
\ ] is easier since it is unshifted.
: ]pada pad ! ;
: ]padb pad cell + ! ;
: ]padc pad 2 cells + ! ;
: ]padd pad 3 cells + ! ;
: pada] pad @ ;
: padb] pad cell + @ ;
: padc] pad 2 cells + @ ;
: padd] pad 3 cells + @ ;

: reset s" _reset" evaluate s" marker _reset" evaluate ;
: 0reset 0sp reset ;
: mrk s" marker mrk" evaluate ;
marker _reset

hex

