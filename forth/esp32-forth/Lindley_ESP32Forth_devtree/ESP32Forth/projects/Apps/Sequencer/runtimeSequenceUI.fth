\
\ Sequence Runtime UI Functions
\
\ UI shown when sequences are playing
\ Sequencer runtime display divided into 8x6 cells for positioning purposes
\ 
\ Concept, Design and Implementaton by: Craig A. Lindley
\ Last Update: 05/03/2023
\

\ ***************************************************************************
\ ***                           Runtime UI Functions                      ***
\ ***************************************************************************

\ Display Positioning Values - precalculated for screen size
14 constant HORIZ_SPACE
13 constant VERT_SPACE

\ Gate bar attributes
16 constant GATE_BAR_WIDTH
 4 constant GATE_BAR_HEIGHT

\ Calculate column start X positon from column number 0..7
: _rtColPos { col -- xPos }
  col 1+ HORIZ_SPACE * col FW * +
;

\ Calculate row start Y position from row number row 0..5
: _rtRowPos { row -- yPos )
  row 1+ VERT_SPACE * row FH * +
;

\ ***************************************************************************
\ ***                    Update individual parts of the UI                ***
\ ***************************************************************************
 
\ Update tempo
: rtTempoUpdate ( -- ) 

  \ Display tempo
  clearFormatBuffer
  s" BPM: " addString
  tempoBPM addNumber
  addSpace
  0 _rtColPos 5 _rtRowPos getFormatBufferString pString
;
  
\ Update transpose value
: rtTransposeUpdate ( -- )

  \ Display transpose value
  clearFormatBuffer
  s" Transp: " addString
  transpose addNumber
  addSpace
  4 _rtColPos 5 _rtRowPos getFormatBufferString pString
;

\ Update sequence number
: rtSequenceUpdate ( -- )

  \ Display sequence number
  clearFormatBuffer
  s" Seq: " addString
  sequence addNumber
  0 _rtColPos 4 _rtRowPos getFormatBufferString pString
;

\ ***************************************************************************
\ ***                         Update Runtime Display                      ***
\ ***************************************************************************

\ Update runtime (playing) display with current values
: displayRuntimeScreen ( -- )

  clearLCD
  
  \ Display step data
  NUM_OF_STEPS 0
  do
    \ ** Display gate value bar **
    \ Clear the step bar area
    i _rtColPos VERT_SPACE 
    GATE_BAR_WIDTH GATE_BAR_HEIGHT BLK fillRect2

    \ Get gate bar display location
    i _rtColPos VERT_SPACE

    \ Get gate value
    i sequence getGate 

    \ Display value
    GATE_BAR_WIDTH * 16 / 1+ GATE_BAR_HEIGHT WHT fillRect2

    \ ** Display note value **
    \ Get note display location
    i _rtColPos 1 _rtRowPos

    \ Get note value
    i sequence getNoteNumber 

    \ Display note
    midiNoteToName pString

    \ ** Display note octave value **
    \ Get octave display location
    i _rtColPos 2 _rtRowPos

    \ Get octave value
    i sequence getNoteNumber

    \ Display octave value
    midiNoteToOctave str pString

    \ ** Display step status **
    \ Get status display location
    i _rtColPos 3 _rtRowPos

    \ Get status value
    i sequence getOn

    \ Display status value
    if s" *" else s"  " then pString
  loop

  \ Display tempo data
  rtTempoUpdate

  \ Display transpose data
  rtTransposeUpdate

  \ Display sequence number
  rtSequenceUpdate
;


