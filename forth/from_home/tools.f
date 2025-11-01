
: times 0 do dup >r  execute r> loop drop ;
: cp cs page ;
: dcount here last-dp @ - cell / ;
variable last-dp
variable init-dp
here last-dp !
here init-dp !

