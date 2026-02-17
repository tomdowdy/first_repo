\ NTP - Network Time Protocol Access
\ Written for ESP32forth
\ By: Craig A. Lindley
\ Last Update: 08/13/2021

Networking

\ Port to send NTP requests to
123 constant NTP_PORT

\ NTP time stamp in first 48 bytes of message
48 constant PACKET_SIZE   

\ Buffer for UDP packets
PACKET_SIZE bytearray pBuf

\ Clear buffer
: clearBuf
  \ Clear all bytes of the packet buffer
  PACKET_SIZE 0
  do
      0 i pBuf c!
  loop
;

\ Initialize UDP data in buffer
: initBuf
  $E3  0 pBuf c!
  $06  2 pBuf c!
  $EC  3 pBuf c!
  $31 12 pBuf c!
  $4E 13 pBuf c!
  $31 14 pBuf c!
  $34 15 pBuf c!
;

0 value conn

\ Send an NTP request packet and read response packet
: getTime     ( -- secondsSince1970 | 0 )

  \ Clear the packet buffer
  clearBuf

  \ Initialize the packet content
  initBuf
 
  \ Make connection to NTP time server
  UDP z" time.nist.gov" NTP_PORT Net.connect to conn
  conn 0 >
  if
    \ Send the NTP UDP packet
    conn 0 pBuf PACKET_SIZE Net.udpSend
    0=
    if 
      \ Read response into buffer
      conn 0 pBuf PACKET_SIZE Net.read
  
      PACKET_SIZE =
      if 
        \ Assemble the response into time value
        40 pBuf c@ 24 <<
        41 pBuf c@ 16 << or
        42 pBuf c@  8 << or
        43 pBuf c@       or

        \ Convert to seconds since 1970
        2208988800 -       
      else
        0
      then
    else
      0
    then
    \ Terminate the connection
    conn Net.dispose
  else
    0
  then
;

forth








