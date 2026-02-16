\
\ Remap an integer number from one range to another. From Arduino
: map { num inMin inMax outMin outMax } ( num inMin inMax outMin outMax -- newNum )
  num inMin - outMax outMin - * inMax inMin - / outMin +
;

