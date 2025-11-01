\ Initialization file for various useful functions.

\ : .hex base @ hex swap . base ! ;
\ : .bin base @ bin swap . base ! ;

false [if]

    Put large scale comments
    in between a conditional compile
    like shown here.


    NOTE: Using 'find'.
        |
    This demonstrates: s" dup" here place here find.
        |
    s" dup" puts an addr/count pair on the stack.
    here puts an address on the stack.
    place makes a counted string of 'dup' at here consuming the stack.
    here puts the counted string address on the stack.
    'find' finds it. This method saves the <name> at here.
    You can also simply do s" dup" bl word find which will Return
    an address and a flag on the stack. Flag = 0 means the word wasn't found.

[then]

\ Quick and dirty temporary storage. Good till something is defined after
\ saving in these locations, i.e., 'here' changes.
: put ( n -- n ) dup here ! ;
: puti ( n idx -- n ) cells here + over swap ! ; \ Put in 'here' + n cells.
: get here @ ;
: geti ( idx -- n ) cells here + @ ;

\ 'here' as a stack. Pad is the counter. Data should be stable till 'here' changes.
\ Put 0 at pad before using.
: >here here pad @ dup >r cells + ! r> 1+ pad ! ;
: here> pad @ if here pad @ 1- dup >r cells + @ r> pad ! then ;
: here@ here pad @ cells + cell- @ ;
: 0here 0 pad ! ;
: phere >here ;
: herep here> ;
: .here here@ ;
: here. pad @ dup if 0 do i cells here + @ . loop else drop then ;
: 0pad 0 pad ! ;

\ Temporarty storage.
8 cells allocate drop constant temp \ Temporary storage.
: put.temp temp ! ; \ Put temp.
: get.temp temp @ ; \ Get temp.

\ Create self incrementing variable. Use with puti!
: make.counter create 0 , does> dup @ 2dup 1+ swap ! swap drop ;
: reset.counter ' >body 0 swap ! ; \ Usage: reset.counter <name>.

: tos.to.bos
    depth dup
    0= if drop ." Stack empty." cr abort then
    dup 1 >
    if
      swap put drop \ Save the TOS item.
      1 puti \ Save stack depth.
      1- 0 do 2 i + puti drop loop
      get \ Put old TOS on stack.
      1 geti 1- \ Get old stack depth.
      0 swap 1- do 2 i + geti -1 +loop
    else
      drop
    then ;

here variable origin origin !

c" base" find 0=
[if]
  : base. base @ dup decimal . base ! ;
[then]

c" re.set" find 0=
[if]
  : re.set
      s" ---marker---" evaluate
      s" marker ---marker---" evaluate
      cr cr 20 spaces s" Sytem reset." type cr cr ;
[then]

c" ---marker---" find 0=
[if]
  marker ---marker---
[then]

c" 0sp" find 0=
[if]
  : cs 0sp ;
[then]

: ?exit ( n -- )
    \ n is number of arguments needed on the stack.
    depth >= if cr ." Wrong number of arguments." cr rdrop exit then ;

    c" buf" FIND 0=
    [if]
      create buf 64 cells allot
      buf 64 cells 0 fill
    [then]

: cstring.to.addrn ( addr -- addr+1 n)
    1+ dup 1- c@ ;

: trunc15
  swap dup 15 > if drop 15 then swap ;

: move.to.buf ( source.addr n dest.addr -- )
    3 ?exit
    trunc15 \ Truncate character count.
    dup dup >r @ 1 + 2* cells + \ Calculate and save dest address.
    2dup ! \ Save character count.
    1+ \ Increment dest address to start of string dest.
    swap cmove \ Copy characters.
    1 r> +! ; \ Increment item count.

: show.last.item ( buf.addr - )
    1 ?exit
    cr cr
    DUP @ 2 * CELLS +
    COUNT TYPE
    cr cr ;

: show.item ( buf.addr n -- )
    2 ?exit
    cr cr
    2* cells + count type
    cr cr ;

: show.all ( buf.addr -- )
    1 ?exit
    cr
    dup @ \ Get item count.
    1+ 2 * cells \ Calculate loop end.
    [ 2 cells ] literal \ Calculate loop start.
    do dup i + cr count type \ Show buffer contents.
    [ 2 cells ] literal +loop
    drop cr cr ; \ Cleanup.

\ include c:\temp\init.f

: push.to.buf ( buf.addr -- )
    1 ?exit
    13 parse rot move.to.buf ;

: bdump ( buf.addr -- )
    1 ?exit
    dup @ 1+ 2* cells dump ;

: convert.to.cstring ( addr1 n addr2 --- addr2 )
    \ addr1 is start of string and n is character count.
    \ addrs is sart of resulting counted string.
    3 ?exit
    2dup ! dup >r 1+ swap cmove r> ;

\ Show built in user stack, like .s.
\ User stack is peculiar to pforth.
: .us ( -- )
    USTACK @ 8 / 1 ?DO
    I CELLS [ ustack ] literal + @ .
    LOOP ;

: usp ( index -- stack value )
    ustack stack.pick ;

: uc ( -- count of items on user stack )
  ustack @ 8 / 1- ;

  : save.string 13 parse dup >r here place r> allot ;

  : char.to.cells ( n -- )
  \ n is the character count.
  dup 8 / swap 8 mod
  if 1 + then
  ;

\ 128 cells allocate drop
: make.buf ( n -- ) \ Name of costant goes after make.buf.
  \ Usage: <number of cells> make.buf <buffer name>.
    cells allocate drop constant ;
