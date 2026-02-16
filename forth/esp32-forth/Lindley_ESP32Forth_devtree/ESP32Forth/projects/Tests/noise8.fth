: qadd8 ( i j -- sum )
  +     ( i j -- sum )
  255   ( sum -- sum 255 ) 
  over  ( sum 255 -- sum 255 sum )
  <     ( sum 255 sum -- sum f )
  if    ( sum f -- sum )
    drop 255 ( sum -- 255 )
  else

  then
;

\ fract8 should be interpreted as fixed point unsigned 256ths.
\ Example: if a fract8 has the value "64", that should be interpreted
\          as 64/256ths, or one-quarter.
\
\  fract8 range is 0 to 0.99609375 in steps of 0.00390625

\  Scale one byte by a second one, which is treated as
\ the numerator of a fraction whose denominator is 256
\ In other words, it computes i * (scale / 256)

: scale8 ( i fract8 -- result )
  1+ * 8 >>
;

