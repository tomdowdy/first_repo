\ Gravity Aware Hour Glass App with Configurable Timing
\ Written in ESP32Forth
\
\ Hardware consists of the following components:
\   ESP32 Mini, MPU6050 IMU, 2 8x8 LED displays with MAX7219 controllers, 
\   a rotary encoder, power switch, battery charger/booster and 1000 maH LiPo battery.
\ See hardware.fth for electrical connections between components
\
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 08/07/2022

\ ********************* Constants & Variables ******************

 1 constant mark                  \ Tag for forgetting

 0 constant MATRIX_A		  \ Identifier for top LED matrix
 1 constant MATRIX_B              \ Identifier for bottom LED matrix

60 constant NUMBER_OF_PARTICLES   \ Number of particles used
 1 constant DEFAULT_DROP_TIME_MIN \ Default time it takes to drop all 60 particles

 0 value dropTimeMS               \ Future time for next particle drop
 0 value dropDelayMin             \ User configured drop time 1 .. 64

 false value dropEnabled          \ Drops enabled when unit on top or bottom
 0 value topDisplay               \ Indicates which of the two displays is on top
 0 value botDisplay               \ Indicates which of the two displays is on the bottom

\ ********************* Support Functions ******************

\ Select Wire vocabulary
Wire

\ Initialize the Wire library in ESP32Forth for using I2C
: initI2C ( -- f )
  MPU_SDA MPU_SCL Wire.begin
  0=
  if 
    \ Initialization Error
    ." Initialization error occurred" cr
    false
  else
    I2C_FREQ Wire.setClock
    true
  then
;

\ Determine hourglass orientation for gravity effect
: determineOrientation
  angleX sf@ 25.0e f>
  if
    \ Hourglass is upright with usb connectors on right
    ROT0 setRotation
    true to dropEnabled 
    MATRIX_A to topDisplay
    MATRIX_B to botDisplay
  else
    angleX sf@ -25.0e f<
    if
      \ Hourglass is upright with usb connectors on left
      ROT180 setRotation
      true to dropEnabled 
      MATRIX_B to topDisplay
      MATRIX_A to botDisplay
    else
      \ Hourglass is in some other orientation so stop the drop
      false to dropEnabled
    then
  then
;

\ Reset drop time calculated from user adjustment
: resetDropTime ( -- )
  dropDelayMin 1000 * ms-ticks + to dropTimeMS
;

\ Calculate coordinates of particle to the right of specified particle
: getRight ( x y -- x+1 y )
  swap 1+ swap
;

\ Calculate coordinates of particle to the left of specified particle
: getLeft ( x y -- x y+1 )
  1+
;

\ Calculate coordinates of particle under specified particle
: getDown ( x y -- x+1 y+1 )
  1+ swap 1+ swap
;

\ Determine if specified particle can move right
\ True if it can; false if it cannot
: canGoRight { disp x y } ( disp x y -- f )
  x 7 = 
  if
    \ Cannot go right
    false
  else
    disp x y getRight getPixel not
  then
;

\ Determine if specified particle can move left
\ True if it can; false if it cannot
: canGoLeft { disp x y } ( disp x y -- f )
  y 7 =
  if
    \ Cannot go left
    false
  else
    disp x y getLeft getPixel not
  then
;

\ Determine if specified particle can move down
\ True if it can; false if it cannot
: canGoDown { disp x y } ( disp x y -- f )
  x 7 = y 7 = or
  if 
    \ Cannot go down
    false
  else
    disp x y getDown getPixel not
  then
;

: goRight { disp x y }   
  disp x y false setPixel
  disp x y getRight true setPixel
;

: goLeft { disp x y }   
  disp x y false setPixel
  disp x y getLeft true setPixel
;

: goDown { disp x y }   
  disp x y false setPixel
  disp x y getDown true setPixel
;

\ Called when it is known a particle can be moved in some direction
: _moveParticle { disp x y cgl cgr cgd } ( disp x y cgl cgr cgd -- )
  cgd
  if
    disp x y goDown
  else
    cgl cgr not and
    if
      disp x y goLeft
    else
      cgr cgl not and
      if
        disp x y goRight
      else
        2 random0toN 1 =
        if
          disp x y goLeft
        else
          disp x y goRight
        then
      then
    then
  then
  display
;

0 value CGL
0 value CGR 
0 value CGD

\ Move a particle on a display
: moveParticle { disp x y }
  \ Is there a particle to move ?
  disp x y getPixel
  if
    \ Yes, see what directions are possible
    disp x y canGoLeft  to CGL
    disp x y canGoRight to CGR
    disp x y canGoDown  to CGD

    \ Is a move possible ?
    CGL CGR CGD or or
    if
      disp x y CGL CGR CGD _moveParticle
      true
    else
      false
    then
  else
    false  
  then
;

0 value particleMoved

