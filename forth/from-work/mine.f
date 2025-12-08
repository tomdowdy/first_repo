
: beginning-of-mine.f ( marks the beginning of my words ) 
	[ here literal ] ;

\ cell prior to here functions
: hd here cell - ; \ hd=address of cell before here
: hd.inc here cell - dup @ 1 + dup >r swap ! r> ;
	\ leaves new value on stack
: hd.dec here cell - dup @ 1 - dup >r swap ! r> ;
	\ leaves new value on stack
: hd0 ( -- flag ) hd.dec 0= ; \ count down
: hdn ( n -- flag ) hd.inc = ; \ count up

: ,p here cell - dup dp ! @ ; 
	\ pops item at cell before here onto stack
	\ and adjusts here
	\ used in conjunction with , word.
	\ Does not impact dcnt variable like ,psh and ,pop do.
	\ quick and dirty TOS save.
: -a ( addr -- x ) cell - @ ; \ -a = addr - cell look
	\ like hd but for an address on the stack
: times ( xt n -- * ) 0 do dup >r  execute r> loop drop ;
: tims ( n <name> -- * ) bl word find 0= if drop exit then swap times ;
: cs 0sp ;
: cp 0sp page ;

variable dcnt 0 dcnt !
: allot- ( n -- ) cells 0 swap - allot ;
\ : ,pop here [ 1 cells literal ] - @ [ 0 1 cells - literal ] dp +! ( allot ) ;
\ : ,pop 0 cell - dp +! dp @ @ ;
: ,psh depth if , 1 dcnt +! else cr ." Stack empty." cr abort then ;
: ,pop dcnt @ if 0 cell - dp dup -rot +! @ @ 0 1 - dcnt +! else cr ." Dstack empty." cr abort then ;
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
: ,cnt dcnt @ ;
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
\ 0 [if]
\ : dmp $ 80
\ 	base @ >r 
\ 	hex
\ 	cr ." -Address- 00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F  ---chars---" cr
\ 	   ." ------------------------------------------------------------------------------"
\ 	dump
\ 	r> base ! ;
\ [then]

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

\ use my-marker to mark a spot by storing the address
\ of the location at that location 
\ then do find-mymarker to find it again
\ method relies on the slim change that a memory location
\ will hold its address.

: find.mrk here $ 200 cells - here 
begin 
	dup dup @ = if swap drop exit then [ 1 cells literal ] - 
	2dup =
until 2drop
;
: rstr.mrk find.mrk dp ! ;
: mrk here , ;

hex
 
include C:\GitHub\first_repo\forth\from-work\yaa_stck_from_work.f

include C:\GitHub\first_repo\forth\from_home\pad_stuff.f

\ not that quick and dirty dump ddmp
: ddmp ( addr -- )
	base @ >r hex
	tmp.bac
	\ tmpa=cell count tmpb=line count
	0 itmpa 0 itmpb
	\ tmpc=start-addr tmpd=end-addr
	dup itmpc 4 cells f * + itmpd
	cr cr
	begin
		tmpb 0= if
			tmpc dup 0 <# # # # # # # # #s #> type ."  |"
			c@ 0 <# # #s #> type
		else
			tmpc c@ 0 <# # #s #> type
		then
		4 tmpa.cnt if
			." |"
			0 itmpa
		else
			space
		then
		10 tmpb.cnt if
		cr 0 itmpa 0 itmpb
		then
		tmpd tmpc.cnt 
	until
	tmp.rstr
	cr 
	r> base !
;

: reset 
	0sp 
	0 dcnt !
	0 stk !
	s" _reset" evaluate s" marker _reset" evaluate ;

variable buf
	here base @ >r hex
		100 cells + buf ! 
		r> base !            \ buffer area above here
	: bufa buf @ ;
	: bufb buf 1 cells + @ ;
	: bufc buf 2 cells + @ ;
	: bufd buf 3 cells + @ ;
	: ibufa buf ! ;
	: ibufb buf 1 cells + ! ;
	: ibufc buf 2 cells + ! ;
	: ibufd buf 3 cells + ! ; 
	: gbuf ( n -- x ) cells buf @ + @ ;
	: pbuf ( x n -- ) cells buf @ + ! ;
: my-mrk s" marker my-mrk" evaluate ;
marker _reset

hex

