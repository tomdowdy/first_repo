
67 constant MIDI_INPUT_LINE

: displayMIDIVoiceScreen ( -- )
  clearLCD
  10 s" 8-Step MIDI Sequencer"   pCenteredString
  40 s" Assigned"                pCenteredString
  54 s" -- MIDI Voice --"        pCenteredString
  MIDI_INPUT_LINE s" Acoustic Guitar (nylon)" pCenteredString
;

\ Display data in MIDI input field
: displayMIDIInputString ( a n -- ) 
 
  \ First clear line on screen
  MIDI_INPUT_LINE s"                        " pCenteredString

  \ Display new string
  MIDI_INPUT_LINE -rot pCenteredString
;

