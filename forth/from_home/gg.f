\ probably for mf348 forth

hex
variable stack.start
: not true xor ;
: cs depth 0= not if 0 do drop loop then ;
: ds stack.start [ 32 cells ] literal dump ;
: es stack.start [ 32 cells ] literal 5a fill ;
: dmp dup [ 32 cells ] literal dump ;
: reset s" ---marker" evaluate s" marker ---marker" evaluate cs ;
: is.imm bl word find 1 = if -1 else 0 then swap drop ;
: >cstr ( same as 'place'. from.addr cnt to.addr ---> ) swap dup >r over >r swap 1+ swap cmove r> dup r> swap c! ;
: get.addr cell allocate drop dup free drop ;
: init here stack.start ! ;
: xt>name ( token to name, done for documentation of sn ) >name id. ;
: sn xt>name ;
: dec. base @ >r dup decimal . r> base ! ;
: hex. base @ >r dup hex . r> base ! ;
: clear.here here [ 32 cells ] literal [ 5a ] literal fill ;
: clear.at [ 32 cells ] literal [ bl ] literal fill ;
: cs ( clear screen, sort of ) 20 0 do cr loop ;
: decomp bb40 execute ;
\ : input.number bl word number? 0= if cr abort" not a number" then ;
\ : wl words.like ;
: my.words cr ." ds es dmp reset is.imm >cstr get.addr init sn clear.here clear.at dec. hex. cs decomp input.number wl my.words" cr cr ;
marker ---marker
init