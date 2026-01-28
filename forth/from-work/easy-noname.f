0 value active-noname
0 value noname-active
: noname: noname-active 0= if here to noname-active :noname else cr abort" Noname already active." then ;
: noname; postpone ; dup to active-noname ; immediate
: noname- 
	noname-active 0= if 
		cr abort" Noname not active." 
	else 
		noname-active dp ! 0 to noname-active 
		0 to active-noname
	then 
;
