\ Weather Station Application for ESP32forth
\ Concept, design and implementation by: Craig A. Lindley
\ Last Update: 03/12/2023

WiFi


\ Weather Station Code
: main
  
  \ Login to Wifi network
  \ SSID s>z PSWD s>z login

  100 delay

  \ Set the Mountain Timezone
  \ usMT setTZ

  \ Initialize the LCD controller with standard rotation
  \ Top of screen towards 4 pin connector
  0 initLCD

  \ Clear the LCD to black
  clearScreen

  1 setTextSize
  
  10 s" Text size 1" pCenteredString

  2 setTextSize

  30 s" Text size 2" pCenteredString

  3 setTextSize
  $780F setFGColor
  60 s" Text size 3" pCenteredString


;


