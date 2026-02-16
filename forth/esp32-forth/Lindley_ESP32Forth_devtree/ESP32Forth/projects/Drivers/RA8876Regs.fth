\
\ RA8876 Controller Registers
\ Written in ESP32forth
\ Ported from RA8876_Lite
\ Written/Ported by: Craig A. Lindley
\ Last Update: 10/12/2021

\ Display controller constants
\ $00 constant CMDWRITE
\ $80 constant DATAWRITE
\ $C0 constant DATAREAD
\ $40 constant STATUSREAD

\   4 constant MRWDP 
\   0 constant LVDS_FORMAT
\   3 constant ICR  
\   0 constant GRAPHIC_MODE
\   1 constant TEXT_MODE
\   0 constant MEMORY_SELECT_IMAGE

\   0 constant DISPLAY_OFF
\   1 constant DISPLAY_ON

\   1 constant CCR
\ $CC constant CCR0
\ $CD constant CCR1

\   1 constant PLL_ENABLE
\   0 constant KEY_SCAN_DISABLE
\   0 constant WAIT_NO_MASK
\   0 constant TFT_OUTPUT24
\   0 constant I2C_MASTER_DISABLE
\   0 constant HOST_DATA_BUS_SERIAL
\   2 constant MACR
\   0 constant DIRECT_WRITE
\   0 constant WRITE_MEMORY_LRTB
\   0 constant READ_MEMORY_LRTB
\   1 constant SERIAL_IF_ENABLE
\   0 constant SELECT_CONFIG_PIP1

  \ Color depth selectors
\   1 constant CANVAS_CD_16
\   1 constant S0_CD_16
\   1 constant S1_CD_16
\   1 constant PIP1_CD_16
\   1 constant PIP2_CD_16
\   1 constant IMAGE_CD_16

\   0 constant PIP1_DISABLE
\   0 constant PIP2_DISABLE

\   0 constant CANVAS_BLOCK_MODE
\   0 constant OUTPUT_RGB

\ $10 constant MPWCTR
\ $11 constant PIPCDEP
\ $12 constant DPCR
\ $13 constant PCSR

\ $14 constant HDWR
\ $15 constant HDWFTR
\ $16 constant HNDR
\ $17 constant HNDFTR
\ $18 constant HSTR
\ $19 constant HPWR

\ $1A constant VDHR0
\ $1B constant VDHR1
\ $1C constant VNDR0
\ $1D constant VNDR1
\ $1E constant VSTR
\ $1F constant VPWR

\ $20 constant MISA0
\ $21 constant MISA1
\ $22 constant MISA2
\ $23 constant MISA3

\ $24 constant MIW0
\ $25 constant MIW1
\ $26 constant MWULX0
\ $27 constant MWULX1
\ $28 constant MWULY0
\ $29 constant MWULY1

\ $50 constant CVSSA0
\ $51 constant CVSSA1
\ $52 constant CVSSA2
\ $53 constant CVSSA3
\ $54 constant CVS_IMWTH0
\ $55 constant CVS_IMWTH1

\ $56 constant AWUL_X0
\ $57 constant AWUL_X1
\ $58 constant AWUL_Y0
\ $59 constant AWUL_Y1
\ $5A constant AW_WTH0
\ $5B constant AW_WTH1
\ $5C constant AW_HT0
\ $5D constant AW_HT1
\ $5E constant AW_COLOR

\ $5F constant CURH0
\ $60 constant CURH1
\ $61 constant CURV0
\ $62 constant CURV1

\ Cursor control registers
\ $63 constant F_CURX0
\ $64 constant F_CURX1 
\ $65 constant F_CURY0 
\ $66 constant F_CURY1 

\ $68 constant DLHSR0
\ $69 constant DLHSR1
\ $6A constant DLVSR0
\ $6B constant DLVSR1
\ $6C constant DLHER0
\ $6D constant DLHER1
\ $6E constant DLVER0
\ $6F constant DLVER1

\ $76 constant DCR1
\ $77 constant ELL_A0
\ $78 constant ELL_A1
\ $79 constant ELL_B0
\ $7A constant ELL_B1
\ $7B constant DEHR0
\ $7C constant DEHR1
\ $7D constant DEVR0
\ $7E constant DEVR1

\ $92 constant BTE_COLR

\ Foreground and background color registers
\ $D2 constant FGCR  
\ $D3 constant FGCG
\ $D4 constant FGCB  
\ $D5 constant BGCR    
\ $D6 constant BGCG    
\ $D7 constant BGCB    

\ $80 constant CIRCLE
\ $C0 constant CIRCLE_FILL
\ $A0 constant RECT
\ $E0 constant RECT_FILL
\ $B0 constant ROUNDRECT
\ $F0 constant ROUNDRECT_FILL

\ TFT timing parameters for 1024x600 resolution
\   0 constant TFT_MODE
\   1 constant XHSYNC_INV
\   1 constant XVSYNC_INV
\   0 constant XDE_INV
\   1 constant XPCLK_INV
\  70 constant HPW
\ 160 constant HND
\ 1024 constant HDW
\ 160 constant HST
\  10 constant VPW
\  23 constant VND
\ 600 constant VDH
\  12 constant VST

