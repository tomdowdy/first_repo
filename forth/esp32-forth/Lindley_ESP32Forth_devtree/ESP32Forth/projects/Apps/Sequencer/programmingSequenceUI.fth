\
\ Sequence Programming UI Functions
\
\ 
\ Concept, Design and Implementaton by: Craig A. Lindley
\ Last Update: 05/12/2023
\

\ ***************************************************************************
\ ***              Update individual parts of the Programming UI          ***
\ ***************************************************************************
 
\ Display string centered on line 0..15
: displayString ( line a n -- ) 

  \ Calculate display row
  rot charSpaceHeight * { row } 
 
  \ First clear line on screen
  row s"                        " pCenteredString

  \ Display new string
  row -rot pCenteredString
;

\ Update sequence
: pgSequenceUpdate ( -- )
  clearFormatBuffer
  sequence addNumber
  4 getFormatBufferString displayString
;

\ Update step
: pgStepUpdate ( -- )
  clearFormatBuffer
  step addNumber
  6 getFormatBufferString displayString
;

\ Update noteletter:notenumber
: pgNoteUpdate ( -- )
  clearFormatBuffer
  midiNote midiNoteToName addString
  $3A addChar
  midiNote addNumber
  8 getFormatBufferString displayString
;

\ Update note octave
: pgNoteOctaveUpdate ( -- )
  clearFormatBuffer
  midiNote midiNoteToOctave addNumber
  10 getFormatBufferString displayString
;

\ Update note gate
: pgNoteGateUpdate ( -- )
  clearFormatBuffer
  noteGate addNumber
  12 getFormatBufferString displayString
;

\ Update note status - playing or muted
: pgNoteStatusUpdate ( -- )
  clearFormatBuffer
  noteStatus
  if 
    s" On"
  else
    s" Off"
  then
  addString
  14 getFormatBufferString displayString
;

\ Update MIDI channel
: pgMIDIChannelUpdate ( -- )
  clearFormatBuffer
  midiChannel 1+ addNumber
  4 getFormatBufferString displayString
;

\ Update MIDI voice
: pgMIDIVoiceUpdate ( -- )
  clearFormatBuffer
  midiVoice MIDI_VOICES addString
  6 getFormatBufferString displayString
;

\ Update MIDI modulation
: pgMIDIModulationUpdate ( -- )
  clearFormatBuffer
  midiModulation addNumber
  8 getFormatBufferString displayString
;

\ Update MIDI reverb
: pgMIDIReverbUpdate ( -- )
  clearFormatBuffer
  midiReverb addNumber
  10 getFormatBufferString displayString
;

\ Update MIDI chorus
: pgMIDIChorusUpdate ( -- )
  clearFormatBuffer
  midiChorus addNumber
  12 getFormatBufferString displayString
;

\ Update MIDI portamento
: pgMIDIPortamentoUpdate ( -- )
  clearFormatBuffer
  midiPortamento addNumber
  14 getFormatBufferString displayString
;

\ ***************************************************************************
\ ***                           Misc Display Screens                      ***
\ ***************************************************************************

5000 constant CREDIT_SCREEN_DELAY_MS

\ Credits screen
: displayCreditsScreen ( -- )
  \ Format version string
  clearFormatBuffer
  s" Version: " addString
  MAJOR_VERSION_NUMBER addNumber
  $2E addChar
  MINOR_VERSION_NUMBER addNumber

  clearLCD

  0 s" Craig Lindley's"       displayString
  2 s" ESP32Forth"            displayString
  4 s" 8-Step MIDI Sequencer" displayString
  6 getFormatBufferString     displayString
  8 s" -- Info At --"         displayString
  10 s" calhjh@gmail.com"     displayString

  CREDIT_SCREEN_DELAY_MS delay
  clearLCD
;

\ Display programming screen
: displayProgrammingScreen ( -- )
  clearLCD

  0 s" ESP32Forth Sequencer" displayString
  1 s" Sequence Programming" displayString
  3 s" Sequence Number"      displayString
  5 s" Step Number"          displayString
  7 s" Note"                 displayString
  9 s" Octave"               displayString
  11 s" Gate"                displayString
  13 s" Sound"               displayString

  \ Now populate the screen with data
  pgSequenceUpdate
  pgStepUpdate
  pgNoteUpdate
  pgNoteOctaveUpdate
  pgNoteGateUpdate
  pgNoteStatusUpdate
;

\ Display MIDI configuration screen
: displayMIDIConfigScreen ( -- )
  clearLCD

  0 s" ESP32Forth Sequencer" displayString
  1 s" MIDI Configuration"   displayString
  3 s" SB0-MIDI Channel"     displayString
  5 s" SB1-MIDI Voice"       displayString
  7 s" SB2-Modulation"       displayString
  9 s" SB3-Reverb"           displayString
 11 s" SB4-Chorus"           displayString
 13 s" SB5-Portamento"       displayString

  \ Now populate the screen with data
  pgMIDIChannelUpdate
  pgMIDIVoiceUpdate
  pgMIDIModulationUpdate
  pgMIDIReverbUpdate
  pgMIDIChorusUpdate
  pgMIDIPortamentoUpdate
;

