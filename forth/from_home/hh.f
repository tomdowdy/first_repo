0 value file.id
0 value line.count
fff value num.bytes
: not0 0= not ;
: next.line here line.count + ;
: get.file s" c:\temp\pforth\abcd.txt" r/o open-file 0= if to file.id 0sp true else 0sp false then ;
: read.file file.id not0 if here num.bytes file.id read-file 0= if 0sp true else 0sp false then then ;
: read.line file.id not0 if next.line num.bytes file.id then ;
: close.file file.id 0= not if file.id close-file not else 0sp false then ;
: reset.file file.id 0= not if close.file 0 to file.id 0 to line.count 0sp true else 0sp false then ;
: do.it get.file read.file reset.file ;
: jjj file.id not0 if next.line num.bytes file.id then ;
: jjjg file.id not0 if next.line num.bytes file.id read-line then ;
