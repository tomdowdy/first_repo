\ Test of the SD card interface on the CYD


: run cr

  s" /spiffs/ERP320.bmp" r/o open-file 0=
  if
    drop   
    ." Open successful"
  else
    drop
    ." Open failed"
  then
;

run






