\
\ Tone words using ESP32 LEDC Interface
\

\ Use GPIO25 as tone output pin
25 constant DEFAULT_OUTPUT_PIN

\ Default PWM channel 0-15
0 constant DEFAULT_CHANNEL

\ Default PWM freqency
5000 constant DEFAULT_PWM_FREQ

\ Default bit resolution 1-16
8 constant DEFAULT_RESOLUTION

\ Note Definitions
 0 constant NOTE_C
 1 constant NOTE_CS
 2 constant NOTE_D
 3 constant NOTE_Eb
 4 constant NOTE_E
 5 constant NOTE_F
 6 constant NOTE_FS
 7 constant NOTE_G
 8 constant NOTE_Ab
 9 constant NOTE_A
10 constant NOTE_Bb
11 constant NOTE_B

0 value _toneEndTimeMS

LEDC

: toneDefaultSetup ( -- )
  DEFAULT_CHANNEL DEFAULT_PWM_FREQ DEFAULT_RESOLUTION ledcSetup drop
  DEFAULT_OUTPUT_PIN DEFAULT_CHANNEL ledcAttachPin
;

\ Changing dutycycle to 0 halts tone production
: toneOff ( -- )
  DEFAULT_CHANNEL 0 ledcWrite
;
  
\ Play a note
: playNote ( note octave -- )
  DEFAULT_CHANNEL -rot ledcWriteNote drop
;

\ Play a note with a duration
: playNoteWithDuration ( note octave toneDurationMS -- )
  MS-TICKS + to _toneEndTimeMS
  playNote
;

\ Play a tone
: playTone ( freq -- )
  DEFAULT_CHANNEL swap 1000 * ledcWriteTone drop
;

\ Play a tone with a duration
: playToneWithDuration ( freq toneDurationMS -- )
  MS-TICKS + to _toneEndTimeMS
  playTone
;


\ This should be called every loop
: toneUpdate ( -- )
  MS-TICKS _toneEndTimeMS >
  if
    toneOff
  then
;

FORTH
