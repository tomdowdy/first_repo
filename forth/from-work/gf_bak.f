hex
0 value dump.start
0 value file.id
: init here to dump.start ;
: reset s" ---marker" evaluate s" marker ---marker" evaluate 0sp ;
: close.file file.id close-file ;
: ds dump.start [ 32 cells ] literal dump ;
: es dump.start [ 32 cells ] literal 5a fill ;
: dmp dup [ 32 cells ] literal dump ;
: is.imm bl word find 1 = if -1 else 0 then swap drop ;
: >cstr ( from.addr cnt to.addr ---> ) swap dup >r over >r swap 1+ swap cmove r> dup r> swap c! ; \ same as 'place'. 
: get.free.addr ( -- addr ) cell allocate drop dup free drop ; \ gets a free address location.
: xt>name ( token to name, done for documentation of sn ) >name id. ;
: sn xt>name ;
: dec. base @ >r dup decimal . r> base ! ;
: hex. base @ >r dup hex . r> base ! ;
: clear.here ( --- ) here [ 32 cells ] literal [ 5a ] literal fill ;
: clear.at ( addr --- ) [ 32 cells ] literal [ bl ] literal fill ;
: cs ( clear screen, sort of ) 20 0 do cr loop ; \ use page instead.
: decomp bb40 execute ; \ decompile a word.
: input.number bl word number? 0= if cr abort" not a number" then ;
: wl words.like ;
: dup.stack depth 0 do r@ 1- pick loop ; \ r@ gets something like the loop count, I think.
: my.words1 cr cr ." reset ds es dmp reset is.imm >cstr get.free.addr init sn clear.here" ;
: my.words2 ." clear.at dec. hex. cs decomp input.number wl dup.stack my.words stack.start" cr cr ;
: my.words my.words1 my.words2 ;
: stack.start dump.start ;
marker ---marker
init
