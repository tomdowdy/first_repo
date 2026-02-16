\ Multi-Display Clock Event Patterns
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 05/23/2022

\ Event display duration
25                         constant EVENT_DURATION_SECS
EVENT_DURATION_SECS 1000 * constant EVENT_DURATION_MS

\ Icon positioning locations on display
 0 constant POS_H
48 constant POS_M
96 constant POS_L

\ Animation that runs for specified length of time in milliseconds
: spaceEventPattern { ms } ( ms -- )

  \ Place the space icons on the displays
  0 MEDIUM_ICON mediumSunIcon   POS_H drawIcon
  0 MEDIUM_ICON mediumStar1Icon POS_L drawIcon
  1 MEDIUM_ICON mediumSunIcon   POS_M drawIcon
  2 MEDIUM_ICON mediumStar2Icon POS_H drawIcon
  2 MEDIUM_ICON mediumSunIcon   POS_L drawIcon
  3 MEDIUM_ICON mediumMoonIcon  POS_M drawIcon
  4 MEDIUM_ICON mediumStar1Icon POS_H drawIcon
  4 MEDIUM_ICON mediumSunIcon   POS_L drawIcon
  5 MEDIUM_ICON mediumMoonIcon  POS_M drawIcon

  \ Calculate time to end display pattern
  ms-ticks ms + { endTime }
  
  begin
    \ Rotate the space icons
    rotate
    showAllDisplays

    ms-ticks endTime >
  until
;

\ Animation that runs for specified length of time in milliseconds
: peaceEventPattern { ms } ( ms -- )

  \ Place the space icons on the displays
  0 MEDIUM_ICON mediumPeaceIcon POS_H drawIcon
  1 MEDIUM_ICON mediumPeaceIcon POS_L drawIcon
  2 MEDIUM_ICON mediumPeaceIcon POS_M drawIcon
  3 MEDIUM_ICON mediumPeaceIcon POS_H drawIcon
  4 MEDIUM_ICON mediumPeaceIcon POS_M drawIcon
  5 MEDIUM_ICON mediumPeaceIcon POS_L drawIcon

  \ Calculate time to end display pattern
  ms-ticks ms + { endTime }
  
  begin
    \ Rotate the space icons
    rotate
    showAllDisplays

    ms-ticks endTime >
  until
;

\ Draw up arrow icon on specified display at specified Y offset
: drawUpArrow { dispNum index } ( dispNum index -- )

  dispNum SMALL_ICON smallUpArrowIcon 
  index 1+ index SMALL_ICON_HEIGHT * +
  drawIcon
;

\ Draw down arrow icon on specified display at specified Y offset
: drawDownArrow { dispNum index } ( dispNum index -- )

  dispNum SMALL_ICON smallDownArrowIcon
  index 1+ index SMALL_ICON_HEIGHT * +
  drawIcon
;

\ Animation that runs for specified length of time in milliseconds
: upArrowEventPattern { ms } ( ms -- )

  \ Calculate time to end display pattern
  ms-ticks ms + { endTime }

  0 { upIndex }

  begin
    7 to upIndex

    8 0
    do
      NUM_OF_DISPLAYS 0
      do
        i upIndex drawUpArrow
      loop
      -1 +to upIndex
    loop
    flashBlue
    clearDisplays

    ms-ticks endTime >
  until
;

\ Animation that runs for specified length of time in milliseconds
: upDownArrowEventPattern { ms } ( ms -- )

  \ Calculate time to end display pattern
  ms-ticks ms + { endTime }

  0 0 { upIndex downIndex }

  begin
    7 to upIndex
    0 to downIndex

    8 0
    do
      NUM_OF_DISPLAYS 0
      do
        i 2 mod 0=
        if
          i upIndex drawUpArrow
        else
          i downIndex drawDownArrow
        then
      loop
      -1 +to upIndex
       1 +to downIndex
    loop
    clearDisplays
    flashGreen

    7 to upIndex
    0 to downIndex
    8 0
    do
      NUM_OF_DISPLAYS 0
      do
        i 2 mod 0=
        if
          i downIndex drawDownArrow
        else 
          i upIndex drawUpArrow
        then
      loop
      -1 +to upIndex
       1 +to downIndex
    loop
    clearDisplays
    flashBlue

    ms-ticks endTime >
  until
;


