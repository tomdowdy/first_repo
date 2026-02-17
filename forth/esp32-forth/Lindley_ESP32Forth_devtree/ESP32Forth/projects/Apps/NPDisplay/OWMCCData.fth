\ Parser for Open Weather Map Current Conditions Data

\ Structure for holding OWM forecast data
struct:
    cell field: .sunriseIndex
    cell field: .sunsetIndex
    cell field: .descIndex
    cell field: .tempIndex
    cell field: .humIndex
    cell field: .presIndex
    cell field: .minTempIndex
    cell field: .maxTempIndex
    cell field: .windSpeedIndex
    cell field: .windDirIndex
    cell field: .cityIndex
constant OWMDATASTRUCT

\ Create instance generator
: new-OWMDATASTRUCT: OWMDATASTRUCT create allot ;

\ Create structure instance for data storage
new-OWMDATASTRUCT: owmccd

\ Show attribute
: showAttrib ( index -- )
  stGet type cr
;

\ Current key data storage
15 byteArray currentKey

\ jParser deferred words resolution

: owmccStartDocument ( -- ) ;

: owmccEndDocument ( -- ) ;

: owmccStartObject ( -- ) ;

: owmccEndObject ( -- ) ;

: owmccStartArray ( -- ) ;

: owmccEndArray ( -- ) ;

: owmc_ckey ( addr n -- ) 2dup ." currentKey: " type cr
  dup >r s>z 0 currentKey r> 1+ cmove
;

0 value _ck

: owmccValue ( addr n -- )

  0 currentKey to _ck

  _ck z" sunrise"     z"cmp 0= if stAdd owmccd .sunriseIndex   ! exit then
  _ck z" sunset"      z"cmp 0= if stAdd owmccd .sunsetIndex    ! exit then
  _ck z" description" z"cmp 0= if stAdd owmccd .descIndex      ! exit then
  _ck z" temp"        z"cmp 0= if stAdd owmccd .tempIndex      ! exit then
  _ck z" humidity"    z"cmp 0= if stAdd owmccd .humIndex       ! exit then
  _ck z" pressure"    z"cmp 0= if stAdd owmccd .presIndex      ! exit then
  _ck z" temp_min"    z"cmp 0= if stAdd owmccd .minTempIndex   ! exit then
  _ck z" temp_max"    z"cmp 0= if stAdd owmccd .maxTempIndex   ! exit then
  _ck z" speed"       z"cmp 0= if stAdd owmccd .windSpeedIndex ! exit then
  _ck z" deg"         z"cmp 0= if stAdd owmccd .windDirIndex   ! exit then
  _ck z" name"        z"cmp 0= if stAdd owmccd .cityIndex      ! exit then
  2drop
;

\ Retrieve OWM data and store in structure
: gatherOWMCCData
  \ Resolve the necessary deferred words for jParser
  ['] owmccStartDocument is jStartDocument
  ['] owmccEndDocument is jEndDocument
  ['] owmccStartObject is jStartObject
  ['] owmccEndObject is jEndObject
  ['] owmccStartArray is jStartArray
  ['] owmccEndArray is jEndArray
  ['] owmc_ckey is jKey
  ['] owmccValue is jValue

  \ Clear the string table
  stInit

  \ Prepare the HTTP GET
  prepareCurrentConditionsGET

  \ Execute the HTTP GET
  executeGET
;

\ Get sunrise time string
: sunriseTime ( -- addr n )
  owmccd .sunriseIndex @ stGet
;

\ Get sunset time string
: sunsetTime ( -- addr n )
  owmccd .sunsetIndex @ stGet
;

\ Get weather description string
: description ( -- addr n )
  owmccd .descIndex @ stGet
;  

\ Get temp string
: temp ( -- addr n )
  owmccd .tempIndex @ stGet
;

\ Get humidity string
: humidity ( -- addr n )
  owmccd .humIndex @ stGet
;

\ Get pressure string
: pressure ( -- addr )
  owmccd .presIndex @ stGet
;

\ Get min temp string
: minTemp ( -- addr n )
  owmccd .minTempIndex @ stGet
;

\ Get max temp string
: maxTemp ( -- addr n )
  owmccd .maxTempIndex @ stGet
;

\ Get wind speed string
: windSpeed ( -- addr n )
  owmccd .windSpeedIndex @ stGet
;

\ Get wind direction string
: windDir ( -- addr n )
  owmccd .windDirIndex @ stGet
;

\ Get city name string
: city ( -- addr n )
  owmccd .cityIndex @ stGet
;

