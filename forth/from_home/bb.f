c" -start" find swap drop 0=
[if]
s" marker -start" evaluate
\ : restart -start c" c:\temp\bb.f" included ;
[then]
: nn >name count type ;
\ : recall us@ ;
: imm? ' >name find -1 = if ." Not immediate." else ." Immediate." then ;
\ here >us
8 cells allocate drop value my.var
: ww [ here ] literal 44 cells dump ;
0 value dic.top
here to dic.top
hex
