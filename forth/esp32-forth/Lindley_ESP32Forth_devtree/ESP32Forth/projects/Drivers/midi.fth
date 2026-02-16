\
\ Minimal MIDI Interface for ESP32Forth
\
\ NOTE: all MIDI functions are 0 based i.e. 0..127
\
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 05/09/2023
\

31250 constant MIDI_BAUD_RATE
$C00001C constant SERIAL_8N1

$80 constant NOTE_OFF_CMD
$90 constant NOTE_ON_CMD
$B0 constant CC_CMD
$C0 constant PC_CMD

\ Control Change messages
 1 constant CC_MODULATION
 5 constant CC_PORTAMENTO_TIME
 7 constant CC_VOLUME
65 constant CC_PORTAMENTO_ON_OFF
91 constant CC_REVERB
93 constant CC_CHORUS

Serial

\ Setup Serial 2 for MIDI output
: midiSetup
  MIDI_TX_PIN MIDI_RX_PIN SERIAL_8N1 MIDI_BAUD_RATE Serial2.begin
;

\ Send a NOTE ON message
: sendNoteOn { note vel chan -- }
\  ." NOTE ON - Note: " note str type ."  Vel: " vel str type ."  Chan: " chan str type cr 
  NOTE_ON_CMD chan or Serial2.write drop
  note                Serial2.write drop
  vel                 Serial2.write drop
;

\ Send a NOTE OFF message
: sendNoteOff { note vel chan -- }
\  ." NOTE OFF - Note: " note str type ."  Vel: " vel str type ."  Chan: " chan str type cr 
  NOTE_OFF_CMD chan or Serial2.write drop
  note                 Serial2.write drop
  vel                  Serial2.write drop
;

\ Send a CC change message
: sendControlChange { ccCode ccVal chan -- }
\  ." CC - Code: " ccCode str type ."  ccValue: " ccVal str type ."  Chan: " chan str type cr
  CC_CMD chan or Serial2.write drop
  ccCode         Serial2.write drop
  ccVal          Serial2.write drop
;

\ Send a program change message
: sendProgramChange { prog chan -- }
\  ." PC - Prog: " prog str type ."  Chan: " chan str type cr
  PC_CMD chan or Serial2.write drop
  prog           Serial2.write drop
;

Forth

\ MIDI note number to octave. Note: middle C NN 60 is C4
: midiNoteToOctave ( noteNum -- octave )
  12 / 1-
;

\ MIDI note number to note name
: midiNoteToName ( noteNum -- a n )
  12 mod
  case
    0 of s" C"  endof
    1 of s" C#" endof
    2 of s" D"  endof
    3 of s" D#" endof
    4 of s" E"  endof
    5 of s" F"  endof
    6 of s" F#" endof
    7 of s" G"  endof
    8 of s" G#" endof
    9 of s" A"  endof
   10 of s" A#" endof
   11 of s" B"  endof
  endcase
;

\ Define the MIDI voices string table

startStringTable MIDI_VOICES

\ Piano
 +" Acoustic Grand Piano" +" Bright Acoustic Piano" +" Electric Grand Piano"
 +" Honky-tonk Piano" +" Elec PIano 1" +" Elect Piano 2" +" Harpsichord"
 +" Clavi"

\ Chromatic Percussion
 +" Celesta" +" Glockenspiel" +" Music Box" +" Vibraphone" +" Marimba"
 +" Xylophone" +" Tubular Bells" +" Dulcimer"

\ Organ
 +" Drawbar Organ" +" Percussive Organ" +" Rock Organ" +" Church Organ"
 +" Reed Organ" +" Accordion" +" Harmonica" +" Tango Accordion"

\ Guitar
 +" Acoustic Guitar (nylon)" +" Acoustic Guitar (steel)" +" Electric Guitar (jazz)"
 +" Electric Guitar (clean)" +" Electric Guitar (muted)" +" Overdriven Guitar"
 +" Distortion Guitar" +" Guitar harmonics"

\ Bass
 +" Acoustic Bass" +" Electric Bass (finger)" +" Electric Bass (pick)"
 +" Fretless Bass" +" Slap Bass 1" +" Slap Bass 2"
 +" Synth Bass 1" +" Synth Bass 2"

\ Strings
 +" Violin" +" Viola" +" Cello" +" Contrabass" +" Tremolo Strings"
 +" Pizzicato Strings" +" Orchestral Harp" +" Timpani"

\ Ensemble
 +" String Ensemble 1" +" String Ensemble 2" +" SynthStrings 1" +" SynthStrings 2"
 +" Choir Aahs" +" Voice Oohs" +" Synth Voice" +" Orchestra Hit"

\ Brass
 +" Trumpet" +" Trombone" +" Tuba" +" Muted Trumpet" +" French Horn"
 +" Brass Section" +" SynthBrass 1" +" SynthBrass 2"

\ Reed
 +" Soprano Sax" +" Alto Sax" +" Tenor Sax" +" Baritone Sax"
 +" Oboe" +" English Horn" +" Bassoon" +" Clarinet"

\ Pipe
 +" Piccolo" +" Flute" +" Recorder" +" Pan Flute"
 +" Blown Bottle" +" Shakuhachi" +" Whistle" +" Ocarina"

\ Synth Lead
 +" Lead 1 (square)" +" Lead 2 (sawtooth)" +" Lead 3 (calliope)" +" Lead 4 (chiff)"
 +" Lead 5 (charang)" +" Lead 6 (voice)" +" Lead 7 (fifths)" +" Lead 8 (bass + lead)"

\ Synth Pad
  +" Pad 1 (new age)" +" Pad 2 (warm)" +" Pad 3 (polysynth)" +" Pad 4 (choir)"
  +" Pad 5 (bowed)" +" Pad 6 (metallic)" +" Pad 7 (halo)" +" Pad 8 (sweep)"

\ Synth Effects
  +" FX 1 (rain)" +" FX 2 (soundtrack)" +" FX 3 (crystal)" +" FX 4 (atmosphere)"
  +" FX 5 (brightness)" +" FX 6 (goblins)" +" FX 7 (echoes)" +" FX 8 (sci-fi)"

\ Ethnic
  +" Sitar" +" Banjo" +" Shamisen" +" Koto"
  +" Kalimba" +" Bag pipe" +" Fiddle" +" Shanai"

\ Percussive
  +" Tinkle Bell" +" Agogo" +" Steel Drums" +" Woodblock"
  +" Taiko Drum" +" Melodic Tom" +" Synth Drum" +" Reverse Cymbal"

\ Sound Effects
  +" Guitar Fret Noise" +" Breath Noise" +" Seashore" +" Bird Tweet"
  +" Telephone Ring" +" Helicopter" +" Applause" +" Gunshot"

endStringTable



 






