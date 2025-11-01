re.set

\ this is a simple text file processor experiment.
\ initially demonstrated a file parser that replaced certain
\ items with others.
\ initialize

: srcfile   s" c:\temp\mytext.txt" ;

\ define input buffer
variable src.start
variable src.finish

variable fh \ file handler id

: open      srcfile r/o open-file throw fh ! ;
: close     fh @ close-file throw ;
: read      begin here 4096 fh @ read-file throw dup allot 0= until ;
: gulp      open read close ;
: start     here src.start ! ;
: finish    here src.start @ - src.finish ! ; \ this is really the character count
: slurp     start gulp finish ;

\ process buffer
variable off.set
\ : entity [char] - emit type [char] ; emit ;
: entity s" --this was a tilde--" ;
\ : int.pret dup [char] ~ = if drop s" --this was a tilde--" type exit then
\      emit ;
(
: int.pret  dup [char] ~ = if drop s" --tilde---" type else emit then
            dup [char] < = if drop s" ---lt---" type else emit then
            dup [char] > = if drop s" ---gt---" type else emit then ;
)

: int.pret
      case
            [char] ~ of s" ---tilde---" type endof
            [char] < of s" ---lt---" type endof
            [char] > of s" ---gt---" type endof
            \ the following is the default action
            dup emit \ dup duplicates the incoming argument to int.pret since endcase will use it
      endcase ;

: pro.cess cr
      \ initialize off.set
      0 off.set !
      \ process text
      begin off.set @ src.finish @ u<
      while src.start @ off.set @ + c@ int.pret 1 off.set +!
      repeat
      cr ;

: view.buffer src.start @ src.finish @ type ;

slurp
