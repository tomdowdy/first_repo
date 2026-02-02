0 value active-noname
\ stores prior dictionary top and indicates an active noname
0 value noname-active 
0 value compiling-noname
: _reset-noname 
		0 to compiling-noname
		0 to active-noname
		0 to noname-active
;
: noname: noname-active 
	if 
		cr s" Noname already active." cr
		22 throw
	else 
		here to noname-active 
		1 to compiling-noname 
		:noname 
	then 
;
: noname; compiling-noname
	if 
		postpone ; 
		dup to active-noname 
		0 to compiling-noname
	else
		cr s" Not compiling a noname." cr
		_reset-noname
		23 throw
	then
; immediate
: noname- 
	noname-active if 
		noname-active dp ! 
		_reset-noname
	else 
		cr ." Noname not active." cr
		_reset-noname
		22 throw
	then 
;
: noname active-noname execute ;
: ; compiling-noname 
	if 
		cr ." Compiling noname, use noname;." cr
		noname;
	else 
		postpone ; 
	then 
; immediate
: noname-bak
	noname-active if
		noname-active ,
		active-noname ,
	else
		cr ." Noname not active." cr
		22 throw
	then
;
: noname-restore
	here cell - @ active-noname !
	0 cell - allot
	here cell - @ noname-active !
	0 cell - allot
;

