\ New noname method
\ Usage: noname: stuff noname;
\ To execute the new headless word, do 'noname'
\ XT for new headless word is stored in active.noname
\ noname- deletes word
\ 0 in active.noname means no headless word is defined

0 value active.noname
: noname: active.noname , :noname ;
: noname; postpone ; dup to active.noname ; immediate
: noname active.noname execute ;
: noname- active.noname >code here - allot 0 to active.noname ;
