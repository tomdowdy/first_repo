\
\ ESP32Forth Sequencer Program
\
\ Operation
\
\ While Playing the actions are:
\   * To enter Programming mode, long click the RotaryEncoder.
\   * To transpose sequence, turn rotaryEncoder.
\   * To change tempo, single click the RotaryEncoder and turn.
\     Single click RotaryEncoder again when done
\   * To load a new sequence click a step key 1..8
\
\ When Programming the actions are:
\   * To return to Playing mode, long click the RotaryEncoder.
\   * To change step pitch, single click a step button and turn RotaryEncoder.
\     Single click step button when done
\   * To change step gate, double click step button and turn RotaryEncoder.
\     Single click step button when done
\   * To change step status, long click step button and turn RotaryEncoder.
\     Single click step button when done
\   * To configure MIDI, single click the RotaryEncoder. This will bring
\     up the MIDI configuration screen.
\
\ MIDI configuration actions are:
\   * To return to programming mode, single click the RotaryEncoder
\   * To change MIDI channel, single click Step 0 button and turn RotaryEncoder.
\     Single click Step 0 button again when done
\   * To change MIDI voice, single click Step 1 button and turn RotaryEncoder.
\     Single click Step 1 button when done
\   * To change MIDI modulation, single click Step 2 button and turn RotaryEncoder.
\     Single click Step 2 button when done
\   * To change MIDI reverb, single click Step 3 button and turn RotaryEncoder.
\     Single click Step 3 button when done
\   * To change MIDI chorus, single click Step 4 button and turn RotaryEncoder.
\     Single click Step 4 button when done
\   * To change MIDI portamento, single click Step 5 button and turn RotaryEncoder.
\     Single click Step 5 button when done
\
\ On startup, sequences are loaded into memory
\ On transition from Programming mode to Playing mode, all sequences are saved
\
\ Original concept by: Tod Kurt. See https://github.com/todbot/picostepseq
\ I used his hardware concept (loosely) but not his software. 
\ This sequencer was written completely in ESP32Forth. This includes the SPI display
\ driver, the MIDI interface and all required utility functions.
\
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 05/12/2023
\

\ ***************************************************************************
\ ***                        Constants and Variables                      ***
\ ***************************************************************************

1 constant STEPS_PER_BEAT

\ Instantiate 8 buttons numbered 0..7
newMCBInstance button0
newMCBInstance button1
newMCBInstance button2
newMCBInstance button3
newMCBInstance button4
newMCBInstance button5
newMCBInstance button6
newMCBInstance button7

\ Create an array of the buttons
button7 button6 button5 button4 
button3 button2 button1 button0
8 initializedArray BUTTON_ARRAY

\ Instantiate the rotary encoder button
newMCBInstance buttonRE

\ Step timing values
0 value stepMillis
0 value noteEndMillis

\ Current state of FSM
0 value fsmState

\ Valid FSM states
0 constant STATE_DISPATCH_MODE
1 constant STATE_MODE_PLAYING
2 constant STATE_MODE_PROGRAMMING
3 constant STATE_TEMPO_CHANGE

\ ***************************************************************************
\ ***                               Functions                             ***
\ ***************************************************************************

ledc

