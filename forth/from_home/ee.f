\ 0 value file.id
\ 0 value line.count
\ : get.file s" c:\tem\pforth\abcd.txt" r/o open-file 0= if to file.id 0sp true else 0sp false then ;
\ : good.file file.id 0= not ;
\ : read.line good.file if here line.count + fff file.id read-line 0= not if 0sp false else swap dup 0= not if line.cout + to line.count 0sp true else 0sp false then then then ;
\ : read.file good.file if here fff file.id read-file 0= if 0sp true else 0sp false then then ;
\ : close.file good.file if file.id close-file not else 0sp false then ;
\ : reset.file good.file if close.file 0 to file.id 0 to line.count 0sp true else 0sp false then ;
\ : do-it get.file read.file reset.file ;


: read.line file.id not0 if next.line fff file.id read-line not0 if 0sp false else swap dup not0 if line.count + to line.count 0sp true else 0sp false then then then ;