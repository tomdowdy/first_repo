

: my-marker here latest create , , does> 2@ context ! here - allot ; 
: allot- cells negate allot ;
: ,pop here cell - dup dp ! @ ;
: ,npush 0 do , loop ;
: ,npop 0 do ,pop loop ;
: ,peek here cell - @ ;
: ,peekn cells here dup rot - do i @ cell +loop ;
: ,npic 1+ cells negate here + @ ;
: ,drop 0 1 - allot ; \ dictionary drop
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
( The following two words, when placed immediately after the name of the word being defined, will cause the word to place its cfa or xt on the stack when executed. Use: : qq myxt do something ; will put the xt of qq on the stack when qq is executed )
: mycfa postpone [ here postpone literal ] ; immediate ( put the cfa of the word this is in on the stack when executed )
: myxt postpone [ here code> postpone literal ] ; immediate ( put the xt of the word this is in on the stack when executed )
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
: hdr. 
	$ ff and $ f 0 do dup 0 <# # #s #> type space 1 + $ ff and loop 0 <# # #s #> type
; 
: dmp $ 80
	base @ >r 
	hex 
	cr ."           00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F " cr

	." -Address- " over hdr. ."   ---chars---" cr
	   ." ------------------------------------------------------------------------------"
	dump
	r> base ! ;
: dmpw ' >code dmp ; ( 'name' -- cfa mem dump )
: dmpxt >code dmp ; ( xt --- cfa mem dump )
: name. >name count type ; ( xt -- 'name' )
: find. find 1 = if ." Immediate." else ." Not immediate." then cr ; 
$ 68 ' #cols >body ! ( change width of words output )
: dw dmpw ;
: dx dmpxt ;
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
	: stk.prev stk dup cell - @ 0= if cr ." No more stacks." cr abort then dp ! ,pop to stk ;
	: :stk stk , stk.new ;

variable tmp 0 tmp !
: wl words.like ;
: reset s" _reset" evaluate s" marker _reset" evaluate ;
: 0reset 0sp reset ;
marker _reset
hex