\ Configure the sequencer's hardware
: hardwareSetup ( -- )

  \ Step Button inputs
  B0_PIN INPUT_PULLUP pinMode
  B1_PIN INPUT_PULLUP pinMode
  B2_PIN INPUT_PULLUP pinMode
  B3_PIN INPUT_PULLUP pinMode
  B4_PIN INPUT_PULLUP pinMode
  B5_PIN INPUT_PULLUP pinMode
  B6_PIN INPUT_PULLUP pinMode
  B7_PIN INPUT_PULLUP pinMode

  \ Rotary encoder inputs
  RE_SW_PIN INPUT_PULLUP pinMode

  \ These are commented out here because the rotary encoder
  \ code initializes them.
  \ RE_PLUS_PIN  INPUT_PULLUP pinMode
  \ RE_MINUS_PIN INPUT_PULLUP pinMode

  \ MIDI output pin
  MIDI_TX_PIN OUTPUT pinMode

  \ LCD outputs
  LCD_MOSI_PIN OUTPUT pinMode
  LCD_SCLK_PIN OUTPUT pinMode
  LCD_DC_PIN   OUTPUT pinMode

  \ LCD DC pin driven high
  LCD_DC_PIN HIGH digitalWrite

  \ Setup ledc channel for PWM control of switch LEDs
  0 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  1 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  2 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  3 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  4 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  5 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  6 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop
  7 PWM_FREQUENCY PWM_RESOLUTION ledcSetup drop

  \ Assigned GPIO pins to ledc channels
  B0LED_PIN 0 ledcAttachPin
  B1LED_PIN 1 ledcAttachPin
  B2LED_PIN 2 ledcAttachPin
  B3LED_PIN 3 ledcAttachPin
  B4LED_PIN 4 ledcAttachPin
  B5LED_PIN 5 ledcAttachPin
  B6LED_PIN 6 ledcAttachPin
  B7LED_PIN 7 ledcAttachPin

  \ Initialize all multi click button instances
  B0_PIN button0 initMCBInstance
  B1_PIN button1 initMCBInstance
  B2_PIN button2 initMCBInstance
  B3_PIN button3 initMCBInstance
  B4_PIN button4 initMCBInstance
  B5_PIN button5 initMCBInstance
  B6_PIN button6 initMCBInstance
  B7_PIN button7 initMCBInstance
  RE_SW_PIN buttonRE initMCBInstance

  \ Initialize rotary encoder
  RE_PLUS_PIN RE_MINUS_PIN initRE
;

\ Button LED control function
: ledControl ( buttonNum state -- )
  ledcWrite
;

\ Button LEDs off
: ledsOff ( -- )
  8 0
  do
    i LED_OFF ledcWrite
  loop
;

\ Compute milliseconds per step from tempo in beats per minute
\ Beats are quarter notes, 120bpm = 120 quarter notes per min
: computeMillisPerStep ( tempoBPM -- )
  60000 STEPS_PER_BEAT / swap / to stepMillis
;

\ Set sequencer tempo in beats per minute
: setTempo ( tempoBPM -- )
  dup
  to tempoBPM
  computeMillisPerStep
  rtTempoUpdate
;

\ Select new sequence
: newSequence ( seq -- )
  to sequence 
  pgSequenceUpdate
  \ Turn current note off
  midiNote 0 midiChannel sendNoteOff
  STATE_DISPATCH_MODE to fsmState
;

\ ***************************************************************************
\ ***                        Programming Functions                        ***
\ ***************************************************************************

\ Set step note
: setStepNote { _step -- }
  _step LED_ON ledControl
  _step sequence getNoteNumber to midiNote
  pgNoteUpdate
  pgNoteOctaveUpdate
  midiNote setEncoderValue
  begin
    \ Update step button state
    _step BUTTON_ARRAY updateMCBButtonInstance
    \ Read rotary encoder
    1 0 127 readEncoder
    if
      \ Encoder changed
      midiNote 64 midiChannel sendNoteOff
      getEncoderValue to midiNote
      midiNote 64 midiChannel sendNoteOn
      pgNoteUpdate
      pgNoteOctaveUpdate
    then
    1 delay
    _step BUTTON_ARRAY isSingleClick
  until
  \ Save new note
  _step sequence midiNote setNoteNumber
  midiNote 64 midiChannel sendNoteOff
  _step LED_OFF ledControl
;

