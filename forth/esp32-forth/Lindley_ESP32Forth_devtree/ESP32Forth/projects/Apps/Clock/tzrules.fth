\ Time Zone Rules
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 08/13/2021
 
\ US Mountain Time Zone (Denver, Salt Lake City)
\ TimeChangeRule usMDT = {"MDT", Second, Sun, Mar, 2, -360};
\ TimeChangeRule usMST = {"MST", First, Sun, Nov, 2, -420};
\ Timezone usMT(usMDT, usMST);

\ Create TCR for daylight savings time
newTCR usMDT

\ Initialize rule
 2 usMDT .wk  !
 1 usMDT .dow !
 3 usMDT .mon !
 2 usMDT .hr  !
-360 usMDT .off !

\ Create TCR for standard time
newTCR usMST

\ Initialize rule
 1 usMST .wk  !
 1 usMST .dow !
11 usMST .mon !
 2 usMST .hr  !
-420 usMST .off !

\ Create TZ object to hold TCRs
newTZ usMT

0      usMT .index !
usMDT usMT .dstTCR !
usMST usMT .stdTCR !

