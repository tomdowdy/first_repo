\
\ Sequence Data Storage and Access Functions
\
\ There are 8 total sequences available in the Sequencer
\ Each sequence consists of 8 steps and
\ each step is comprised of 4 (32 bit) values:
\ noteNumber, velocity, gate and muted.
\
\ Concept, Design and Implementaton by: Craig A. Lindley
\ Last Update: 05/12/2023
\

\ Given an address of a Step the following offsets can be used to
\ access its various fields
 0 constant NOTE_OFFSET
 4 constant VELOCITY_OFFSET
 8 constant GATE_OFFSET
12 constant ON_OFFSET

\ Sequence/Step storage parameters
4 cells constant STEP_SIZE
8 constant NUM_OF_STEPS
8 constant NUM_OF_SEQUENCES

NUM_OF_STEPS STEP_SIZE * constant SEQUENCE_SIZE

\ From the above, calculate storage requiremets
SEQUENCE_SIZE NUM_OF_SEQUENCES * constant SEQUENCE_STORAGE_SIZE

\ Allocate storage for the sequence/step data
create SEQUENCE_STORAGE SEQUENCE_STORAGE_SIZE allot


\ Calculate step offset
\ seqNum 0..7, stepNum 0..7
: calcStepOffset ( stepNum seqNum -- stepOffset )
  SEQUENCE_SIZE * swap STEP_SIZE * +
;

\ Get a note number from specified sequence and step
\ seqNum 0..7, stepNum 0..7
: getNoteNumber ( stepNum seqNum -- noteNumber )
  calcStepOffset SEQUENCE_STORAGE + @
;

\ Set note number
: setNoteNumber ( stepNum seqNum noteNumber -- )
  >r calcStepOffset SEQUENCE_STORAGE + r> swap !
;

\ Get a velocity from specified sequence and step
\ seqNum 0..7, stepNum 0..7
: getVelocity ( stepNum seqNum -- velocity )
  calcStepOffset SEQUENCE_STORAGE + VELOCITY_OFFSET + @
;

\ Set velocity value
: setVelocity ( stepNum seqNum velocity -- )
  >r calcStepOffset SEQUENCE_STORAGE + VELOCITY_OFFSET + r> swap !
;

\ Get gate value from specified sequence and step
\ seqNum 0..7, stepNum 0..7
: getGate ( stepNum seqNum -- gate )
  calcStepOffset SEQUENCE_STORAGE + GATE_OFFSET + @
;

\ Set gate value
: setGate ( stepNum seqNum gate -- )
  >r calcStepOffset SEQUENCE_STORAGE + GATE_OFFSET + r> swap !
;

\ Get on value from specified sequence and step
\ seqNum 0..7, stepNum 0..7
: getOn ( stepNum seqNum -- on )
  calcStepOffset SEQUENCE_STORAGE + ON_OFFSET + @
;

\ Set on value
: setOn ( stepNum seqNum on -- )
  >r calcStepOffset SEQUENCE_STORAGE + ON_OFFSET + r> swap !
;

\ Save all sequence data
: saveSequences ( -- f )

  cr ." Saving sequences" cr

  0 true { fid result }
  
  \ Attempt to open SPIFFS file for writing
  s" /spiffs/SSFile.dat" w/o create-file 0=
  if
    \ File opened successfully
    to fid
 
    \ Attempt to write the sequence data
    SEQUENCE_STORAGE SEQUENCE_STORAGE_SIZE fid write-file 0=
    if 
      drop
    else
      ." File write failed" cr
      false to result
    then
    fid close-file drop
  else
    ." File open failed" cr
    false to result
  then
  result
;

\ Load all sequence data
: loadSequences ( -- f)

  cr ." Loading sequences" cr

  0 true { fid result }
  
  \ Attempt to open SPIFFS file for reading
  s" /spiffs/SSFile.dat" r/o open-file 0=
  if
    \ File opened successfully
    to fid
 
    \ Attempt to read the sequence data
    SEQUENCE_STORAGE SEQUENCE_STORAGE_SIZE fid read-file 0=
    if 
      drop
    else
      ." File read failed" cr
      false to result
    then
    fid close-file drop
  else
    ." File open failed" cr
    false to result
  then
  result
;

\ Clear sequence data storage
: clearSequenceData ( -- )
  SEQUENCE_STORAGE SEQUENCE_STORAGE_SIZE erase
;

\ Fill sequence data storage with reasonable data
: fillSequenceData ( -- )

  \ How about some Pink Floyd
  0 0 47 setNoteNumber
  0 0 64 setVelocity
  0 0  9 setGate
  0 0 true setOn

  1 0 59 setNoteNumber
  1 0 64 setVelocity
  1 0  7 setGate
  1 0 true setOn

  2 0 54 setNoteNumber
  2 0 64 setVelocity
  2 0  4 setGate
  2 0 true setOn

  3 0 47 setNoteNumber
  3 0 64 setVelocity
  3 0  9 setGate
  3 0 true setOn

  4 0 42 setNoteNumber
  4 0 64 setVelocity
  4 0  9 setGate
  4 0 true setOn

  5 0 45 setNoteNumber
  5 0 64 setVelocity
  5 0  9 setGate
  5 0 true setOn

  6 0 47 setNoteNumber
  6 0 64 setVelocity
  6 0  9 setGate
  6 0 true setOn

  7 0 50 setNoteNumber
  7 0 64 setVelocity
  7 0  9 setGate
  7 0 true setOn

  9 { g }
  NUM_OF_SEQUENCES 1
  do
    NUM_OF_STEPS 0  
    do
      i j i 2 mod 0= if 60 else 65 then setNoteNumber

      i j 64 setVelocity

      i j g setGate

      i j false setOn
    loop
  loop
;

\ Test Code
\ : fillData
\
\  1 { val }
\  clearSequenceData
\
\  NUM_OF_SEQUENCES 0
\  do
\    NUM_OF_STEPS 0 
\    do
\      i j val setNoteNumber
\      1 +to val
\
\      i j val setVelocity
\      1 +to val
\
\     i j val setGate
\     1 +to val
\
\      i j val setOn
\      1 +to val
\ 
\    loop
\  loop
\  SEQUENCE_STORAGE SEQUENCE_STORAGE_SIZE dump 
\ ;







