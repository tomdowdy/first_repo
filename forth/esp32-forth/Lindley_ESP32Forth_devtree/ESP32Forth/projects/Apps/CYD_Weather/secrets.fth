\ Secrets File for the CYD ESP32Forth Weather Station

\ WiFi Login Credentials
: SSID  z" CraigNet" ;
: PSWD  z" craigandheather" ;

\ Open Weather Map Info
: APIKEY  s" 512f63fc90533134388edda77e7beaf5 " ; \ ending space necessary
: ZIPCODE s" 80919,us" ;
: UNITS   s" imperial" ;
: HOST    s" craigandheather.net" ;