\ Set step note gate
: setStepNoteGate { _step -- }
  _step LED_ON ledControl
  _step sequence getGate to noteGate
  pgNoteGateUpdate
  noteGate setEncoderValue
  begin
    \ Update step button state
    _step BUTTON_ARRAY updateMCBButtonInstance
    \ Read rotary encoder
    1 1 15 readEncoder
    if
      \ Encoder changed
      getEncoderValue to noteGate
      pgNoteGateUpdate
    then
    1 delay
    _step BUTTON_ARRAY isSingleClick
  until
  \ Save new note gate
  _step sequence noteGate setGate
  _step LED_OFF ledControl
;

\ Set step note status
: setStepNoteStatus { _step -- }
  _step LED_ON ledControl
  _step sequence getOn to noteStatus
  pgNoteStatusUpdate
  noteStatus setEncoderValue
  begin
    \ Update step button state
    _step BUTTON_ARRAY updateMCBButtonInstance
    \ Read rotary encoder
    1 0 1 readEncoder
    if
      \ Encoder changed
      getEncoderValue to noteStatus
      pgNoteStatusUpdate
    then
    1 delay
    _step BUTTON_ARRAY isSingleClick
  until
  \ Save new note status
  _step sequence noteStatus setOn
  _step LED_OFF ledControl
;

\ ***************************************************************************
\ ***                       MIDI Configuration Functions                  ***
\ ***************************************************************************

\ Set MIDI channel
: setMIDIChannel ( -- )
  0 LED_ON ledControl
  midiChannel setEncoderValue
  begin
    \ Update button 0 state
    button0 updateMCBButtonInstance
    1 0 15 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiChannel
      pgMIDIChannelUpdate
    then
    1 delay
    button0 isSingleClick
  until
  0 LED_OFF ledControl
;

\ Set MIDI voice
: setMIDIVoice ( -- )
  1 LED_ON ledControl
  midiVoice setEncoderValue
  begin
    \ Update button 1 state
    button1 updateMCBButtonInstance
    1 0 127 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiVoice
      pgMIDIVoiceUpdate
    then
    1 delay
    button1 isSingleClick
  until
  midiVoice midiChannel sendProgramChange
  1 LED_OFF ledControl
;

\ Set MIDI modulation
: setMIDIModulation ( -- )
  2 LED_ON ledControl
  midiModulation setEncoderValue
  begin
    \ Update step button 2 state
    button2 updateMCBButtonInstance
    8 0 127 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiModulation
      pgMIDIModulationUpdate
    then
    1 delay
    button2 isSingleClick
  until
  CC_MODULATION midiModulation midiChannel sendControlChange
  2 LED_OFF ledControl
;

\ Set MIDI reverb
: setMIDIReverb ( -- )
  3 LED_ON ledControl
  midiReverb setEncoderValue
  begin
    \ Update step button 3 state
    button3 updateMCBButtonInstance
    8 0 127 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiReverb
      pgMIDIReverbUpdate
    then
    1 delay
    button3 isSingleClick
  until
  CC_REVERB midiReverb midiChannel sendControlChange
  3 LED_OFF ledControl
;

\ Set MIDI chorus
: setMIDIChorus ( -- )
  4 LED_ON ledControl
  midiChorus setEncoderValue
  begin
    \ Update step button 4 state
    button4 updateMCBButtonInstance
    8 0 127 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiChorus
      pgMIDIChorusUpdate
    then
    1 delay
    button4 isSingleClick
  until
  CC_CHORUS midiChorus midiChannel sendControlChange
  4 LED_OFF ledControl
;

\ Set MIDI portamento
: setMIDIPortamento ( -- )
  5 LED_ON ledControl
  midiPortamento setEncoderValue
  begin
    \ Update step button 5 state
    button5 updateMCBButtonInstance
    8 0 127 readEncoder
    if
      \ Encoder changed
      getEncoderValue to midiPortamento
      pgMIDIPortamentoUpdate
    then
    1 delay
    button5 isSingleClick
  until
  midiPortamento
  0<>
  if
    CC_PORTAMENTO_ON_OFF 127          midiChannel sendControlChange
    CC_PORTAMENTO_TIME midiPortamento midiChannel sendControlChange
  else
    CC_PORTAMENTO_ON_OFF 0 midiChannel sendControlChange
    CC_PORTAMENTO_TIME   0 midiChannel sendControlChange
  then
  5 LED_OFF ledControl
