: _hdr. 
	$ ff and $ f 0 do dup 0 <# # #s #> type space 1 + $ ff and loop 0 <# # #s #> type
; 
: dmp $ 80
	base @ >r 
	hex 
	cr ."           00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F " cr

	." -Address- " over _hdr. ."   ---chars---" cr
	   ." ------------------------------------------------------------------------------"
	dump
	r> base ! ;