128 make.buf str.buf
\ constant str.buf
0 str.buf !
str.buf cell+ value str.buf.next
str.buf.next dup cell+ swap !

: str.store 13 parse dup >r \ Get string and save count.
  \ Usage: str.store <string>.
    str.buf.next dup >r @ dup >r place \ Store string and save address.
    r> r> swap r> + 1+ swap ! \ Calc next address and save.
    1 str.buf +! ; \ Increment item count.

: str.get.first ( -- addr n )
    str.buf 2 cells + dup c@ ;

: str.get.next ( addr n -- addr+ n+ )
    + 1+ dup c@ ;

: str.get.idx ( idx -- addr n )
    >r str.get.first \ Stack: addr n.
    r> 0 ?do
      str.get.next
    loop ;

\ The following demonstrates how to capture and save a part of the input stream.

: aaa
    cells allocate drop       ( Create string buffer )
    >in @ >r                  ( Save the current input buffer pointer.)
    bl word count temp place  ( Save string buffer name captured from the input string )
    \ r> dup >r >in !
    r> >in !                  ( Restore input buffer pointer )
    \ The second save.input.pointer sets up the repeat of the input buffer after the constant word.
    constant
    \ r> >in ! bl word count type ( Redo input buffer again to test a repeat )
    \ Apparently the input buffer pointer can be fiddled with indefinetly.
    ;

\ Same as above aaa but enhanced.
\ Also sets up the string buffer structure for counted strings
\ used above in str.store with a modification.
\ Buffer structure is 1st byte - current count, 2nd byte - max cell count, next
\ cell - next available address, and remaining bytes are for characters.
\ Note this is a string buffer that uses bytes, not cells.
\ This will probably work with str.store. Just name the buffer str.buf.

\ For future structures that use cells instead of bytes, the 3rd byte of the
\ first cell could be used to store number of cells per element.

\ '<name> count evaluate' gets buffer address from buffer name
\ stored in variable temp. Evaluate needs addr and count.
: exec count evaluate ; \ exec means execute.

: make.str.buf1
  \ Usage: <number of cells> make.str.buf <buffer name>
      dup >r ( Save max number of elements ) 2 + cells allocate drop
      >in @ >r ( Save input pointer )
      bl word count temp place ( Save buffer name in variable temp )
      r> >in ! ( Restore input pointer )
      constant
      temp exec r> dup >r 2 + cells 0 fill ( Zero buffer )
      temp exec 0 swap c! ( Zero element count )
      temp exec 1+ r> swap c! ( Store max number of elements )
      temp exec dup 2 cells + swap cell+ ! ; ( Save next element address )

\ The following is similar to make.str.buf1 but needs no external variable.
: make.str.buf2 ( n -- )
  \ Usage: <number of cells> make.str.buf <buffer name>
      dup >r ( Save max number of elements ) 2 + cells allocate drop dup >r \ Save buffer address.
      constant
      \ The constant is named <buffer name> and holds the address of the buffer.
      \ Return stack has 2 items, r1 and r2, r2 is the top of the stack.
      \ r1 = max allowable number of buffer elements.
      \ r2 = the buffer address.
      2r@ swap 2 + cells 0 fill ( Zero buffer )
      r@ 0 swap c! ( Zero element count )
      r@ dup 2 cells + swap cell+ ! ( Save next element address )
      2r> 1+ c! ( Save max number of elements )
      ;

\ The following is similar to make.str.buf2 but does not use the return stack.
: make.str.buf ( n -- )
  \ Usage: <number of cells> make.str.buf <buffer name>
      dup ( Save max number of elements ) 2 + cells allocate drop dup \ Save buffer address.
      constant
      \ The constant is named <buffer name> and holds the address of the buffer.
      \ The stack has 2 items, r1 and r2, r2 is the top of the stack.
      \ r1 = max allowable number of buffer elements.
      \ r2 = the buffer address.
      2dup swap 2 + cells 0 fill ( Zero buffer )
      dup 0 swap c! ( Zero element count )
      dup dup 2 cells + swap cell+ ! ( Save next element address )
      1+ c! ( Save max number of elements )
      does>
        @ dup cell+ @ swap dup c@ \ Stack contains next addr, buffer addr, and count.
        here cell+ ! swap here !
      \ Stack contains the buffer address.
      \ 'here' and 'here + 1 cell' contain the next addr and count respectively.
      ;

\ Exception stuff.

: aa depth 0= if 2 throw else ." aa here " then ;
\ : aa ['] drop catch ;
: bbb ['] aa catch 0= if ." no error " else ." was error" then ;

\ Auto indexing an array.
: make.auto.array cells allocate drop create , does> @ swap cells + ;
\ Usage: number of cells (on the stack) make.auto.array <name>.
\ Then do idx <name> and the address of the cell is left on the stack.
\ NOTE: This does not store in the dictionary area.

false [if]
    The above aa and bb seems to catch the throw in aa when the stack is empty.
    It does not however, catch a stack underflow if aa is redefined to drop.


    The following will act the same as entering a variable, constant, value, or name
    made with 'create'. For a variable, constant, or value it will return the
    value of the item. For a name made with 'create' it will return the address.
    This allows the user to do a <word.after> <name> type construct
    instead of a <name> <some word> type construct. Could be useful.
    This allows passing parameters after the command word instead of placing them
    on the stack prior to issuing the command word.
[then]
: word.after bl word find drop
    if >body @ then ;

: bb \ this doesnt work.
    begin
      bl word count dup
      0<> if type then
    until ;

cs


buf push.to.buf one
buf push.to.buf onetwo
buf push.to.buf onetwothree
buf push.to.buf onetwothreefour
