create ss 40 allot
create gg 40 allot

s" the one thing above" ss swap cmove
s" one" gg swap cmove


: a1 here cell - ;
: cmpr ( addr1 n addr m -- flag )
    tmp.bac 
    , , , ,
    2 ,npic ]tmpa
    begin
        
    until
    4 ,ndrop
    tmp.rstr ;
