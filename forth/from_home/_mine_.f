\ for pforth

: dmp $ 80
	base @ >r
	hex
	cr ." -Address- 00 01 02 03|04 05 06 07|08 09 0A 0B|0C 0D 0E 0F  ---chars---" cr
	   ." ------------------------------------------------------------------------------"
	dump
	r> base ! ;
: dw ' >code dmp ;
: dxt >code dmp ;
: name. >name count type ;
: find. find . . ;
: >caddr dup pad ! pad 1+ swap cmove pad ;
: xt>nt >name ;
: caddr>nt ( caddr -- nt flag|flag ) find if xt>nt -1 else drop 0 then ; \ Returns 0 if word is not defined.
: addrn>nt ( addr n -- nt ) >caddr caddr>nt ;
: inp>nt ( Takes word from input stream and returns nt or 0. Usage: inp>nt <name> ) bl word caddr>nt ;
: inp>xt bl word find not if drop 0 else -1 then ;
: find. bl word find cr dup 0= if 2drop ." Word not found." cr else -1 = if ." Not immediate." cr else ." Immediate." cr then then ;
: reset s" _reset" evaluate s" marker _reset" evaluate ;
' #cols >body $ 72 swap ! \ change number of columns displayed by the word, words.
