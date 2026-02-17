\ Convert wind direction in degrees to a string
\ Wind directions
\ Abbrev Direction    Degrees
\ N 	North 	         0°
\ NNE 	North-Northeast 22.5°
\ NE 	Northeast 	45°
\ ENE 	East-Northeast 	67.5°
\ E 	East 		90°
\ ESE 	East-Southeast 	112.5°
\ SE 	Southeast 	135°
\ SSE 	South-Southeast 157.5°
\ S 	South 		180°
\ SSW 	South-Southwest	202.5°
\ SW 	Southwest 	225°
\ WSW 	West-Southwest 	247.5°
\ W 	West 		270°
\ WNW 	West-Northwest 	292.5°
\ NW 	Northwest 	315°
\ NNW 	North-Northwest	337.5°

0 value _degx100

\ Pass degrees * 100 and get back string addr
: convertWindDirection ( degx100 -- addr n )
  to _degx100

  _degx100 34875 36000 between? _degx100 0 1124 between? or 
  if s" N" exit then
  _degx100 1125 3374 between? 
  if s" NNE" exit then
  _degx100 3375 5624 between? 
  if s" NE" exit then
  _degx100 5625 7874 between? 
  if s" ENE" exit then
  _degx100 7875 10124 between? 
  if s" E" exit then
  _degx100 10125 12374 between? 
  if s" ESE" exit then
  _degx100 12375 14624 between? 
  if s" SE" exit then
  _degx100 14625 16874 between? 
  if s" SSE" exit then
  _degx100 16875 19124 between? 
  if s" S" exit then
  _degx100 19125 21374 between? 
  if s" SSW" exit then
  _degx100 21375 23624 between? 
  if s" SW" exit then
  _degx100 23625 25874 between? 
  if s" WSW" exit then
  _degx100 25875 28124 between? 
  if s" W" exit then
  _degx100 28125 30374 between? 
  if s" WNW" exit then
  _degx100 30375 32624 between? 
  if s" NW" exit then
  _degx100 32625 34874 between? 
  if s" NNW" exit then
;

: testWD ( deg -- )
  convertWindDirection type cr ;
;



