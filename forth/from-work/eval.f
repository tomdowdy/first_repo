: -leading ( addr n -- addr n )
( remove leading spaces )
Begin
   dup 0>
   2 pick c@ bl = and
  if
      1 /string
   then
 over c@ bl <>
 over 0= or
until
;

Create bfr 64 cells allot
Create arr 64 cells allot
0 variable offst offst !

: addrn>caddr ( addr n - caddr )
( assumes bfr array exists )
dup bfr dup >r c!  r@ 1 + swap cmove r>
;

: parse-str ( addr len -- word-addr word-len rest-addr rest-len )
	( parse word  on blank )
	Dup 0= if 2drop exit then
	-trailing
	\ start remove leading spaces = a
		Begin
			Over c@ bl =
		While
			1 /string
		Repeat
	\ end a
	Over >r 
	Begin
		Over c@ bl = >r
		1 /string dup 0= ( addr cnt flg )
		r> or
	Until
	r@ 2 pick swap -
	Over 0<> +
	r> swap 2swap
;

: str>xt ( addr n -- xt )
	( interpret string and leave an xt for sequence on stack )
	dup 0= if exit then
	0 offst !
	Begin
		parse-str 2>r
		addrn>caddr
		find 
		if 
			arr offst @ + ! Cell offst +!
		Else
			Count 0 0 2swap >number 0=
			If
				Drop
				d>s
				['] (literal) arr offst @ + 2!
				2 cells offst +!
			Else
				Cr Abort" error in text"
			Then
		Then
		2r> dup 0=
	Until
	0 arr offst @ + !
	Cell offst +!
	2drop
	Arr codebase -
;

: eval-str ( addr n -- text stack effects )
	( interpret string as if from keyboard )
	dup 0= if exit then
	Begin
		parse-str 2>r
		addrn>caddr
		find 
		if 
			execute
		Else
			Count 0 0 2swap >number 0=
			If
				Drop
				d>s
			Else
				Cr Abort" error in text"
			Then
		Then
		2r> dup 0=
	Until
	2drop
;