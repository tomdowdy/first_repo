\ Time Zone Rules
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 08/14/2021

\ Get the name of a timezone
: tzNameFromIndex ( index -- addr n )
  case
    0 of s" Sydney"      endof
    1 of s" Frankfurt"   endof
    2 of s" London"      endof
    3 of s" New York"    endof
    4 of s" Houston"     endof
    5 of s" Denver"      endof
    6 of s" Phoenix"     endof
    7 of s" Los Angeles" endof
  endcase
;

\ Australia Eastern Time Zone (Sydney, Melbourne)
\ TTimeChangeRule aEDT = {"AEDT", First, Sun, Oct, 2, 660};    //UTC + 11 hours
\ TimeChangeRule aEST = {"AEST", First, Sun, Apr, 3, 600};    //UTC + 10 hours
\ Timezone ausET(aEDT, aEST);

\ Create TCR for daylight saving time
newTCR aEDT

\ Initialize rule
 1 aEDT .wk   !
 1 aEDT .dow  !
10 aEDT .mon  !
 2 aEDT .hr   !
660 aEDT .off !

\ Create TCR for standard time
newTCR aEST

\ Initialize rule
 1 aEST .wk   !
 1 aEST .dow  !
 4 aEST .mon  !
 3 aEST .hr   !
600 aEST .off !

\ Create TZ object to hold TCRs
newTZ ausET

0    ausET .index  !
aEDT ausET .dstTCR !
aEST ausET .stdTCR !

\ Central European Time (Frankfurt, Paris)
\ TimeChangeRule CEST = {"CEST", Last, Sun, Mar, 2, 120};     //Central European Summer Time
\ TimeChangeRule CET = {"CET ", Last, Sun, Oct, 3, 60};       //Central European Standard Timezone CE(CEST, CET);

\ Create TCR for daylight saving time
newTCR CEST

\ Initialize rule
 0 CEST .wk   !
 1 CEST .dow  !
 3 CEST .mon  !
 2 CEST .hr   !
120 CEST .off !

\ Create TCR for standard time
newTCR CET

\ Initialize rule
 0 CET .wk  !
 1 CET .dow !
10 CET .mon !
 3 CET .hr  !
60 CET .off !

\ Create TZ object to hold TCRs
newTZ CE

1    CE .index  !
CEST CE .dstTCR !
CET  CE .stdTCR !

\ United Kingdom (London, Belfast)
\ TimeChangeRule BST = {"BST", Last, Sun, Mar, 1, 60};        //British Summer Time
\ TimeChangeRule GMT = {"GMT", Last, Sun, Oct, 2, 0};         //Standard Time
\ Timezone UK(BST, GMT);

\ Create TCR for daylight saving time
newTCR BST

\ Initialize rule
 0 BST .wk  !
 1 BST .dow !
 3 BST .mon !
 1 BST .hr  !
60 BST .off !

\ Create TCR for standard time
newTCR GMT

\ Initialize rule
 0 GMT .wk  !
 1 GMT .dow !
10 GMT .mon !
 2 GMT .hr  !
 0 GMT .off !

\ Create TZ object to hold TCRs
newTZ UK

2   UK .index  !
BST UK .dstTCR !
GMT UK .stdTCR !

\ US Eastern Time Zone (New York, Detroit)
\ TimeChangeRule usEDT = {"EDT", Second, Sun, Mar, 2, -240};
\ TimeChangeRule usEST = {"EST", First, Sun, Nov, 2, -300};
\ Timezone usET(usEDT, usEST);

\ Create TCR for daylight saving time
newTCR usEDT

\ Initialize rule
 2 usEDT .wk  !
 1 usEDT .dow !
 3 usEDT .mon !
 2 usEDT .hr  !
-240 usEDT .off !

\ Create TCR for standard time
newTCR usEST

\ Initialize rule
 1 usEST .wk  !
 1 usEST .dow !
11 usEST .mon !
 2 usEST .hr  !
-300 usEST .off !

\ Create TZ object to hold TCRs
newTZ usET

3     usET .index  !
usEDT usET .dstTCR !
usEST usET .stdTCR !

\ US Central Time Zone (Chicago, Houston)
\ TimeChangeRule usCDT = {"CDT", Second, Sun, Mar, 2, -300};
\ TimeChangeRule usCST = {"CST", First, Sun, Nov, 2, -360};
\ Timezone usCT(usCDT, usCST);

\ Create TCR for daylight saving time
newTCR usCDT

\ Initialize rule
 2 usCDT .wk  !
 1 usCDT .dow !
 3 usCDT .mon !
 2 usCDT .hr  !
-300 usCDT .off !

\ Create TCR for standard time
newTCR usCST

\ Initialize rule
 1 usCST .wk  !
 1 usCST .dow !
11 usCST .mon !
 2 usCST .hr  !
-360 usCST .off !

\ Create TZ object to hold TCRs
newTZ usCT

4     usCT .index  !
usCDT usCT .dstTCR !
usCST usCT .stdTCR !
 
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

5     usMT .index  !
usMDT usMT .dstTCR !
usMST usMT .stdTCR !

\ Arizona is US Mountain Time Zone but does not use DST
\ Timezone usAZ(usMST, usMST);

\ Create TZ object to hold TCRs
newTZ usAZ

6     usAZ .index  !
usMST usAZ .dstTCR !
usMST usAZ .stdTCR !

\ US Pacific Time Zone (Las Vegas, Los Angeles)
\ TimeChangeRule usPDT = {"PDT", Second, Sun, Mar, 2, -420};
\ TimeChangeRule usPST = {"PST", First, Sun, Nov, 2, -480};
\ Timezone usPT(usPDT, usPST);

\ Create TCR for daylight savings time
newTCR usPDT

\ Initialize rule
 2 usPDT .wk  !
 1 usPDT .dow !
 3 usPDT .mon !
 2 usPDT .hr  !
-420 usPDT .off !

\ Create TCR for standard time
newTCR usPST

\ Initialize rule
 1 usPST .wk  !
 1 usPST .dow !
11 usPST .mon !
 2 usPST .hr  !
-480 usPST .off !

\ Create TZ object to hold TCRs
newTZ usPT

7     usPT .index  !
usPDT usPT .dstTCR !
usPST usPT .stdTCR !

