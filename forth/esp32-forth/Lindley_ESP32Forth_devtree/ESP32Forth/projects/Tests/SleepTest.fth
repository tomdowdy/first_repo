\ ESP32Forth Sleep Test
\ Test works !
\ 12/10/2022

SLEEP

: main

  30000000 Sleep.timerWakeupUS
  ." Waking UP" cr cr
  ." Wakeup Cause: " Sleep.getCause . cr

  ." Staying Awake" cr
  10000 delay

  ." Going to sleep" cr cr
  Sleep.deepSleep
;
