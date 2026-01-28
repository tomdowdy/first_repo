0 value active-noname
0 value noname-active
0 value compiling-noname
: reset-noname 
		0 to compiling-noname
		0 to active-noname
		0 to noname-active
;
: noname: noname-active 
	if 
		cr abort" Noname already active." cr
	else 
		here to noname-active 
		:noname 
		1 to compiling-noname 
	then 
;
: noname; compiling-noname
	if 
		postpone ; 
		dup to active-noname 
		0 to compiling-noname
	else
		cr s" Not compiling a noname." cr
		reset-noname
		abort
	then
; immediate
: noname- 
	noname-active if 
		noname-active dp ! 
		reset-noname
	else 
		cr ." Noname not active." cr
		reset-noname
		abort
	then 
;
: noname active-noname execute ;
: ; compiling-noname 
	if 
		cr ." Compiling noname, use noname;." cr
		reset-noname
		abort
	else 
		postpone ; 
	then 
; immediate
