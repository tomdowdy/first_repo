\
\ Earth Quake Mapping Functions
\ Using floating point instead of fix point
\ as in the previous versions
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 11/10/2023
\

\ Mapping between lon and lat to screen coordinates

\ Screen dimensions
320 constant SCREEN_WIDTH
240 constant SCREEN_HEIGHT

\ Equirectangular map dimensions
320 constant MAP_WIDTH
161 constant MAP_HEIGHT

SCREEN_HEIGHT MAP_HEIGHT - 2 / constant MAP_Y_OFFSET

\ Fixed Point Conversion Constants
320.0e fconstant FP_MAP_WIDTH
161.0e fconstant FP_MAP_HEIGHT
 90.0e fconstant C90
180.0e fconstant C180
360.0e fconstant C360
 -1.0e fconstant CMinus1


: lonToMapX ( fpDecimalLon -- scnX )
  C180 f+ FP_MAP_WIDTH f* C360 f/ f>s
;

: latToMapY ( fpDecimalLat -- scnY )
  CMinus1 f* C90 f+ FP_MAP_HEIGHT f* C180 f/ f>s MAP_Y_OFFSET +
;

Forth

