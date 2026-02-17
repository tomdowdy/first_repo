\ Earth Quake Mapping Functions
\ Concept, Design and Implementation by: Craig A. Lindley
\ Last Update: 09/08/2021

\ Mapping between lon and lat to screen coordinates

\ Screen dimensions
320 constant SCREEN_WIDTH
240 constant SCREEN_HEIGHT

\ Equirectangular map dimensions
320 constant MAP_WIDTH
161 constant MAP_HEIGHT

SCREEN_HEIGHT MAP_HEIGHT - 2 / constant MAP_Y_OFFSET

FIXED_PT

\ Fixed Point Conversion Constants
z" 320.0"  FP.fromZ" constant FP_MAP_WIDTH
z" 161.0"  FP.fromZ" constant FP_MAP_HEIGHT
z"  90.0"  FP.fromZ" constant C90
z" 180.0"  FP.fromZ" constant C180
z" 360.0"  FP.fromZ" constant C360
z" -1.0"   FP.fromZ" constant CMinus1


: lonToMapX ( fpDecimalLon -- scnX )
  C180 FP.add FP_MAP_WIDTH FP.mult C360 FP.div FP.toInt
;

: latToMapY ( fpDecimalLat -- scnY )
  CMinus1 FP.mult C90 FP.add FP_MAP_HEIGHT FP.mult C180 FP.div FP.toInt MAP_Y_OFFSET +
;

Forth

