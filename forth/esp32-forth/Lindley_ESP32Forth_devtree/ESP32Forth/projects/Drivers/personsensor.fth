\ Person Sensor Driver
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 07/14/2023

$62 constant PS_I2C_ADDRESS
 40 constant PS_PACKET_SIZE

\ Configuration commands for the sensor. Write this as a byte to the I2C bus
\ followed by a second byte as an argument value.
$01 constant PSR_MODE
$02 constant PSR_ENABLE_ID
$03 constant PSR_SINGLE_SHOT
$04 constant PSR_CALIBRATE_ID
$05 constant PSR_PERSIST_IDS
$06 constant PSR_ERASE_IDS
$07 constant PSR_DEBUG_MODE

\ The person sensor will never output more than four faces.
4 constant PS_MAX_FACE_COUNT

\ How many different faces the sensor can recognize
7 constant PS_MAX_IDS_COUNT

\ Person sensor data buffer
PS_PACKET_SIZE byteArray PS_DATA

\ Show contents of data buffer
: showBuffer ( -- )
  0 PS_DATA PS_PACKET_SIZE dump
;

Wire

\ Writes the value to the person sensor register over the I2C bus
: psWriteReg ( val reg -- ) 

  PS_I2C_ADDRESS Wire.beginTransmission
  Wire.write
  Wire.write
  PS_I2C_ADDRESS Wire.endTransmission
;

\ Fetch the latest results from the person sensor.
\ Returns true on success; false on failure
: psRead ( -- f )

  PS_I2C_ADDRESS PS_PACKET_SIZE true Wire.requestFrom 
  PS_PACKET_SIZE =
  if
    PS_PACKET_SIZE 0
    do
      Wire.read i PS_DATA c!
    loop
    true
  else
    false
  then
;

\ Initialize I2C interface for person sensor
: initI2C ( -- f )
  \ Bring up I2C interface
  PS_SDA_PIN PS_SCL_PIN Wire.begin
  if
    ." I2C init success"
    true
  else
    ." I2C init failure"
    false
  then
;

\ Offset in data buffer for number of faces data
 4 constant OFFSET_NUM_FACES

\ Offsets to the 4 possible faces detected
 5 constant OFFSET_F1
13 constant OFFSET_F2
21 constant OFFSET_F3
29 constant OFFSET_F4

\ Each face found has a set of information associated with it:
\  box_confidence: How certain we are we have found a face, from 0 to 255.
\  box_left: X coordinate of the left side of the box, from 0 to 255
\  box_top: Y coordinate of the top edge of the box, from 0 to 255
\  box_right: X coordinate of the right side of the box, from 0 to 255
\  box_bottom: Y coordinate of the bottom edge of the box, from 0 to 255
\  id_confidence: How sure the sensor is about the recognition result
\  id: Numerical ID assigned to this face
\  is_facing: Whether the person is facing the camera, 0 or 1

\ Item offsets for person data items
 0 constant BOX_CONFIDENCE
 1 constant BOX_LEFT
 2 constant BOX_TOP
 3 constant BOX_RIGHT
 4 constant BOX_BOTTOM
 5 constant ID_CONFIDENCE
 6 constant ID
 7 constant IS_FACING

\ Get the number of faces reported
: getNumberOfFaces ( -- faces )
  OFFSET_NUM_FACES PS_DATA c@
;

\ Get box confidence for specified face
: getBoxConfidence ( offset -- boxConfidence ) 
  PS_DATA c@
;

\ Get box left for specified face
: getBoxLeft ( offset -- boxLeft ) 
  BOX_LEFT + PS_DATA c@
;

\ Get box top for specified face
: getBoxTop ( offset -- boxTop ) 
  BOX_TOP + PS_DATA c@
;

\ Get box right for specified face
: getBoxRight ( offset -- boxRight ) 
  BOX_RIGHT + PS_DATA c@
;

\ Get box bottom for specified face
: getBoxBottom ( offset -- boxBottom ) 
  BOX_BOTTOM + PS_DATA c@
;

\ Get id confidence for specified face
: getIDConfidence ( offset -- idConfidence ) 
  ID_CONFIDENCE + PS_DATA c@
;

\ Get id for specified face
: getID ( offset -- id ) 
  ID + PS_DATA c@
;

\ Get is facing value for specified face
: getIsFacing ( offset -- isFacing ) 
  IS_FACING + PS_DATA c@
;

\ Calculate horizontal (left/right) offset in acquisition window for specified face
: horizOffset { offset } ( offset -- horizOffset )
  offset getBoxRight offset getBoxLeft dup >r - 2 / r> + 127 -
;

\ Calculate vertical (top/bottom) offset in acquisition window for specified face
: vertOffset { offset } ( offset -- vertOffset )
  offset getBoxBottom offset getBoxTop dup >r - 2 / r> + 127 -
;

Forth
