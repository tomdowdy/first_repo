0 value active-noname
0 value noname-active
0 value compiling-noname
: reset-noname 
		0 to compiling-noname
		0 to active-noname
		0 noname-active
;
: noname: noname-active 
	if 
		cr abort" Noname already active." 
	else 
		here to noname-active :noname 
		1 to compiling-noname 
	then 
;
: noname; compiling-noname
	if 
		postpone ; 
		dup to active-noname 
		0 to compiling-noname
	else
		cr abort" Not compiling a noname."
		reset-noname
	then
; immediate
: noname- 
	noname-active if 
		noname-active dp ! 
		reset-noname
	else 
		cr abort" Noname not active." 
		reset-noname
	then 
;
: noname active-noname execute ;
: ; compiling-noname 
	if 
		cr abort" Compiling noname, use noname;." 
		reset-noname
	else 
		postpone ; 
	then 
; immediate
