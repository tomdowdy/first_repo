\ Event Database

FIXED_PT

30 constant MAX_RECORDS
30 constant STR_LEN

0 value numberOfRecords

: struct: 0 ;

: field:
  create over , +
  does> @ + ;

\ Test Structure
struct:
     cell field: scnX
     cell field: scnY
     cell field: fpMag
  STR_LEN field: loc
constant RECORD_SIZE

: clearLoc ( addr -- )
  STR_LEN erase
;

\ Create an array of records of given size and number
\ Array cleared to zeros
: allotRecordArray ( recSize numRecs -- ) ( i -- addr )
  create 2dup swap c, drop * dup 1+ here swap 0 fill allot does> dup c@ rot * + 1+
;

RECORD_SIZE MAX_RECORDS allotRecordArray records

\ Functions for retrieving values from records
\ Get scnX value from specified record
: getScnX ( recNum -- scnX ) records scnX @ ;

\ Get scnY value from specified record
: getScnY ( recNum -- scnY ) records scnY @ ;

\ Get fpMag value from specified record
: getFPMag ( recNum -- fpMag ) records fpMag @ ;

\ Get loc string from specified record
: getLoc ( recNum -- addr n )
  records loc z>s
;

\ Function for moving records in preparation for adding new record
: moveRecords ( -- )
  \ No movement needed if this is first record added
  numberOfRecords 0 <>
  if
    0 records 1 records numberOfRecords RECORD_SIZE * cmove>
  then
;

\ Values are only set directly in record 0
: addNewRecord ( scnX scnY fpMag locAddr locN -- )
  \ Move records so new record can be added
  moveRecords
  
  0 records loc -rot s>z z"cpy
  0 records fpMag !
  0 records scnY !
  0 records scnX !

  1 +to numberOfRecords
;

\ Display all records - only for testing purposes
: displayRecords ( -- )
  cr
  numberOfRecords 0
  do
    i ." Record: " . i getScnX ."  ScnX: " . i getScnY ."  ScnY: " .
    i getFPMag ."  Mag: " 2 FP.toS" type i getLoc ."  Loc: " type
    cr
  loop
;




