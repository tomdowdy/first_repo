\
\ Sequencer Constants and Runtime Variables
\
\ Concept, Design and Implementaton by: Craig A. Lindley
\ Last Update: 05/12/2023
\

\ ***************************************************************************
\ ***                               Constants                             ***
\ ***************************************************************************

\ Current version number
1 constant MAJOR_VERSION_NUMBER
0 constant MINOR_VERSION_NUMBER

\ LED brightness values
  0 constant LED_OFF
 20 constant LED_DIM
255 constant LED_ON

\ ***************************************************************************
\ ***                            Runtime Variables                        ***
\ ***************************************************************************

\ Program variables displayed and manipulated in the Sequencer UI
0 value sequence
0 value step
0 value noteGate
0 value noteStatus
0 value tempoBPM
0 value transpose
0 value playing

0 value midiNote
0 value midiChannel
0 value midiVoice
0 value midiModulation
0 value midiReverb
0 value midiChorus
0 value midiPortamento

