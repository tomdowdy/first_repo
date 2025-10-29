\ string stack geforth 6.3.2013, f83 1986 mka
\ 03/09/2013 works again in principle. debugging necessary.
\ 03/10/2013 everything ok


 
: -- bye ;

: OK ; \ tested ok

\ vocabulary stringstackwords stringstackwords definitions

\ decimals

\ : ($ postponed ( ; immediate
: ($ postpone ( ; immediate

false [if] String stack structure

Stack is growing down in memory space.
-------------------------------------------------- -

here3 (bot$) <-- bot$ is saved here
here2: sp$ <-- 'SP$ is pointing there
top of stack: s0 top$
                s1 sec$
                ...
                sn
bot of stack: her0+cell bot$ <-- end of string stack
here0: (sp$) <-- sp$ location is saved here
header: <name>

-------------------------------------------------- -
[then]


variable 'SP$ \ holds string stack pointer location.
variable CSP$ \ store a current stack pointer there. String stack "marker".
: create-stringstack ( "name n -- )  
   create   
   here 0 , ( -- n here0 )
   swap allot align ( -- here0 )
   here over ! \ save sp$ addr to her0
   here 'sp$ ! \ init ' pointer
   here , \ init sp$ to itself
   cell+ , \ save bottom addr
   does> @ 'sp$ ! ;

1000 create-stringstack $S
OK



\ stringstack basics (stringstack unchanged).

: SP$ ( -- addr ) 'sp$ @ ;
: TOS$ ( -- addr ) sp$ @ ;
: BOT$ ( -- addr ) sp$ cell+ @ ;

: !CSP$ ( -- ) tos$ csp$ ! ; \ store current stack pointer

: ?CSP$ ( -- ) tos$ csp$ @ <> abort" $stack changed" ;
: ?OFL ( addr -- ) bot$ u< abort" $overflow" ;
: ?LIM ( len -- ) $FF00 and abort" $toolong" ; ( ??? )
: ?MTY ( addr -- ) sp$ >= abort" $underflow" ;
: ?FIT ( len -- ) tos$ c@ u> abort" $does'nt fit in tos$ " ;

: SKIP$ ( addr1 -- addr2 ) count + ;
: PICK$ ( nth -- addr )
     tos$ begin dup ?mty swap ?dup while 1- swap skip$ repeat ;

: TOP$ ( -- addr ) 0 pick$ ;
: SEC$ ( -- addr ) 1 pick$ ;
: DEPTH$ ( -- n ) ($ sn..s0 )  
     0 tos$ begin dup sp$ - while skip$ swap 1+ swap repeat drop ;
\ : LAST$ ( -- addr ) depth$ 1-pick$ ;
OK



\ addressing top string
 

: TOPCOUNT$ ( -- addr+1 len ) ($ -- ) top$ count ;
: TOPLENGTH$ ( -- len ) ($ -- ) top$ c@ ;
: TOPLOC$ ( +n -- addr ) ($ -- ) top$ + ;

: GET$ ( n -- char ) toploc$ c@ ;
: PUT$ ( char n -- ) toploc$ c! ;

\ use to move part of strings around
: EXTRACT$ ( n1 n2 -- from.adr len )  
\    toplength$ umin over - 1+ swap toploc$ swap ;
    toplength$ min over - 1+ swap toploc$ swap ;
: PATCH$ ( len n -- to.adr len )  
    2dup + ?fit toploc$ swap ;
OK



\ move strings to and from top of stringstack
\ (number of items on string stack changed!)

: "PUSH ( from.adr len -- ) ($ -- s ) \ push string to stringstack.
     dup ?lim tos$ over - 1- dup ?ofl dup sp$ ! place ;
: "POP ( -- from.adr len ) ($ s -- )  
     topcount$ 2dup + sp$ ! ;
: "CHAR ( char -- ) ($ -- s ) here ( dumy adr) 1 "push topcount$ drop c! ;

: "@ ( from.buffer -- ) ($ -- s ) count "push ;
\ : "! ( to.buffer -- ) ($ s -- ) "pop red place ;
: "! ( to.buffer -- ) ($ s -- ) "pop place ;

: "COPY ( to.buffer -- ) ($ s -- s ) \ non destructive
\    topcount$ red place ;
    topcount$ place ;
OK



\ stringstack operators
: "EMPTY ( -- ) ($ sn..s0 -- ) sp$ dup ! ; ok
: "CLEAR ( -- ) ($ sn..sm..s0 -- sn..sm ) csp$ @ sp$ ! ; ok
: "DROP ( -- ) ($ s -- ) "pop 2drop ; OK
: "PICK ( n -- ) ($ sm..sn..s0 -- sm..sn..s0 sn ) pick$ "@ ; OK
: "DUP ( -- ) ($ s -- ss ) 0 "pick ; OK
: "OVER ( -- ) ($ ab -- aba ) 1 "pick ; OK
: "ROLL ( n -- ) ($ sn..s0 -- sn-1..s0 sn ) ok
     pick$ dup "@ tos$ tuck - "pop + swap cmove> ;
: "ROLLDOWN ( n -- ) ($ sn..s1 s0 -- s0 sn .. s1 ) ok
     pick$ skip$ dup topcount$ + tuck - tos$ swap
\     "dup cmove "pop red over - 1- place ;
     "dup cmove "pop over - 1- place ;
: "SWAP ( -- ) ($ ab -- ba ) 1 "roll ; OK
: "RED ( -- ) ($ abc -- bca ) 2 "roll ; OK



\ manipulate top strings
: "JOIN ( -- ) ($ ab -- ab ) ok
     tos$ dup >r "pop dup toplength$ + r> c! over sp$ ! 1+ cmove> ;  
: "SPLIT ( n -- ) ($ ab -- ab ) ok
     toplength$ over - over toploc$ >r >r
     "pop drop swap over 2 - dup sp$ ! place r> r> c! ;
\ : "PATCH ( n -- ) ($ abcd xx -- axxd ) "pop red patch$ cmove ; OK
: "PATCH ( n -- ) ($ abcd xx -- axxd ) "pop patch$ cmove ; OK
: "EXTRACT ( n1 n2 -- ) ($ asb -- s ) extract$ "drop "push ; ok
: "INSERT ( n -- ) ($ ab s -- asb ) ok
     "swap "split "red "swap "join "join ;

\ change top string
: "FILL ( c -- ) ($ s -- cc ) \ replace characters with c ok
\    topcount$ red fill ;
    topcount$ fill ;
: "BLANK ( -- ) ($ s -- bl ) \ replace characters with blanks ok
     bl "fill ;
\ 46 "fill ; \ testing

: "APPEND ( char -- ) ($ s1 -- s2 ) "char "swap "join ; OK
: "INFRONT ( char -- ) ($ s1 -- s2 ) "char "join ; ok
: "ENROL ( char -- ) ($ s - s' ) ok
     topcount$ 1- 2dup >r dup 1+ swap r> cmove + c! ;
: "BLANKS ( len -- ) ($ -- s ) \ make blank string ok
    here swap "push "blank ;
: "SUPP ( len -- ) ($ s -- s bl ) \ make supplement blank string ok
    toplength$ - 0 max "blanks ;
: "L ( len -- ) ($ s -- s_bl ) "supp "swap "join ; OK
: "R ( len -- ) ($ s -- bl_s ) "supp "join ; ok



\ special string types
\ : "" ( -- ) ($ -- s ) 0 0 "push ;
\ : "D ( d -- ) ($ -- s ) (d.) "push ;
\ : "0 ( -- ) ($ -- s ) 0 0 "d ;
\ : "NUMBER ( -- d ) ($ s -- )  
\ lenght$ ​​toploc$ c@ bl = not IF bl "append THEN
\ "pop drop number ;
\ : (D.PRICE) ( d -- addr len )
\ tuck dabs <# # # ascii . hold #s red sign #> ;
\ : "PRICE ( -- ) ($ s -- $US ) "number (d.price) "push ;



\ string comparators
: COMPARE$ ( -- n ) ($ s1 s0 -- s1 s0 ) ok
    top$ count sec$ count compare ;
: "COMPARE ( --- n ) ($ s1 s2 -- ) compare$ "drop "drop ; ok
: "= ( -- f ) ($ s1 s2 -- ) "compare 0= ;
: "< ( -- f ) ($ s1 s2 -- ) "compare 0< ;
: "<= ( -- f ) ($ s1 s2 -- ) "compare dup 0< swap 0= or ;
OK



\ string compiling layer ( not implemented here)
\ string defining words ( not done here )



\ stringstack I/O
: "TYPE ( -- ) ($ s -- s ) \ non destructive info of tos$. ok
     topcount$ type ; OK
: ". ( -- ) ($ s -- ) "pop type ; OK
\ : "AT ( col row -- ) ($ s -- ) at-xy ". ; OK
: "AT ( col row -- ) ($ s -- ) 2drop ". ; OK
: ".R ( len -- ) ($ s -- ) "R ". ; ok
: ".L ( len -- ) ($ s -- ) "L ". ; ok
: "EXPECT ( len -- ) ($ -- s ) ok
   "blanks topcount$ expect "pop drop span @ "push ;



\ string input special ( no)



\ string debugging toolbox
\ default (.s$)
defer (.s$)
\ : ".S ( -- ) ($ -- ) \ show strings on stringstack ok
\      depth$ 0= IF ." Empty$ " exit then
\      tos$ BEGIN depth$ while (.s$) REPEAT sp$ ! space ;
: ".S ( -- ) ($ -- ) \ show strings on stringstack ok
     depth$ 0= IF ." Empty$ " exit then
     tos$ BEGIN depth$ while REPEAT sp$ ! space ;
: "PRINTLINE ( ​​-- ) cr ". ; OK
  ' "printline is (.s$)

: ?$ ( addr -- ) ( $ s -- s ) \ check whats there ok
     count type ; OK
: "DUMP ( -- ) ($ s -- s ) \ dump top of stringstack ok
    top$ toplength$ 1+ dump ;

\ F83 trace not implemented

words cr cr



true [if] \ examples

s" one" "push
s" two" "push
s" three" "push
s" four" "push
".s.s


[then]

( finished)