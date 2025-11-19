\ the quickest and dirtiest memory dump ive made
\ : qq cr dup 10 cells + swap do i dup c@ . 1+ 4 mod 0= if cr then loop ; 
\ or
\ : qq cr dup 10 cells + swap do i dup c@ 0 <# # #s #> type space 1+ 4 mod 0= if cr then loop ;
\ or
\ : qq cr 10 0 do dup . 8 0 do dup c@ 0 <# # #s #> type space 1+ loop cr loop drop ;
\ or
: dmpp cr cr 10 0 do dup 0 <# [char] : hold # #S [CHAR] 0 HOLD [CHAR] 0 HOLD #> type space 8 0 do dup c@ 0 <# # #s #> type space 1+ loop cr loop drop ;
