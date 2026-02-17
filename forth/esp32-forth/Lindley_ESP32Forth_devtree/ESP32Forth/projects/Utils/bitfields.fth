marker _bf_

\ Bit Field Words

\ Calculate how many bytes required to hold numBits
: calcBFBytes { numBits | tmp -- numBytes }
  numBits 8 / -> tmp
  numBits 8 mod 0<>
  if 1 +-> tmp then
  tmp
;

\ Print the binary bits in an 8 bit byte
: .8bits { byte -- }
  8 0
  do
    1 7 i - << byte and 0<>
    if  ." 1" else ." 0" then
  loop
;

\ Show all bits in bit field
: showBitField                { bfaddr -- } 
  cr
  bfaddr w@                          ( -- numBits )
  dup                        ( numBits -- numBits numBits)
  ." NumBits: " . cr ( numBits numBits -- numBits )
  calcBFBytes  0
  do
    i bfaddr 2+ + c@ .8bits cr
  loop
  cr
;

\ Clear all bits to zeros
: clearAll            ( bfaddr -- )
  dup                 ( bfaddr -- bfaddr bfaddr )
  w@           ( bfaddr bfaddr -- bfaddr numBits )
  calcBFBytes ( bfaddr numBits -- bfaddr bytes )
  swap 2+ swap erase
;

: _createBitField { numBits | addr -- bfaddr }
  \ Calc size in bytes of bit field + 2 for numBits
  numBits calcBFBytes 2+

  \ Save start address of bit field in dictionary
  here -> addr

  \ Allot calculated number of bytes
  allot

  \ Store number of bits 
  numBits addr w!

  \ Return bit field attributes
  addr
;

\ Create a bit field for specified number of bits
: createBitField          ( numBits -- bfaddr )
  _createBitField         ( numBits -- bfaddr )
  dup                      ( bfaddr -- bfaddr bfaddr )
  clearAll          ( bfaddr bfaddr -- bfaddr )
;

\ Clear a specifed bit in a bit field
: clearBit { bfaddr bitNum | addr bits -- }
  bfaddr w@ -> bits
  bitNum 0<  bitNum bits >= or
  if cr ." clearBit parameter out of range" cr exit then

  \ Calculate which byte of bit field specified bit is in
  bitNum 8 / bfaddr + 2+ -> addr
  
  \ Get byte at address 
  addr c@ 
  1 bitNum 8 mod << not and
  addr c! 
;

\ Set a specifed bit in a bit field
: setBit { bfaddr bitNum | addr bits -- }
  bfaddr w@ -> bits
  bitNum 0<  bitNum bits >= or
  if cr ." setBits parameter out of range" cr exit then

  \ Calculate which byte of bit field specified bit is in
  bitNum 8 / bfaddr 2+ + -> addr
  
  \ Get byte at address 
  addr c@ 
  1 bitNum 8 mod << or
  addr c! 
;

\ Test if a bit in a bit field is set or not
: bitSet? { bfaddr bitNum | addr bits -- f }
  bfaddr w@ -> bits
  bitNum 0<  bitNum bits >= or
  if cr ." setBits parameter out of range" cr exit then

  \ Calculate which byte of bit field specified bit is in
  bitNum 8 / bfaddr 2+ + -> addr
  
  \ Get byte at address 
  addr c@ 
  1 bitNum 8 mod << and
;

\ Various tests

: bfTest  { | bfAddr -- }
 
 36 createBitField -> bfAddr

 bfAddr showBitField
 bfAddr 23 bitSet? if ." bit set" else ." bit clear" then cr
 bfAddr 23 setBit
 bfAddr showBitField
 bfAddr 23 bitSet? if ." bit set" else ." bit clear" then cr
 bfAddr 23 clearBit
 bfAddr showBitField
 bfAddr 23 bitSet? if ." bit set" else ." bit clear" then cr
 bfAddr showBitField
 bfAddr 37 clearBit
 bfAddr 0 setBit
 bfAddr 1 setBit
 bfAddr 7 setBit
 bfAddr 14 setBit
 bfAddr 30 setBit
 bfAddr 32 setBit
 bfAddr 35 setBit
 bfAddr 20 setBit
 bfAddr showBitField
 bfAddr clearAll
 bfAddr showBitField
;









