\
\ MPU6050 IMU Driver
\ Ported from code written by: tockn
\ See: https://github.com/tockn/MPU6050_tockn
\ Written for ESP32Forth
\ Ported by: Craig A. Lindley
\ Last Update: 07/24/2022

\ Constants
$19 constant MPU_SMPLRT_DIV
$1A constant MPU_CONFIG
$1B constant MPU_GYRO_CONFIG 
$1C constant MPU_ACCEL_CONFIG
$6B constant MPU_PWR_MGMT_1

1000 constant DELAY_BEFORE
1000 constant DELAY_AFTER

\ Integer Variables
0 value rawAccX
0 value rawAccY
0 value rawAccZ
0 value rawTemp
0 value rawGyroX
0 value rawGyroY
0 value rawGyroZ
0 value preInterval
0 value rx
0 value ry
0 value rz

\ Floating Point Variables
fvariable gyroXoffset
fvariable gyroYoffset
fvariable gyroZoffset
fvariable temp
fvariable accX
fvariable accY
fvariable accZ
fvariable gyroX
fvariable gyroY
fvariable gyroZ
fvariable angleGyroX
fvariable angleGyroY
fvariable angleGyroZ
fvariable angleAccX
fvariable angleAccY
fvariable angleAccZ
fvariable angleX
fvariable angleY
fvariable angleZ
fvariable interval
fvariable accCoef
fvariable gyroCoef
fvariable x
fvariable y
fvariable z

\ Low Level MPU6050 I2C functions

\ Bring in WIRE vocabulary
also WIRE

\ Write MPU6050
: writeMPU6050 { reg data }
  MPU_ADDR Wire.beginTransmission
  reg  Wire.write drop
  data Wire.write drop
  true Wire.endTransmission 0<>
  if
    ." Wire error" cr
  then
;

\ Read a signed 16 bit value from I2C
: read16BitWord ( -- n )
  \ Read two bytes
  Wire.read Wire.read { MSB LSB }
  MSB 128 and 0<>
  if
    \ 16 bit word will be negative
     $FFFF0000 MSB 8 << or LSB or
  else
    \ 16 bit word will be positive
    MSB 8 << LSB or
  then
;

\ Calculate gyro offsets
: calcGyroOffsets ( -- )
  DELAY_BEFORE delay

  3000 0
  do
    MPU_ADDR Wire.beginTransmission
    $43 Wire.write drop
    false Wire.endTransmission 0<>
    if
      ." Wire error" cr
    then
    MPU_ADDR 6 true Wire.requestFrom drop

    read16BitWord to rx
    read16BitWord to ry
    read16BitWord to rz

    rx s>f 65.5e f/ x sf@ f+ x sf!
    ry s>f 65.5e f/ y sf@ f+ y sf!
    rz s>f 65.5e f/ z sf@ f+ z sf!
  loop

  x sf@ 3000.0e f/ gyroXOffset sf!
  y sf@ 3000.0e f/ gyroYOffset sf!
  z sf@ 3000.0e f/ gyroZOffset sf!

 \ gyroXOffset sf@ ." X: " f. cr
 \ gyroYOffset sf@ ." Y: " f. cr
 \ gyroZOffset sf@ ." Z: " f. cr

  DELAY_AFTER delay
;

\ Update data from the MPU6050
: mpuUpdate ( -- )
  MPU_ADDR Wire.beginTransmission
  $3B Wire.write drop
  false Wire.endTransmission 0<>
  if
    ." Wire error" cr
  then
  MPU_ADDR 14 true Wire.requestFrom drop

  \ Read the data
  read16BitWord to rawAccX
  read16BitWord to rawAccY
  read16BitWord to rawAccZ
  read16BitWord to rawTemp
  read16BitWord to rawGyroX
  read16BitWord to rawGyroY
  read16BitWord to rawGyroZ

  rawTemp s>f 12412.0e f+ 340.0e f/ temp sf!

  \ ." Temp: " temp sf@ f. cr

  rawAccX s>f 16384.0e f/ accX sf!
  rawAccY s>f 16384.0e f/ accY sf!
  rawAccZ s>f 16384.0e f/ accZ sf!

  accY sf@ accZ sf@ accZ sf@ f* accX sf@ accX sf@ f* f+ fsqrt fatan2 
    360e f* 2.0e f/ pi f/ angleAccX sf!

  accX sf@ accZ sf@ accZ sf@ f* accY sf@ accY sf@ f* f+ fsqrt fatan2 
    360e f* -2.0e f/ pi f/ angleAccY sf!

  rawGyroX s>f 65.5e f/ gyroX sf!
  rawGyroY s>f 65.5e f/ gyroY sf!
  rawGyroZ s>f 65.5e f/ gyroZ sf!

  gyroX sf@ gyroXoffset sf@ f- gyroX sf!
  gyroY sf@ gyroYoffset sf@ f- gyroY sf!
  gyroZ sf@ gyroZoffset sf@ f- gyroZ sf!

  ms-ticks preInterval - s>f 0.001e f* interval sf!

  gyroX sf@ interval sf@ f* angleGyroX sf@ f+ angleGyroX sf!
  gyroY sf@ interval sf@ f* angleGyroY sf@ f+ angleGyroY sf!
  gyroZ sf@ interval sf@ f* angleGyroZ sf@ f+ angleGyroZ sf!

  gyroX sf@ interval sf@ f* angleX sf@ f+ gyroCoef sf@ f*
    accCoef sf@ angleAccX sf@ f* f+ angleX sf!

  gyroY sf@ interval sf@ f* angleY sf@ f+ gyroCoef sf@ f*
    accCoef sf@ angleAccY sf@ f* f+ angleY sf!

  angleGyroZ sf@ angleZ sf!

  ms-ticks to preInterval
;

\ Initialize the MPU6050
: initMPU6050 ( -- )
  \ Install coefficients
  0.02e accCoef  sf!
  0.98e gyroCoef sf!

  \ Initialize all variables just in case

  \ Integer Variables
  0 to rawAccX  0 to rawAccY  0 to rawAccZ
  0 to rawTemp
  0 to rawGyroX 0 to rawGyroY 0 to rawGyroZ
  0 to preInterval
  0 to rx       0 to ry       0 to rz

  \ Floating Point Variables
  0.0e gyroXoffset sf! 0.0e gyroYoffset sf! 0.0e gyroZoffset sf!
  0.0e temp        sf!
  0.0e accX        sf! 0.0e accY        sf! 0.0e accZ        sf!
  0.0e gyroX       sf! 0.0e gyroY       sf! 0.0e gyroZ       sf!
  0.0e angleGyroX  sf! 0.0e angleGyroY  sf! 0.0e angleGyroZ  sf!
  0.0e angleAccX   sf! 0.0e angleAccY   sf! 0.0e angleAccZ   sf!
  0.0e angleX      sf! 0.0e angleY      sf! 0.0e angleZ      sf!
  0.0e interval    sf!
  0.0e x           sf! 0.0e y           sf! 0.0e z           sf!

  \ Configure device
  MPU_SMPLRT_DIV   0 writeMPU6050
  MPU_CONFIG       0 writeMPU6050
  MPU_GYRO_CONFIG  8 writeMPU6050
  MPU_ACCEL_CONFIG 0 writeMPU6050
  MPU_PWR_MGMT_1   1 writeMPU6050

  \ Update device
  mpuUpdate

  \ Initialize variables
  0.0e angleGyroX sf!
  0.0e angleGyroY sf!

  angleAccX sf@ angleX sf!
  angleAccY sf@ angleY sf!

  ms-ticks to preInterval
;