;

\ Do MIDI configuration
: doMIDIConfiguration ( -- )

  displayMIDIConfigScreen
  begin
    button0  updateMCBButtonInstance
    button1  updateMCBButtonInstance
    button2  updateMCBButtonInstance
    button3  updateMCBButtonInstance
    button4  updateMCBButtonInstance
    button5  updateMCBButtonInstance
    buttonRE updateMCBButtonInstance

    button0 isSingleClick if setMIDIChannel    then
    button1 isSingleClick if setMIDIVoice      then
    button2 isSingleClick if setMIDIModulation then
    button3 isSingleClick if setMIDIReverb     then
    button4 isSingleClick if setMIDIChorus     then
    button5 isSingleClick if setMIDIPortamento then

    1 delay
    buttonRE isSingleClick
  until

  \ Redisplay programming screen
  displayProgrammingScreen
;

\ ***************************************************************************
\ ***                           Program Entry Point                       ***
\ ***************************************************************************

\ Main program execution
: main ( -- )

  \ Do hardware setup
  hardwareSetup

  \ Do MIDI setup
  midiSetup

  \ Initialize variables
  0 to sequence
  0 to step
  0 to midiNote
  9 to noteGate
  false to noteStatus

  \ Default MIDI channel
  0 to midiChannel

  \ Default MIDI voice
  0 to midiVoice

  \ Init LCD into landscape mode
  1 initLCD

  \ Set default text size
  1 setTextSize

  \ Display initial message
  displayCreditsScreen

  \ Device initially in programming mode
  false to playing

  \ Default tempo
  100 to tempoBPM

  \ Compute step timing
  tempoBPM computeMillisPerStep

  \ Attempt to load sequences into memory
  loadSequences ( -- f )
  \ Was read successful ?
  0=
  if
    \ No it wasn't so initialize sequence data
    fillSequenceData

    \ Save the data
    saveSequences
    0=
    if
      exit
    then
  then

  STATE_DISPATCH_MODE to fsmState

  begin

    \ Update buttons' state
    button0  updateMCBButtonInstance
    button1  updateMCBButtonInstance
    button2  updateMCBButtonInstance
    button3  updateMCBButtonInstance
    button4  updateMCBButtonInstance
    button5  updateMCBButtonInstance
    button6  updateMCBButtonInstance
    button7  updateMCBButtonInstance
    buttonRE updateMCBButtonInstance

    \ Run FSM
    fsmState
    case
      STATE_DISPATCH_MODE
        of
          playing
          if
            STATE_MODE_PLAYING to fsmState

            \ Load transpose value into encoder
            transpose setEncoderValue

            \ Start at step 0 of selected sequence
            0 to step

            \ Update display
            displayRuntimeScreen

            \ Get first sequence note
            step sequence getOn
            if
              step LED_ON ledControl
              step sequence getNoteNumber transpose + dup to midiNote
              step sequence getVelocity
              midiChannel sendNoteOn
            else
              step LED_DIM ledControl
            then

            \ Calculate time to end note
            step sequence getGate stepMillis * 16 / MS-TICKS + to noteEndMillis
          else
            STATE_MODE_PROGRAMMING to fsmState

            \ Turn all button LEDs off
            ledsOff

            \ Start at step 0 of selected sequence
            0 to step
            
            \ Gather sequence data
            step sequence getNoteNumber to midiNote
            step sequence getGate       to noteGate
            step sequence getOn         to noteStatus

            \ Update display
            displayProgrammingScreen
          then
        endof

      STATE_MODE_PLAYING
        of
          \ Check for change to programming state
          buttonRE isLongClick
          if
            false to playing
            STATE_DISPATCH_MODE to fsmState
          then

          \ Check for sequence loading
          button0 isSingleClick if 0 newSequence then  
          button1 isSingleClick if 1 newSequence then  
          button2 isSingleClick if 2 newSequence then  
          button3 isSingleClick if 3 newSequence then  
          button4 isSingleClick if 4 newSequence then  
          button5 isSingleClick if 5 newSequence then  
          button6 isSingleClick if 6 newSequence then  
          button7 isSingleClick if 7 newSequence then  

          \ Check for transpose change
          \ Read encoder. Transpose -36..36 notes. inc 1
          1 -36 36 readEncoder
          if
            getEncoderValue to transpose
            rtTransposeUpdate
          then
          
          \ Check for tempo change triggered by single click of encoder
          buttonRE isSingleClick
          if
            tempoBPM setEncoderValue
            STATE_TEMPO_CHANGE to fsmState
          then

          \ Play the programmed sequence
          noteEndMillis MS-TICKS <
          if
            \ Turn current note off
            midiNote 0 midiChannel sendNoteOff
            step LED_OFF ledControl

            \ Adv to next step
            1 +to step
            step 8 >=
            if 0 to step then

            step sequence getOn
            if
              step LED_ON ledControl

              step sequence getNoteNumber transpose + dup to midiNote
              step sequence getVelocity
              midiChannel sendNoteOn
            else
              step LED_DIM ledControl
            then

            \ Calculate time to end note
            step sequence getGate stepMillis * 16 / MS-TICKS + to noteEndMillis
          then          
        endof

      STATE_TEMPO_CHANGE
        of
          \ Read encoder. Tempo 20..200 BPM. inc 1
          2 20 200 readEncoder
          if
            getEncoderValue setTempo
            rtTempoUpdate
          then

          \ Are we done ?
          buttonRE isSingleClick
          if
            getEncoderValue setTempo
            STATE_DISPATCH_MODE to fsmState
          then
        endof

      STATE_MODE_PROGRAMMING
        of
          buttonRE isLongClick
          if
            saveSequences
            true to playing
            STATE_DISPATCH_MODE to fsmState
          then

          \ Do step note setting
          button0 isSingleClick if 0 setStepNote then  
          button1 isSingleClick if 1 setStepNote then  
          button2 isSingleClick if 2 setStepNote then  
          button3 isSingleClick if 3 setStepNote then  
          button4 isSingleClick if 4 setStepNote then  
          button5 isSingleClick if 5 setStepNote then  
          button6 isSingleClick if 6 setStepNote then  
          button7 isSingleClick if 7 setStepNote then  
          
          \ Do step note gate setting
          button0 isDoubleClick if 0 setStepNoteGate then  
          button1 isDoubleClick if 1 setStepNoteGate then  
          button2 isDoubleClick if 2 setStepNoteGate then  
          button3 isDoubleClick if 3 setStepNoteGate then  
          button4 isDoubleClick if 4 setStepNoteGate then  
          button5 isDoubleClick if 5 setStepNoteGate then  
          button6 isDoubleClick if 6 setStepNoteGate then  
          button7 isDoubleClick if 7 setStepNoteGate then  

          \ Do step note status setting
          button0 isLongClick if 0 setStepNoteStatus then  
          button1 isLongClick if 1 setStepNoteStatus then  
          button2 isLongClick if 2 setStepNoteStatus then  
          button3 isLongClick if 3 setStepNoteStatus then  
          button4 isLongClick if 4 setStepNoteStatus then  
          button5 isLongClick if 5 setStepNoteStatus then  
          button6 isLongClick if 6 setStepNoteStatus then  
          button7 isLongClick if 7 setStepNoteStatus then

          \ Select MIDI configuration
          buttonRE isSingleClick if doMIDIConfiguration then  
        endof     
    endcase

    \ Delay for background processes
    1 delay
    false
  until
;

forth
