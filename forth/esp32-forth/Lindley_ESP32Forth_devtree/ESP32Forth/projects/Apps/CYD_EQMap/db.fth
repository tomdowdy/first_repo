\ Earthquake Event Database 
\ Written for ESP32forth
\ Written by: Craig A. Lindley
\ Last Update: 11/18/2023

60 constant MAX_RECORDS
30 constant STR_LEN

0 value numberOfRecords

\ Record Structure
struct:
     cell field: scnX
     cell field: scnY
     cell field: mag
constant RECORD_SIZE

\ Function to create an array of records of given size and number
\ Array cleared to zeros
: allotRecordArray ( recSize numRecs -- ) ( i -- addr )
  create 2dup swap c, drop * dup 1+ here swap 0 fill allot does> dup c@ rot * + 1+
;

\ Create the database records array
RECORD_SIZE MAX_RECORDS allotRecordArray records

\ Functions for retrieving values from records
\ Get scnX value from specified record
: getScnX ( recNum -- scnX ) records scnX @ ;

\ Get scnY value from specified record
: getScnY ( recNum -- scnY ) records scnY @ ;

\ Get mag value from specified record
: getMag ( recNum -- mag ) records mag @ ;

\ Function for moving records in preparation for adding new record
: moveRecords ( -- )
  \ No movement needed if this is first record added
  numberOfRecords 0 <>
  if
    0 records 1 records numberOfRecords RECORD_SIZE * cmove>
  then
;

\ Create a new db record with event data
: addNewRecord ( scnX scnY mag -- )

  \ Only add records if there is room
  numberOfRecords MAX_RECORDS <
  if
    \ Move records so new record can be added
    moveRecords
  
    0 records mag  !
    0 records scnY !
    0 records scnX !

    numberOfRecords MAX_RECORDS 2 - <
    if 
      1 +to numberOfRecords
    then
  then
;

\ Display all records - only for testing purposes
: displayRecords ( -- )
  cr
  numberOfRecords 0
  do
    i ." Record: " . i getScnX ."  ScnX: " . i getScnY ."  ScnY: " .
    i getMag ."  Mag: " .
    cr
  loop
;




