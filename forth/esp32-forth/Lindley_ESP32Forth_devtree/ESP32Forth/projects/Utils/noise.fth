\ Noise Functions for ESP32Forth
\ Extracted from noise.cpp in the FASTLED Arduino Library
\ With the idea of making a more pleasing plasma display
\ Porting by: Craig A. Lindley
\ Last Update: 11/24/2022

\ Random Noise Data
create NOISE_DATA
    151 c, 160 c, 137 c,  91 c,  90 c,  15 c, 131 c,  13 c, 201 c,  95 c,  96 c,  53 c, 194 c, 233 c,   7 c, 225 c,
    140 c,  36 c, 103 c,  30 c,  69 c, 142 c,   8 c,  99 c,  37 c, 240 c,  21 c,  10 c,  23 c, 190 c,   6 c, 148 c,
    247 c, 120 c, 234 c,  75 c,   0 c,  26 c, 197 c,  62 c,  94 c, 252 c, 219 c, 203 c, 117 c,  35 c,  11 c,  32 c,
     57 c, 177 c,  33 c,  88 c, 237 c, 149 c,  56 c,  87 c, 174 c,  20 c, 125 c, 136 c, 171 c, 168 c,  68 c, 175 c,
     74 c, 165 c,  71 c, 134 c, 139 c,  48 c,  27 c, 166 c,  77 c, 146 c, 158 c, 231 c,  83 c, 111 c, 229 c, 122 c,
     60 c, 211 c, 133 c, 230 c, 220 c, 105 c,  92 c,  41 c,  55 c,  46 c, 245 c,  40 c, 244 c, 102 c, 143 c,  54 c,
     65 c,  25 c,  63 c, 161 c,   1 c, 216 c,  80 c,  73 c, 209 c,  76 c, 132 c, 187 c, 208 c,  89 c,  18 c, 169 c,
    200 c, 196 c, 135 c, 130 c, 116 c, 188 c, 159 c,  86 c, 164 c, 100 c, 109 c, 198 c, 173 c, 186 c,   3 c,  64 c,
     52 c, 217 c, 226 c, 250 c, 124 c, 123 c,   5 c, 202 c,  38 c, 147 c, 118 c, 126 c, 255 c,  82 c,  85 c, 212 c,
    207 c, 206 c,  59 c, 227 c,  47 c,  16 c,  58 c,  17 c, 182 c, 189 c,  28 c,  42 c, 223 c, 183 c, 170 c, 213 c,
    119 c, 248 c, 152 c,   2 c,  44 c, 154 c, 163 c,  70 c, 221 c, 153 c, 101 c, 155 c, 167 c,  43 c, 172 c,   9 c,
    129 c,  22 c,  39 c, 253 c,  19 c,  98 c, 108 c, 110 c,  79 c, 113 c, 224 c, 232 c, 178 c, 185 c, 112 c, 104 c,
    218 c, 246 c,  97 c, 228 c, 251 c,  34 c, 242 c, 193 c, 238 c, 210 c, 144 c,  12 c, 191 c, 179 c, 162 c, 241 c,
     81 c,  51 c, 145 c, 235 c, 249 c,  14 c, 239 c, 107 c,  49 c, 192 c, 214 c,  31 c, 181 c, 199 c, 106 c, 157 c,
    184 c,  84 c, 204 c, 176 c, 115 c, 121 c,  50 c,  45 c, 127 c,   4 c, 150 c, 254 c, 138 c, 236 c, 205 c,  93 c,
    222 c, 114 c,  67 c,  29 c,  24 c,  72 c, 243 c, 141 c, 128 c, 195 c,  78 c,  66 c, 215 c,  61 c, 156 c, 180 c,
    151 c,


\ Add two bytes together
\ Sum capped at 0xFF or 255

: qadd8 ( i j -- sum )
  +     ( i j -- sum )
  255   ( sum -- sum 255 ) 
  over  ( sum 255 -- sum 255 sum )
  <     ( sum 255 sum -- sum f )
  if    ( sum f -- sum )
    drop 255 ( sum -- 255 )
  else

  then
;
     
\ fract8 is a fixed point unsigned number
\ Example: if a fract8 has the value "64", that should be interpreted
\          as 64/256ths, or one-quarter.
\
\  fract8 range is 0 to 0.99609375 in steps of 0.00390625

