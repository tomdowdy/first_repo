
hex
0 value stack.start
here value initial.stack
\ : not true xor ;
\ : cs clearstack ;
: ds stack.start ( -- ) [ 32 cells ] literal dump ; \ Dump stack from stack.start.
: es stack.start ( -- ) [ 32 cells ] literal 5a fill ; \ Empty stack from stack.start.
: dmp ( addr -- addr; display memory contents.) dup [ 32 cells ] literal dump ; \ Dump selected memory.
: reset s" ---marker" evaluate s" marker ---marker" evaluate 0sp ;
: is.imm bl word find 1 = if -1 else 0 then swap drop ;
: >cstr ( same as 'place'. from.addr cnt to.addr ---> ) swap dup >r over >r swap 1+ swap cmove r> dup r> swap c! ;
: get.addr cell allocate drop dup free drop ;
: init here to stack.start ;
\ : xt>name ( token to name, done for documentation of sn ) >name id. ;
\ : sn xt>name ;
: dec. base @ >r dup decimal . r> base ! ;
: hex. base @ >r dup hex . r> base ! ;
: clear.here here [ 32 cells ] literal [ 5a ] literal fill ;
: clear.at [ 32 cells ] literal [ bl ] literal fill ;
: cs page ;
: decomp bb40 execute ;
\ : input.number bl word number? 0= if cr abort" not a number" then ;
: wl words.like ;
\ : is.name parse-name find-name if true else false then ;
: peek.stack dup stack> dup rot >stack ; \ name peek.stack.
: push.stack >stack ; \ value name push.stack.
: pop.stack stack> ; \ name pop.stack.
: make.stack :stack ; \ size make.stack name.

: qm s" marker qmm" evaluate ; \ Quick marker.
: my.words1 cr ." initial.stack stack.start ds es dmp reset is.imm >cstr" cr ;
: my.words2 ." get.addr init sn clear.here clear.atcs decomp input.number" cr ;
: my.words3 ." is.name make.stack push.stack pop.stack peek.stack qm reinit my.words" ;
: my.words my.words1 my.words2 my.words3 cr cr ;
32 make.stack m.s

: reinit s" include c:\temp\my-extra.f" evaluate ;

marker ---marker
init
\ reinit