\ Traverse matrix and check if particles need to be moved
\ Randomize direction of scan so particles don't always fall the same direction
: updateMatrix ( -- f )
  false to particleMoved
  8 0 false 0 0 0 { n z dir x y t } 
  2 n * 1- 0
  do
    2 random0toN 1 = to dir
    i n <
    if
      0 to z
    else
      i n - 1+ to z
    then
    i z - 1+ z
    do
      dir 
      if
        7 i - to y
        j i - to x
      else
        7 j i - - to y
        i to x
      then
      \ Transform coordinates
      x to t
      y to x
      7 t - to y

      MATRIX_B x y moveParticle
      if
        true to particleMoved
      then
      MATRIX_A x y moveParticle
      if
        true to particleMoved
      then
    loop
  loop
  particleMoved
;

\ Count the number of particles on a display
: countParticles { disp } ( disp -- n )
  0 { ptCount }
  8 0 
  do
    8 0
    do
      disp i j getPixel    
      if
        1 +to ptCount
      then
    loop
  loop
  ptCount
;

\ Fill a display with max count of particles
: fillDisplayParticles { disp maxCount }
  8 0 0 0 0 0 { n count x y z t } 
  2 n * 1- 0
  do
    i n <
    if
      0 to z
    else
      i n - 1+ to z
    then
    i z - 1+ z
    do
      count maxCount <
      if
        j i - to x
        7 i - to y
      
        \ Transform coordinates
        x to t
        y to x
        7 t - to y

        disp x y true setPixel
        1 +to count
      then
    loop 
  loop
  display
;

\ Check for user interaction
\ Single click brings up a UI which displays the drop delay
\ Values are 1 .. 63 minutes
\ An additional click closes the UI and installs the timing value
: checkUserInteraction ( -- )
  \ Poll rotary encoder button
  pollButton

  \ Rotary encoder single click ?
  isSingleClick
  if
    \ Stop the drop
    false to dropEnabled

    \ Clear the matrix and the backing data
    clearDisplay

    1 to encoderValue
    MATRIX_A encoderValue fillDisplayParticles

    begin
      \ Read rotary encoder with inc of 1; min value of 1; max value 63
      1 1 63 readEncoder
      if
        \ Clear the matrix and the backing data
        clearDisplay

        \ Show the new delay value
        0 encoderValue fillDisplayParticles
      then

      \ Poll rotary encoder button
      pollButton

      \ Has the rotary encoder button been clicked ?
      isSingleClick
    until
    \ Install the selected timing value     
    encoderValue to dropDelayMin

    \ Calculate drop time
    resetDropTime

    topDisplay NUMBER_OF_PARTICLES fillDisplayParticles
    1000 delay

    \ Start display
    true to dropEnabled
  then
;

\ ********************* Program Entry ******************

\ Select SPI vocabulary
SPI

\ Initialize hardware
: initHwd ( -- )

  \ Seed random number generator
  randomseed

  \ Initialize VSPI interface for LED displays
  LED_CLK 4 LED_DIN LED_CS VSPI.begin
  SPI_FREQ VSPI.setFrequency

  \ Initialize LED driver
  LED_CS initMAX7219Driver

  \ Initialize I2C interface
  initI2C drop

  \ Initialize MPU6050 IMU
  initMPU6050
  calcGyroOffsets

  \ Initialize rotary encoder multi click button/switch
  RE_SW initButton

  \ Initialize rotary encoder
  RE_PLUS RE_MINUS initRE

  \ Initial display rotation. Applies to both displays
  ROT0 setRotation

  \ Assume device is upright with connectors on right
  MATRIX_A to topDisplay
  MATRIX_B to botDisplay
;

\ Main
: main cr cr

  \ Initialize hardware
  initHwd

  \ Fill a display
  topDisplay NUMBER_OF_PARTICLES fillDisplayParticles

  \ Pause before dropping first particle
  1000 delay

  \ Enable particles to drop
  true to dropEnabled

  \ Initial drop delay time
  DEFAULT_DROP_TIME_MIN to dropDelayMin

  begin

    \ Check for user interaction
    checkUserInteraction

    \ Update IMU
    10 0
    do
      mpuUpdate
    loop

    \ Determine hourglass orientation
    determineOrientation

    \ Time for a particle drop ?
    dropTimeMS ms-ticks < dropEnabled and
    if 
      \ Reset drop timer
      resetDropTime
     
      \ Conditionally move particle between displays
      topDisplay 7 7 getPixel
      if 
        topDisplay 7 7 false setPixel
        botDisplay 0 0 true  setPixel
        display
      then
    then

    updateMatrix drop

    \ See if all of the particles have been moved
    \ If so, stop drop
    botDisplay countParticles NUMBER_OF_PARTICLES =
    if
      false to dropEnabled
    then
    150 delay
    false
  until
;

only forth
