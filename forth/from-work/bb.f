
: get.file 
cr ." here 1" cr
	s" c:\temp\pforth\bb.txt" r/o open-file
." 2 show stack " .s cr
	0= if 
." 3 show stack " .s cr
		to file.id
		0 0 0
		begin
cr ." 7 stack dump " .s
			here 2 pick + 999 file.id read-line
cr ." 6 stack dump " .s
		2 pick ( get # of bytes read )
		0= until
		file.id close.file
		\ forget ctr
	else
." here 4" cr
		abort" bad file " 
	then
." here 5" cr
abort" test abort"
;
\ get.file