\ Scale one byte by a second one, which is treated as
\ the numerator of a fraction whose denominator is 256
\ In other words, it computes i * (scale / 256)

: scale8 ( i fract8 -- result )
  1+ * 8 >>
;


EASE8() is below

LIB8STATIC uint8_t ease8InOutQuad( uint8_t i)
{
    uint8_t j = i;
    if( j & 0x80 ) {
        j = 255 - j;
    }
    uint8_t jj  = scale8(  j, j);
    uint8_t jj2 = jj << 1;
    if( i & 0x80 ) {
        jj2 = 255 - jj2;
    }
    return jj2;
}


int8_t lerp7by8( int8_t a, int8_t b, fract8 frac)
{
    // int8_t delta = b - a;
    // int16_t prod = (uint16_t)delta * (uint16_t)frac;
    // int8_t scaled = prod >> 8;
    // int8_t result = a + scaled;
    // return result;
    int8_t result;
    if( b > a) {
        uint8_t delta = b - a;
        uint8_t scaled = scale8( delta, frac);
        result = a + scaled;
    } else {
        uint8_t delta = a - b;
        uint8_t scaled = scale8( delta, frac);
        result = a - scaled;
    }
    return result;
}

int8_t inoise8_raw(uint16_t x, uint16_t y, uint16_t z)
{
    // Find the unit cube containing the point
    uint8_t X = x>>8;
    uint8_t Y = y>>8;
    uint8_t Z = z>>8;

    // Hash cube corner coordinates
    uint8_t A = P(X)+Y;
    uint8_t AA = P(A)+Z;
    uint8_t AB = P(A+1)+Z;
    uint8_t B = P(X+1)+Y;
    uint8_t BA = P(B) + Z;
    uint8_t BB = P(B+1)+Z;

    // Get the relative position of the point in the cube
    uint8_t u = x;
    uint8_t v = y;
    uint8_t w = z;

    // Get a signed version of the above for the grad function
    int8_t xx = ((uint8_t)(x)>>1) & 0x7F;
    int8_t yy = ((uint8_t)(y)>>1) & 0x7F;
    int8_t zz = ((uint8_t)(z)>>1) & 0x7F;
    uint8_t N = 0x80;

    u = EASE8(u); v = EASE8(v); w = EASE8(w);

    int8_t X1 = lerp7by8(grad8(P(AA), xx, yy, zz), grad8(P(BA), xx - N, yy, zz), u);
    int8_t X2 = lerp7by8(grad8(P(AB), xx, yy-N, zz), grad8(P(BB), xx - N, yy - N, zz), u);
    int8_t X3 = lerp7by8(grad8(P(AA+1), xx, yy, zz-N), grad8(P(BA+1), xx - N, yy, zz-N), u);
    int8_t X4 = lerp7by8(grad8(P(AB+1), xx, yy-N, zz-N), grad8(P(BB+1), xx - N, yy - N, zz - N), u);

    int8_t Y1 = lerp7by8(X1,X2,v);
    int8_t Y2 = lerp7by8(X3,X4,v);

    int8_t ans = lerp7by8(Y1,Y2,w);

    return ans;
}

uint8_t inoise8(uint16_t x) {
    int8_t n = inoise8_raw(x);    //-64..+64
    n += 64;                      // 0..128
    uint8_t ans = qadd8(n,n);     // 0..255
    return ans;
}

/// Calculate an integer average of two signed 7-bit
///       integers (int8_t)
///       If the first argument is even, result is rounded down.
///       If the first argument is odd, result is result up.
LIB8STATIC_ALWAYS_INLINE int8_t avg7( int8_t i, int8_t j)
{
#if AVG7_C == 1
    return ((i + j) >> 1) + (i & 0x1);


static int8_t inline __attribute__((always_inline)) selectBasedOnHashBit(uint8_t hash, uint8_t bitnumber, int8_t a, int8_t b) {
	int8_t result;
#if !defined(__AVR__)
	result = (hash & (1<<bitnumber)) ? a : b;




static int8_t  inline __attribute__((always_inline)) grad8(uint8_t hash, int8_t x, int8_t y, int8_t z) {

    hash &= 0xF;

    int8_t u, v;

    u = selectBasedOnHashBit( hash, 3, y, x);

    v = hash<4?y:hash==12||hash==14?x:z;

    if(hash&1) { u = -u; }
    if(hash&2) { v = -v; }

    return avg7(u,v);
}


