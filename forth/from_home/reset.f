: re.set    s" ---marker--- marker ---marker--- " evaluate ;

: edit.dd.notepad   s" notepad 'c:\temp\dd.f'" system ;
: edit.dd   s" atom.cmd 'c:\temp\dd.f'" system ;
: run       s" c:\temp\dd.f" required ;   \ required is same as included but checks if already loaded.
                                          \ including/requiring the file runs the contents.
\ : run- s" c:\temp\dd.f" include ;

marker ---marker---
