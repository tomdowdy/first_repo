
: beginning-of-mine ( marks the beginning of my words ) ;

: ,p here cell - dup dp ! @ ; \ used in conjunction with 
	\ ,. Does not impact dcnt variable like ,psh does.
	\ quick and dirty TOS save.

variable dcnt 0 dcnt !
: allot- cells negate allot ;
\ : ,pop here [ 1 cells literal ] - @ [ 0 1 cells - literal ] dp +! ( allot ) ;
\ : ,pop 0 cell - dp +! dp @ @ ;
: ,psh , 1 dcnt +! ;
: ,pop 0 cell - dp dup -rot +! @ @ 0 1 - dcnt +! ;
: ,npsh 0 do ,psh loop ;
: ,npop 0 do ,pop loop ;
\ : ,pick 1+ cells negate here + @ ;
: ,pic 1+ cells dp @ swap - @ ;
: ,npic cells here dup rot - ?do i @ cell +loop ;
: ,peek dp @ cell - @ ;
: ,drop 0 cell - dp +! 0 1 - dcnt +! ; \ dictionary drop
: ,ndrop 0 ?do ,drop loop ;
: ,swap ,pop ,pop swap , , ;
: ,rot ,pop ,pop ,pop rot , , , ;
: ,-rot ,pop ,pop ,pop -rot , , , ;
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
 
include C:\GitHub\first_repo\forth\from-work\yaa_stck_from_work.f

include C:\GitHub\first_repo\forth\from_home\pad_stuff.f

: reset 
	0sp 
	0 dcnt !
	0 stk !
	s" _reset" evaluate s" marker _reset" evaluate ;
: mrk s" marker mrk" evaluate ;
marker _reset

hex

