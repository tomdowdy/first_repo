/*
 * Copyright 2021 Bradley D. Nelson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/
 
/*
 * ESP32forth v7.0.6.5 - With modifications by: Craig A. Lindley (CAL) 
 * Last Update: V4.1 - 07/11/2023
 */

#include <inttypes.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "driver/rmt.h"

#include <WiFi.h>

// Define options required for application
#define ENABLE_WIFI_SUPPORT
#define ENABLE_NETWORK_SUPPORT
#define ENABLE_SPIFFS_SUPPORT // Always enable to use remember and startup:
// #define ENABLE_SD_MMC_SUPPORT
// #define ENABLE_SD_SUPPORT
// #define ENABLE_I2C_SUPPORT
#define ENABLE_SPI_SUPPORT
// #define ENABLE_FREERTOS_SUPPORT
#define ENABLE_WS2812_SUPPORT
// #define ENABLE_LEDC_SUPPORT
// #define ENABLE_TEMPSENSOR_SUPPORT
// #define ENABLE_HTTP_SUPPORT
// #define ENABLE_HTTPS_SUPPORT
#define ENABLE_INTERRUPTS_SUPPORT

// CAL NOTE: intptr_t is a 32 bit value and so is cell_t
typedef intptr_t cell_t;
typedef uintptr_t ucell_t;

#define Y(op, code) X(#op, id ## op, code)
#define NIP (--sp)
#define NIPn(n) (sp -= (n))
#define DROP (tos = *sp--)
#define DROPn(n) (NIPn(n-1), DROP)
#define DUP (*++sp = tos)
#define PUSH DUP; tos = (cell_t)
#define COMMA(n) *g_sys.heap++ = (n)
#define DOIMMEDIATE() (*g_sys.current)[-1] |= IMMEDIATE
#define UNSMUDGE() (*g_sys.current)[-1] &= ~SMUDGE
#define DOES(ip) **g_sys.current = (cell_t) ADDR_DODOES; (*g_sys.current)[1] = (cell_t) ip
#define PARK DUP; *++rp = (cell_t) sp; *++rp = (cell_t) ip

#ifndef SSMOD_FUNC
# if __SIZEOF_POINTER__ == 8
typedef __int128_t dcell_t;
# elif __SIZEOF_POINTER__ == 4 || defined(_M_IX86)
typedef int64_t dcell_t;
# else
#  error "unsupported cell size"
# endif
# define SSMOD_FUNC dcell_t d = (dcell_t) *sp * (dcell_t) sp[-1]; \
                    --sp; cell_t a = (cell_t) (d < 0 ? ~(~d / tos) : d / tos); \
                    *sp = (cell_t) (d - ((dcell_t) a) * tos); tos = a
#endif

#define OPCODE_LIST \
  X("0=", ZEQUAL, tos = !tos ? -1 : 0) \
  X("NOT", NOT, tos = !tos ? -1 : 0) \
  X("0<", ZLESS, tos = (tos|0) < 0 ? -1 : 0) \
  X("+", PLUS, tos += *sp--) \
  X("U/MOD", USMOD, w = *sp; *sp = (ucell_t) w % (ucell_t) tos; \
                    tos = (ucell_t) w / (ucell_t) tos) \
  X("*/MOD", SSMOD, SSMOD_FUNC) \
  Y(AND, tos &= *sp--) \
  Y(OR, tos |= *sp--) \
  Y(XOR, tos ^= *sp--) \
  Y(DUP, DUP) \
  Y(SWAP, w = tos; tos = *sp; *sp = w) \
  Y(OVER, DUP; tos = sp[-1]) \
  Y(DROP, DROP) \
  X("<<", SHIFTL, tos = (*sp-- << tos)) \
  X(">>", SHIFTR, tos = (*sp-- >> tos)) \
  X("@", AT, tos = *(cell_t *) tos) \
  X("C@", CAT, tos = *(uint8_t *) tos) \
  X("!", STORE, *(cell_t *) tos = *sp--; DROP) \
  X("C!", CSTORE, *(uint8_t *) tos = *sp--; DROP) \
  X("SP@", SPAT, DUP; tos = (cell_t) sp) \
  X("SP!", SPSTORE, sp = (cell_t *) tos; DROP) \
  X("RP@", RPAT, DUP; tos = (cell_t) rp) \
  X("RP!", RPSTORE, rp = (cell_t *) tos; DROP) \
  X(">R", TOR, *++rp = tos; DROP) \
  X("R>", FROMR, DUP; tos = *rp; --rp) \
  X("R@", RAT, DUP; tos = *rp) \
  Y(EXECUTE, w = tos; DROP; JMPW) \
  Y(BRANCH, ip = (cell_t *) *ip) \
  Y(0BRANCH, if (!tos) ip = (cell_t *) *ip; else ++ip; DROP) \
  Y(DONEXT, *rp = *rp - 1; if (~*rp) ip = (cell_t *) *ip; else (--rp, ++ip)) \
  Y(DOLIT, DUP; tos = *ip++) \
  Y(ALITERAL, COMMA(g_sys.DOLIT_XT); COMMA(tos); DROP) \
  Y(CELL, DUP; tos = sizeof(cell_t)) \
  Y(FIND, tos = find((const char *) *sp, tos); --sp) \
  Y(PARSE, DUP; tos = parse(tos, sp)) \
  X("S>NUMBER?", CONVERT, tos = convert((const char *) *sp, tos, g_sys.base, sp); \
                          if (!tos) --sp) \
  X("F>NUMBER?", FCONVERT, tos = fconvert((const char *) *sp, tos, fp); --sp) \
  Y(CREATE, DUP; DUP; tos = parse(32, sp); \
            create((const char *) *sp, tos, 0, ADDR_DOCREATE); \
            COMMA(0); DROPn(2)) \
  X("DOES>", DOES, DOES(ip); ip = (cell_t *) *rp; --rp) \
  Y(IMMEDIATE, DOIMMEDIATE()) \
  X("'SYS", SYS, DUP; tos = (cell_t) &g_sys) \
  Y(YIELD, PARK; return rp) \
  X(":", COLON, DUP; DUP; tos = parse(32, sp); \
                create((const char *) *sp, tos, SMUDGE, ADDR_DOCOLON); \
                g_sys.state = -1; --sp; DROP) \
  Y(EVALUATE1, DUP; float *tfp = fp; \
               sp = evaluate1(sp, &tfp); \
               fp = tfp; w = *sp--; DROP; if (w) JMPW) \
  Y(EXIT, ip = (cell_t *) *rp--) \
  X(";", SEMICOLON, UNSMUDGE(); COMMA(g_sys.DOEXIT_XT); g_sys.state = 0) \

#define SET tos = (cell_t)

#define n0 tos
#define n1 (*sp)
#define n2 sp[-1]
#define n3 sp[-2]
#define n4 sp[-3]
#define n5 sp[-4]
#define n6 sp[-5]
#define n7 sp[-6]
#define n8 sp[-7]
#define n9 sp[-8]
#define n10 sp[-9]

#define a0 ((void *) tos)
#define a1 (*(void **) &n1)
#define a2 (*(void **) &n2)
#define a3 (*(void **) &n3)
#define a4 (*(void **) &n4)
#define a5 (*(void **) &n5)
#define a6 (*(void **) &n6)

#define b0 ((uint8_t *) tos)
#define b1 (*(uint8_t **) &n1)
#define b2 (*(uint8_t **) &n2)
#define b3 (*(uint8_t **) &n3)
#define b4 (*(uint8_t **) &n4)
#define b5 (*(uint8_t **) &n5)
#define b6 (*(uint8_t **) &n6)

#define c0 ((char *) tos)
#define c1 (*(char **) &n1)
#define c2 (*(char **) &n2)
#define c3 (*(char **) &n3)
#define c4 (*(char **) &n4)
#define c5 (*(char **) &n5)
#define c6 (*(char **) &n6)


#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>

#if defined(ESP32)
# define HEAP_SIZE (100 * 1024)
# define STACK_SIZE 512
#elif defined(ESP8266)
# define HEAP_SIZE (40 * 1024)
# define STACK_SIZE 512
#else
# define HEAP_SIZE 2 * 1024
# define STACK_SIZE 32
#endif
#define INTERRUPT_STACK_CELLS 64

static IPAddress ToIP(cell_t ip) {
  return IPAddress(ip & 0xff, ((ip >> 8) & 0xff), ((ip >> 16) & 0xff), ((ip >> 24) & 0xff));
}

static cell_t FromIP(IPAddress ip) {
  cell_t ret = 0;
  ret = (ret << 8) | ip[3];
  ret = (ret << 8) | ip[2];
  ret = (ret << 8) | ip[1];
  ret = (ret << 8) | ip[0];
  return ret;
}

IPAddress hostIP;

#define PLATFORM_OPCODE_LIST \
  /* Floating Point Functions */ \
  Y(DOFLIT, *++fp = *(float *) ip++) \
  X("fp@", FPAT, DUP; tos = (cell_t) fp) \
  X("fp!", FPSTORE, fp = (float *) tos; DROP) \
  X("sf@", FAT, *++fp = *(float *) tos; DROP) \
  X("sf!", FSTORE, *(float *) tos = *fp--; DROP) \
  X("fdup", FDUP, fp[1] = *fp; ++fp) \
  X("fnip", FNIP, fp[-1] = *fp; --fp) \
  X("fdrop", FDROP, --fp) \
  X("fover", FOVER, fp[1] = fp[-1]; ++fp) \
  X("fswap", FSWAP, float ft = fp[-1]; fp[-1] = *fp; *fp = ft) \
  X("fnegate", FNEGATE, *fp = -*fp) \
  X("f0<", FZLESS, DUP; tos = *fp-- < 0.0f ? -1 : 0) \
  X("f0=", FZEQUAL, DUP; tos = *fp-- == 0.0f ? -1 : 0) \
  X("f+", FPLUS, fp[-1] += *fp; --fp) \
  X("f-", FMINUS, fp[-1] -= *fp; --fp) \
  X("f*", FSTAR, fp[-1] *= *fp; --fp) \
  X("f/", FSLASH, fp[-1] /= *fp; --fp) \
  X("1/f", FINVERSE, *fp = 1.0 / *fp) \
  X("s>f", STOF, *++fp = (float) tos; DROP) \
  X("f>s", FTOS, DUP; tos = (cell_t) *fp--) \
  /* Trig Functions */ \
  X("fdtorad", FDTORAD, *fp *= 0.01745329252) \
  X("fradtod", FRADTOD, *fp *= 57.295779513) \
  X("fsin", FSIN, *fp = sinf(*fp)) \
  X("fsinh", FSINH, *fp = sinhf(*fp)) \
  X("fasin", FASIN, *fp = asinf(*fp)) \
  X("fcos", FCOS, *fp = cosf(*fp)) \
  X("fcosh", FCOSH, *fp = coshf(*fp)) \
  X("facos", FACOS, *fp = acosf(*fp)) \
  X("ftan", FTAN, *fp = tanf(*fp)) \
  X("ftanh", FTANH, *fp = tanhf(*fp)) \
  X("fatan", FATAN, *fp = atanf(*fp)) \
  X("fatan2", FATAN2, fp[-1] = atan2f(fp[-1], *fp); --fp) \
  X("fabs", FABS, *fp = fabsf(*fp)) \
  X("ffloor", FFLOOR, *fp = floorf(*fp)) \
  X("fceil", FCEIL, *fp = ceilf(*fp)) \
  X("flog", FLOG, *fp = logf(*fp)) \
  X("flog10", FLOG10, *fp = log10f(*fp)) \
  X("fsqrt", FSQRT, *fp = sqrtf(*fp)) \
  X("fpow", FPOW, fp[-1] = powf(fp[-1], *fp); --fp) \
  /* Memory Allocation */ \
  Y(MALLOC, SET malloc(n0)) \
  Y(SYSFREE, free(a0); DROP) \
  Y(REALLOC, SET realloc(a1, n0); NIP) \
  Y(heap_caps_malloc, SET heap_caps_malloc(n1, n0); NIP) \
  Y(heap_caps_free, heap_caps_free(a0); DROP) \
  Y(heap_caps_realloc, \
      tos = (cell_t) heap_caps_realloc(a2, n1, n0); NIPn(2)) \
  /* Serial 0, 1 and 2 */ \
  /* Serial (Serial0) is used for programming; not for projects */ \
  X("Serial.begin", SERIAL_BEGIN, Serial.begin(tos); DROP) \
  X("Serial.end", SERIAL_END, Serial.end()) \
  X("Serial.available", SERIAL_AVAILABLE, PUSH Serial.available()) \
  X("Serial.readBytes", SERIAL_READ_BYTES, n0 = Serial.readBytes(b1, n0); NIP) \
  X("Serial.write", SERIAL_WRITE, n0 = Serial.write(n0)) \
  X("Serial.writeBuffer", SERIAL_WRITEB, n0 = Serial.write(b1, n0); NIP) \
  X("Serial.flush", SERIAL_FLUSH, Serial.flush()) \
  /* Serial1 is generally unused but is used on some boards for static flash access */ \
  X("Serial1.begin", SERIAL1_BEGIN, Serial1.begin(tos, SERIAL_8N1, 9, 10); DROP) \
  X("Serial1.end", SERIAL1_END, Serial1.end()) \
  X("Serial1.available", SERIAL1_AVAILABLE, PUSH Serial1.available()) \
  X("Serial1.readBytes", SERIAL1_READ_BYTES, n0 = Serial1.readBytes(b1, n0); NIP) \
  X("Serial1.write", SERIAL1_WRITE, n0 = Serial1.write(n0)) \
  X("Serial1.writeBuffer", SERIAL1_WRITEB, n0 = Serial1.write(b1, n0); NIP) \
  X("Serial1.flush", SERIAL1_FLUSH, Serial1.flush()) \
  /* Serial2 is unused and available for projects */ \
  X("Serial2.begin", SERIAL2_BEGIN, Serial2.begin(n0, n1, n2, n3); DROPn(4)) \
  X("Serial2.end", SERIAL2_END, Serial2.end()) \
  X("Serial2.available", SERIAL2_AVAILABLE, PUSH Serial2.available()) \
  X("Serial2.readBytes", SERIAL2_READ_BYTES, n0 = Serial2.readBytes(b1, n0); NIP) \
  X("Serial2.write", SERIAL2_WRITE, n0 = Serial2.write(n0)) \
  X("Serial2.writeBuffer", SERIAL2_WRITEB, n0 = Serial2.write(b1, n0); NIP) \
  X("Serial2.flush", SERIAL2_FLUSH, Serial2.flush()) \
  /* Random functions */ \
  X("randomSeed", RANDOM_SEED, randomSeed(time(NULL))) \
  X("rand", RAND, PUSH rand()) \
  X("random0toN", RANDOM_0N, n0 = (rand() % n0)) \
  X("randomNtoM", RANDOM_NM, int diff = n0 - n1; n0 = ((rand() % diff) + n1); NIP) \
  /* Pins and PWM */ \
  Y(pinMode, pinMode(n1, n0); DROPn(2)) \
  Y(digitalWrite, digitalWrite(n1, n0); DROPn(2)) \
  Y(digitalRead, n0 = digitalRead(n0)) \
  Y(analogRead, n0 = analogRead(n0)) \
  Y(pulseIn, n0 = pulseIn(n2, n1, n0); NIPn(2)) \
  Y(dacWrite, dacWrite(n1, n0); DROPn(2)) \
  /* General System */ \
  /* CAL memmove ( src dest n --- ) */ \
  X("memmove", MEMMOVE, memmove(a1, a2, n0); DROPn(3)) \
  X("MS-TICKS", MS_TICKS, PUSH millis()) \
  X("delay", MS_DELAY, delay(n0); DROP) \
  X("delayMicroseconds", MS_DELAY_US, delayMicroseconds(n0); DROP) \
  X("RAW-YIELD", RAW_YIELD, yield()) \
  Y(TERMINATE, exit(n0)) \
  /* File words */ \
  X("R/O", R_O, PUSH O_RDONLY) \
  X("R/W", R_W, PUSH O_RDWR) \
  X("W/O", W_O, PUSH O_WRONLY) \
  X("APPEND", APPEND, PUSH O_APPEND) \
  Y(BIN, ) \
  X("CLOSE-FILE", CLOSE_FILE, tos = close(tos); tos = tos ? errno : 0) \
  X("FLUSH-FILE", FLUSH_FILE, fsync(tos); /* fsync has no impl and returns ENOSYS :-( */ tos = 0) \
  X("OPEN-FILE", OPEN_FILE, cell_t mode = n0; DROP; cell_t len = n0; DROP; \
    memcpy(filename, a0, len); filename[len] = 0; \
    n0 = open(filename, mode, 0777); PUSH n0 < 0 ? errno : 0) \
  X("CREATE-FILE", CREATE_FILE, cell_t mode = n0; DROP; cell_t len = n0; DROP; \
    memcpy(filename, a0, len); filename[len] = 0; \
    n0 = open(filename, mode | O_CREAT | O_TRUNC); PUSH n0 < 0 ? errno : 0) \
  X("DELETE-FILE", DELETE_FILE, cell_t len = n0; DROP; \
    memcpy(filename, a0, len); filename[len] = 0; \
    n0 = unlink(filename); n0 = n0 ? errno : 0) \
  X("WRITE-FILE", WRITE_FILE, cell_t fd = n0; DROP; cell_t len = n0; DROP; \
    n0 = write(fd, a0, len); n0 = n0 != len ? errno : 0) \
  X("READ-FILE", READ_FILE, cell_t fd = n0; DROP; cell_t len = n0; DROP; \
    n0 = read(fd, a0, len); PUSH n0 < 0 ? errno : 0) \
  X("FILE-POSITION", FILE_POSITION, \
    n0 = (cell_t) lseek(n0, 0, SEEK_CUR); PUSH n0 < 0 ? errno : 0) \
  X("REPOSITION-FILE", REPOSITION_FILE, cell_t fd = n0; DROP; \
    n0 = (cell_t) lseek(fd, tos, SEEK_SET); n0 = n0 < 0 ? errno : 0) \
  X("RESIZE-FILE", RESIZE_FILE, cell_t fd = n0; DROP; n0 = ResizeFile(fd, tos)) \
  X("FILE-SIZE", FILE_SIZE, struct stat st; w = fstat(n0, &st); \
    n0 = (cell_t) st.st_size; PUSH w < 0 ? errno : 0) \
  X("z\"len", ZSTRINGLEN, n0 = strlen((const char *) n0)) \
  X("z\"cmp", ZSTRINGCMP, n0 = strcmp((const char *) n1, (const char *) n0); NIP) \
  X("z\"cpy", ZSTRINGCPY, strcpy((char *) n1, (const char *) n0); DROPn(2)) \
  X("z\"cat", ZSTRINGCAT, strcat((char *) n1, (const char *) n0); DROPn(2)) \
  X("Sleep.getCause", SLEEP_CAUSE, PUSH esp_sleep_get_wakeup_cause()) \
  X("Sleep.enableExt0Wakeup", SLEEP_EXT0_WAKEUP, esp_sleep_enable_ext0_wakeup((gpio_num_t) n1, n0); DROPn(2)) \
  X("Sleep.timerWakeupUS", SLEEP_TIMER_WAKEUP, esp_sleep_enable_timer_wakeup(n0); DROP) \
  X("Sleep.deepSleep", SLEEP_DEEP_SLEEP, esp_deep_sleep_start()) \
  OPTIONAL_WIFI_SUPPORT \
  OPTIONAL_NETWORK_SUPPORT \
  OPTIONAL_SPIFFS_SUPPORT \
  OPTIONAL_SD_MMC_SUPPORT \
  OPTIONAL_SD_SUPPORT \
  OPTIONAL_I2C_SUPPORT \
  OPTIONAL_SPI_SUPPORT \
  OPTIONAL_FREERTOS_SUPPORT \
  OPTIONAL_INTERRUPTS_SUPPORT \
  OPTIONAL_WS2812_SUPPORT \
  OPTIONAL_LEDC_SUPPORT \
  OPTIONAL_TEMPSENSOR_SUPPORT \
  OPTIONAL_HTTP_SUPPORT \
  OPTIONAL_HTTPS_SUPPORT

#ifndef ENABLE_HTTPS_SUPPORT
# define OPTIONAL_HTTPS_SUPPORT
#else

# include <HTTPClient.h>
# include <WiFiClientSecure.h>

  WiFiClientSecure client;
  HTTPClient https;
  
# define OPTIONAL_HTTPS_SUPPORT \
  X("HTTPS.setCert", HTTPS_SC, client.setCACert(c0); DROP) \
  X("HTTPS.begin", HTTPS_BEGIN, tos = https.begin(client, c0)) \
  X("HTTPS.doGet", HTTPS_DOGET, PUSH https.GET()) \
  X("HTTPS.getPayload", HTTPS_GETPL, String s = https.getString(); \
    memcpy((void *) n1, (void *) s.c_str(), n0); DROPn(2)) \
  X("HTTPS.end", HTTPS_END, https.end())
#endif

#ifndef ENABLE_HTTP_SUPPORT
# define OPTIONAL_HTTP_SUPPORT
#else

# include <HTTPClient.h>
  HTTPClient http;
  
# define OPTIONAL_HTTP_SUPPORT \
  X("HTTP.begin", HTTP_BEGIN, tos = http.begin(c0)) \
  X("HTTP.doGet", HTTP_DOGET, PUSH http.GET()) \
  X("HTTP.getPayload", HTTP_GETPL, String s = http.getString(); \
    memcpy((void *) n1, (void *) s.c_str(), n0); DROPn(2)) \
  X("HTTP.end", HTTP_END, http.end())
#endif

#ifndef ENABLE_WIFI_SUPPORT
# define OPTIONAL_WIFI_SUPPORT
#else
# define OPTIONAL_WIFI_SUPPORT \
  X("WiFi.config", WIFI_CONFIG, \
      WiFi.config(ToIP(n3), ToIP(n2), ToIP(n1), ToIP(n0)); DROPn(4)) \
  X("WiFi.begin", WIFI_BEGIN, WiFi.begin(c1, c0); DROPn(2)) \
  X("WiFi.disconnect", WIFI_DISCONNECT, WiFi.disconnect()) \
  X("WiFi.status", WIFI_STATUS, PUSH WiFi.status()) \
  X("WiFi.macAddress", WIFI_MAC_ADDRESS, WiFi.macAddress(b0); DROP) \
  X("WiFi.localIP", WIFI_LOCAL_IPS, PUSH FromIP(WiFi.localIP())) \
  X("WiFi.mode", WIFI_MODE, WiFi.mode((wifi_mode_t) n0); DROP) \
  X("WiFi.setTxPower", WIFI_SET_TX_POWER, WiFi.setTxPower((wifi_power_t) n0); DROP) \
  X("WiFi.getTxPower", WIFI_GET_TX_POWER, PUSH WiFi.getTxPower()) \
  X("WiFi.hostByName", WIFI_HOST_BY_NAME, n0 = WiFi.hostByName(c0, hostIP))
#endif

#ifndef ENABLE_NETWORK_SUPPORT
# define OPTIONAL_NETWORK_SUPPORT
#else
# define OPTIONAL_NETWORK_SUPPORT \
  X("Net.connect", NET_CONNECT, n0 = (cell_t) netConnect(n2, c1, n0); NIPn(2)) \
  X("Net.dispose", NET_DISPOSE, netDispose(n0); DROP) \
  X("Net.tcpWrite", NET_TCP_WRITE, n0 = tcpWrite(n2, (uint8_t *) n1, n0); NIPn(2)) \
  X("Net.udpSend", NET_UDP_SEND, n0 = udpSend(n2, (uint8_t *) n1, n0); NIPn(2)) \
  X("Net.receiveTimeoutMS!", NET_SET_REC_TIMEOUT, setReceiveTimeoutMS((forth_netconn *) n1, n0); DROPn(2)) \
  X("Net.readTimeoutMS!", NET_SET_READ_TIMEOUT, setReadTimeoutMS((forth_netconn *) n1, n0); DROPn(2)) \
  X("Net.read", NET_READ, n0 = netRead(n2, (uint8_t *) n1, n0); NIPn(2)) \
  X("Net.readLine", NET_READ_LINE, n0 = netReadLn(n2, (uint8_t *) n1, n0); NIPn(2)) \
  X("Net.tcpServer", NET_TCP_SERVER, n0 = (cell_t) netTCPServer(n0);) \
  X("Net.tcpServerAccept", NET_TCP_SERVER_ACCEPT, n0 = (cell_t) netTCPServerAccept(n0);)
#endif

#ifndef ENABLE_TEMPSENSOR_SUPPORT
# define OPTIONAL_TEMPSENSOR_SUPPORT
#else
# include <OneWire.h>
# include <DallasTemperature.h>

  OneWire oneWire;
  DallasTemperature sensors(&oneWire);
  
# define OPTIONAL_TEMPSENSOR_SUPPORT \
  X("TempSensor.begin", TEMPSENSOR_BEGIN, oneWire.begin(n0); sensors.begin(); DROP) \
  X("TempSensor.getTempC", TEMPSENSOR_TEMPC, sensors.requestTemperatures(); \
    cell_t t = round(sensors.getTempCByIndex(0)); PUSH t) \
  X("TempSensor.getTempF", TEMPSENSOR_TEMPF, sensors.requestTemperatures(); \
    cell_t t = round(sensors.getTempFByIndex(0)); PUSH t)
#endif

#ifndef ENABLE_LEDC_SUPPORT
# define OPTIONAL_LEDC_SUPPORT
#else
# define OPTIONAL_LEDC_SUPPORT \
  Y(ledcSetup, n0 = (cell_t) (1000000 * ledcSetup(n2, n1 / 1000.0, n0)); NIPn(2)) \
  Y(ledcAttachPin, ledcAttachPin(n1, n0); DROPn(2)) \
  Y(ledcDetachPin, ledcDetachPin(n0); DROP) \
  Y(ledcRead, n0 = ledcRead(n0)) \
  Y(ledcReadFreq, n0 = (cell_t) (1000000 * ledcReadFreq(n0))) \
  Y(ledcWrite, ledcWrite(n1, n0); DROPn(2)) \
  Y(ledcWriteTone, \
      n0 = (cell_t) (1000000 * ledcWriteTone(n1, n0 / 1000.0)); NIP) \
  Y(ledcWriteNote, \
      tos = (cell_t) (1000000 * ledcWriteNote(n2, (note_t) n1, n0)); NIPn(2))
#endif

#ifndef ENABLE_WS2812_SUPPORT
# define OPTIONAL_WS2812_SUPPORT
#else
# define OPTIONAL_WS2812_SUPPORT \
  X("WS2812.begin", INIT_WS2812_DRIVER, initWS2812Driver(n0); DROP) \
  X("WS2812.show", SHOW_WS2812_PIXELS, showPixels(b1, n0); DROPn(2))
#endif

#ifndef ENABLE_SPIFFS_SUPPORT
// Provide a default failing SPIFFS.begin
# define OPTIONAL_SPIFFS_SUPPORT \
  X("SPIFFS.begin", SPIFFS_BEGIN, NIPn(2); n0 = 0)
#else
# include "SPIFFS.h"
// SPIFFS.begin ( formatOnFail s"/spiffs" numOfOpenFiles -- f )
# define OPTIONAL_SPIFFS_SUPPORT \
  X("SPIFFS.begin", SPIFFS_BEGIN, \
      tos = SPIFFS.begin(n2, c1, n0); NIPn(2)) \
  X("SPIFFS.end", SPIFFS_END, SPIFFS.end()) \
  X("SPIFFS.format", SPIFFS_FORMAT, PUSH SPIFFS.format()) \
  X("SPIFFS.totalBytes", SPIFFS_TOTAL_BYTES, PUSH SPIFFS.totalBytes()) \
  X("SPIFFS.usedBytes", SPIFFS_USED_BYTES, PUSH SPIFFS.usedBytes())
#endif

#ifndef ENABLE_FREERTOS_SUPPORT
# define OPTIONAL_FREERTOS_SUPPORT
#else
# include "freertos/FreeRTOS.h"
# include "freertos/task.h"
# define OPTIONAL_FREERTOS_SUPPORT \
  Y(vTaskDelete, vTaskDelete((TaskHandle_t) n0); DROP) \
  Y(xTaskCreatePinnedToCore, n0 = xTaskCreatePinnedToCore((TaskFunction_t) a6, c5, n4, a3, (UBaseType_t) n2, (TaskHandle_t *) a1, (BaseType_t) n0); NIPn(6)) \
  Y(xPortGetCoreID, PUSH xPortGetCoreID())
#endif

#ifndef ENABLE_INTERRUPTS_SUPPORT
# define OPTIONAL_INTERRUPTS_SUPPORT
#else
# include "esp_intr_alloc.h"
# include "driver/timer.h"
# include "driver/gpio.h"
# define OPTIONAL_INTERRUPTS_SUPPORT \
  Y(gpio_config, n0 = gpio_config((const gpio_config_t *) a0)) \
  Y(gpio_reset_pin, n0 = gpio_reset_pin((gpio_num_t) n0)) \
  Y(gpio_set_intr_type, n0 = gpio_set_intr_type((gpio_num_t) n1, (gpio_int_type_t) n0); NIP) \
  Y(gpio_intr_enable, n0 = gpio_intr_enable((gpio_num_t) n0)) \
  Y(gpio_intr_disable, n0 = gpio_intr_disable((gpio_num_t) n0)) \
  Y(gpio_set_level, n0 = gpio_set_level((gpio_num_t) n1, n0); NIP) \
  Y(gpio_get_level, n0 = gpio_get_level((gpio_num_t) n0)) \
  Y(gpio_set_direction, n0 = gpio_set_direction((gpio_num_t) n1, (gpio_mode_t) n0); NIP) \
  Y(gpio_set_pull_mode, n0 = gpio_set_pull_mode((gpio_num_t) n1, (gpio_pull_mode_t) n0); NIP) \
  Y(gpio_wakeup_enable, n0 = gpio_wakeup_enable((gpio_num_t) n1, (gpio_int_type_t) n0); NIP) \
  Y(gpio_wakeup_disable, n0 = gpio_wakeup_disable((gpio_num_t) n0)) \
  Y(gpio_pullup_en, n0 = gpio_pullup_en((gpio_num_t) n0)) \
  Y(gpio_pullup_dis, n0 = gpio_pullup_dis((gpio_num_t) n0)) \
  Y(gpio_pulldown_en, n0 = gpio_pulldown_en((gpio_num_t) n0)) \
  Y(gpio_pulldown_dis, n0 = gpio_pulldown_dis((gpio_num_t) n0)) \
  Y(gpio_hold_en, n0 = gpio_hold_en((gpio_num_t) n0)) \
  Y(gpio_hold_dis, n0 = gpio_hold_dis((gpio_num_t) n0)) \
  Y(gpio_deep_sleep_hold_en, gpio_deep_sleep_hold_en()) \
  Y(gpio_deep_sleep_hold_dis, gpio_deep_sleep_hold_dis()) \
  Y(gpio_install_isr_service, n0 = gpio_install_isr_service(n0)) \
  Y(gpio_uninstall_isr_service, gpio_uninstall_isr_service()) \
  Y(gpio_isr_handler_add, n0 = GpioIsrHandlerAdd(n2, n1, n0); NIPn(2)) \
  Y(gpio_isr_handler_remove, n0 = gpio_isr_handler_remove((gpio_num_t) n0)) \
  Y(gpio_set_drive_capability, n0 = gpio_set_drive_capability((gpio_num_t) n1, (gpio_drive_cap_t) n0); NIP) \
  Y(gpio_get_drive_capability, n0 = gpio_get_drive_capability((gpio_num_t) n1, (gpio_drive_cap_t *) a0); NIP) \
  Y(esp_intr_alloc, n0 = EspIntrAlloc(n4, n3, n2, n1, a0); NIPn(4)) \
  Y(esp_intr_free, n0 = esp_intr_free((intr_handle_t) n0)) \
  Y(timer_isr_register, n0 = TimerIsrRegister(n5, n4, n3, n2, n1, a0); NIPn(5))
#endif

#ifndef ENABLE_SD_MMC_SUPPORT
# define OPTIONAL_SD_MMC_SUPPORT
#else
# include "SD_MMC.h"
# define OPTIONAL_SD_MMC_SUPPORT \
  X("SD_MMC.begin", SD_MMC_BEGIN, tos = SD_MMC.begin(c1, n0); NIP) \
  X("SD_MMC.end", SD_MMC_END, SD_MMC.end()) \
  X("SD_MMC.cardType", SD_MMC_CARD_TYPE, PUSH SD_MMC.cardType()) \
  X("SD_MMC.totalBytes", SD_MMC_TOTAL_BYTES, PUSH SD_MMC.totalBytes()) \
  X("SD_MMC.usedBytes", SD_MMC_USED_BYTES, PUSH SD_MMC.usedBytes())
#endif

#ifndef ENABLE_SD_SUPPORT
# define OPTIONAL_SD_SUPPORT
#else
# include "SD.h"
// SD can use either the HSPI or the VSPI interface
// Below is the signature for initializing the SD interface
// Stack should be configured this way before SD.begin_* is called
// ( SD_CLK SD_MISO SD_MOSI SD_CS SD_FREQ NUM_OPEN_FILES -- f)
# define OPTIONAL_SD_SUPPORT \
  X("SD.begin_hSPI", SD_BEGIN_HSPI, hSPI.begin(n5, n4, n3, n2); \
      tos = SD.begin(n2, hSPI, n1, "/sdcard", n0); NIPn(5)) \
  X("SD.begin_vSPI", SD_BEGIN_VSPI, vSPI.begin(n5, n4, n3, n2); \
      tos = SD.begin(n2, vSPI, n1, "/sdcard", n0); NIPn(5)) \
  X("SD.end", SD_END, SD.end()) \
  X("SD.cardType",   SD_CARD_TYPE,   PUSH SD.cardType()) \
  X("SD.totalBytes", SD_TOTAL_BYTES, PUSH SD.totalBytes()) \
  X("SD.usedBytes",  SD_USED_BYTES,  PUSH SD.usedBytes())
#endif

#ifndef ENABLE_I2C_SUPPORT
# define OPTIONAL_I2C_SUPPORT
#else
# include <Wire.h>
# define OPTIONAL_I2C_SUPPORT \
  X("Wire.begin", WIRE_BEGIN, n0 = Wire.begin(n1, n0); NIP) \
  X("Wire.setClock", WIRE_SET_CLOCK, Wire.setClock(n0); DROP) \
  X("Wire.getClock", WIRE_GET_CLOCK, PUSH Wire.getClock()) \
  X("Wire.setTimeout", WIRE_SET_TIMEOUT, Wire.setTimeout(n0); DROP) \
  X("Wire.getTimeout", WIRE_GET_TIMEOUT, PUSH Wire.getTimeout()) \
  X("Wire.beginTransmission", WIRE_BEGIN_TRANSMISSION, Wire.beginTransmission(n0); DROP) \
  X("Wire.endTransmission", WIRE_END_TRANSMISSION, n0 = Wire.endTransmission(n0)) \
  X("Wire.requestFrom", WIRE_REQUEST_FROM, n0 = Wire.requestFrom(n2, n1, n0); NIPn(2)) \
  X("Wire.write", WIRE_WRITE, n0 = Wire.write(n0)) \
  X("Wire.available", WIRE_AVAILABLE, PUSH Wire.available()) \
  X("Wire.read", WIRE_READ, PUSH Wire.read()) \
  X("Wire.peek", WIRE_PEEK, PUSH Wire.peek()) \
  X("Wire.flush", WIRE_FLUSH, Wire.flush())
#endif

#ifndef ENABLE_SPI_SUPPORT
# define OPTIONAL_SPI_SUPPORT
#else
# include "SPIIntfc.h"
# define OPTIONAL_SPI_SUPPORT \
  X("VSPI.begin", VSPI_BEGIN, vSPI.begin((int8_t) n3, (int8_t) n2, (int8_t) n1, (int8_t) n0); DROPn(4)) \
  X("VSPI.end", VSPI_END, vSPI.end();) \
  X("VSPI.setHwCs", VSPI_SETHWCS, vSPI.setHwCs((boolean) n0); DROP) \
  X("VSPI.setBitOrder", VSPI_SETBITORDER, vSPI.setBitOrder((uint8_t) n0); DROP) \
  X("VSPI.setDataMode", VSPI_SETDATAMODE, vSPI.setDataMode((uint8_t) n0); DROP) \
  X("VSPI.setFrequency", VSPI_SETFREQUENCY, vSPI.setFrequency((uint32_t) n0); DROP) \
  X("VSPI.setClockDivider", VSPI_SETCLOCKDIVIDER, vSPI.setClockDivider((uint32_t) n0); DROP) \
  X("VSPI.getClockDivider", VSPI_GETCLOCKDIVIDER, PUSH vSPI.getClockDivider();) \
  X("VSPI.transfer",   VSPI_TRANSFER, vSPI.transfer((uint8_t *) n1, (uint32_t) n0); DROPn(2)) \
  X("VSPI.transfer8",  VSPI_TRANSFER_8,  PUSH (uint8_t)  vSPI.transfer((uint8_t) n0); NIP) \
  X("VSPI.transfer16", VSPI_TRANSFER_16, PUSH (uint16_t) vSPI.transfer16((uint16_t) n0); NIP) \
  X("VSPI.transfer32", VSPI_TRANSFER_32, PUSH (uint32_t) vSPI.transfer32((uint32_t) n0); NIP) \
  X("VSPI.transferBytes", VSPI_TRANSFER_BYTES, vSPI.transferBytes((const uint8_t *) n2, (uint8_t *) n1, (uint32_t) n0); DROPn(3)) \
  X("VSPI.transferBits", VSPI_TRANSFER_BITES, vSPI.transferBits((uint32_t) n2, (uint32_t *) n1, (uint8_t) n0); DROPn(3)) \
  X("VSPI.write", VSPI_WRITE, vSPI.write((uint8_t) n0); DROP) \
  X("VSPI.write16", VSPI_WRITE16, vSPI.write16((uint16_t) n0); DROP) \
  X("VSPI.write32", VSPI_WRITE32, vSPI.write32((uint32_t) n0); DROP) \
  X("VSPI.writeBytes", VSPI_WRITE_BYTES, vSPI.writeBytes((const uint8_t *) n1, (uint32_t) n0); DROPn(2)) \
  X("VSPI.writePixels", VSPI_WRITE_PIXELS, vSPI.writePixels((const void *) n1, (uint32_t) n0); DROPn(2)) \
  X("VSPI.writePattern", VSPI_WRITE_PATTERN, vSPI.writePattern((const uint8_t *) n2, (uint8_t) n1, (uint32_t) n0); DROPn(3)) \
  X("HSPI.begin", HSPI_BEGIN, hSPI.begin((int8_t) n3, (int8_t) n2, (int8_t) n1, (int8_t) n0); DROPn(4)) \
  X("HSPI.end", HSPI_END, hSPI.end();) \
  X("HSPI.setHwCs", HSPI_SETHWCS, hSPI.setHwCs((boolean) n0); DROP) \
  X("HSPI.setBitOrder", HSPI_SETBITORDER, hSPI.setBitOrder((uint8_t) n0); DROP) \
  X("HSPI.setDataMode", HSPI_SETDATAMODE, hSPI.setDataMode((uint8_t) n0); DROP) \
  X("HSPI.setFrequency", HSPI_SETFREQUENCY, hSPI.setFrequency((uint32_t) n0); DROP) \
  X("HSPI.setClockDivider", HSPI_SETCLOCKDIVIDER, hSPI.setClockDivider((uint32_t) n0); DROP) \
  X("HSPI.getClockDivider", HSPI_GETCLOCKDIVIDER, PUSH hSPI.getClockDivider();) \
  X("HSPI.transfer",   HSPI_TRANSFER, hSPI.transfer((uint8_t *) n1, (uint32_t) n0); DROPn(2)) \
  X("HSPI.transfer8",  HSPI_TRANSFER_8,  PUSH (uint8_t)  hSPI.transfer((uint8_t) n0); NIP) \
  X("HSPI.transfer16", HSPI_TRANSFER_16, PUSH (uint16_t) hSPI.transfer16((uint16_t) n0); NIP) \
  X("HSPI.transfer32", HSPI_TRANSFER_32, PUSH (uint32_t) hSPI.transfer32((uint32_t) n0); NIP) \
  X("HSPI.transferBytes", HSPI_TRANSFER_BYTES, hSPI.transferBytes((const uint8_t *) n2, (uint8_t *) n1, (uint32_t) n0); DROPn(3)) \
  X("HSPI.transferBits", HSPI_TRANSFER_BITES, hSPI.transferBits((uint32_t) n2, (uint32_t *) n1, (uint8_t) n0); DROPn(3)) \
  X("HSPI.write", HSPI_WRITE, hSPI.write((uint8_t) n0); DROP) \
  X("HSPI.write16", HSPI_WRITE16, hSPI.write16((uint16_t) n0); DROP) \
  X("HSPI.write32", HSPI_WRITE32, hSPI.write32((uint32_t) n0); DROP) \
  X("HSPI.writeBytes", HSPI_WRITE_BYTES, hSPI.writeBytes((const uint8_t *) n1, (uint32_t) n0); DROPn(2)) \
  X("HSPI.writePixels", HSPI_WRITE_PIXELS, hSPI.writePixels((const void *) n1, (uint32_t) n0); DROPn(2)) \
  X("HSPI.writePattern", HSPI_WRITE_PATTERN, hSPI.writePattern((const uint8_t *) n2, (uint8_t) n1, (uint32_t) n0); DROPn(3))
#endif

static char filename[PATH_MAX];
static String string_value;

static cell_t EspIntrAlloc(cell_t source, cell_t flags, cell_t xt, cell_t arg, cell_t *ret);
static cell_t GpioIsrHandlerAdd(cell_t pin, cell_t xt, cell_t arg);
static cell_t TimerIsrRegister(cell_t group, cell_t timer, cell_t xt, cell_t arg, void *ret);

#define PRINT_ERRORS 0

#define CELL_MASK (sizeof(cell_t) - 1)
#define CELL_LEN(n) (((n) + CELL_MASK) / sizeof(cell_t))
#define FIND(name) find(name, sizeof(name) - 1)
#define UPPER(ch) (((ch) >= 'a' && (ch) <= 'z') ? ((ch) & 0x5F) : (ch))
#define CELL_ALIGNED(a) (((cell_t) (a) + CELL_MASK) & ~CELL_MASK)
#define IMMEDIATE 1
#define SMUDGE 2
#define VOCABULARY_DEPTH 16

#if PRINT_ERRORS
#include <unistd.h>
#endif

static struct {
  const char *tib;
  cell_t ntib, tin, state, base;
  cell_t *heap, **current, ***context, notfound;
  int argc;
  char **argv;
  cell_t *(*runner)(cell_t *rp);  // pointer to forth_run
  cell_t *rp;  // spot to park main thread
  cell_t DOLIT_XT, DOFLIT_XT, DOEXIT_XT, YIELD_XT;
} g_sys;

static cell_t convert(const char *pos, cell_t n, cell_t base, cell_t *ret) {
  *ret = 0;
  cell_t negate = 0;
  if (!n) { return 0; }
  if (*pos == '-') { negate = -1; ++pos; --n; }
  if (*pos == '$') { base = 16; ++pos; --n; }
  for (; n; --n) {
    uintptr_t d = UPPER(*pos) - '0';
    if (d > 9) {
      d -= 7;
      if (d < 10) { return 0; }
    }
    if (d >= base) { return 0; }
    *ret = *ret * base + d;
    ++pos;
  }
  if (negate) { *ret = -*ret; }
  return -1;
}

static cell_t fconvert(const char *pos, cell_t n, float *ret) {
  *ret = 0;
  cell_t negate = 0;
  cell_t has_dot = 0;
  cell_t exp = 0;
  float shift = 1.0;
  if (!n) { return 0; }
  if (*pos == '-') { negate = -1; ++pos; --n; }
  for (; n; --n) {
    if (*pos >= '0' && *pos <= '9') {
      if (has_dot) {
        shift = shift * 0.1f;
        *ret = *ret + (*pos - '0') * shift;
      } else {
        *ret = *ret * 10 + (*pos - '0');
      }
    } else if (*pos == 'e' || *pos == 'E') {
      break;
    } else if (*pos == '.') {
      if (has_dot) { return 0; }
      has_dot = -1;
    }
    ++pos;
  }
  if (!n) { return 0; }  // must have E
  ++pos; --n;
  if (n) {
    if (!convert(pos, n, 10, &exp)) { return 0; }
  }
  if (exp < -128 || exp > 128) { return 0; }
  for (;exp < 0; ++exp) { *ret *= 0.1f; }
  for (;exp > 0; --exp) { *ret *= 10.0f; }
  if (negate) { *ret = -*ret; }
  return -1;
}

static cell_t same(const char *a, const char *b, cell_t len) {
  for (;len && UPPER(*a) == UPPER(*b); --len, ++a, ++b);
  return len == 0;
}

static cell_t find(const char *name, cell_t len) {
  for (cell_t ***voc = g_sys.context; *voc; ++voc) {
    cell_t *pos = **voc;
    cell_t clen = CELL_LEN(len);
    while (pos) {
      if (!(pos[-1] & SMUDGE) && len == pos[-3] &&
          same(name, (const char *) &pos[-3 - clen], len)) {
        return (cell_t) pos;
      }
      pos = (cell_t *) pos[-2];  // Follow link
    }
  }
  return 0;
}

static void create(const char *name, cell_t length, cell_t flags, void *op) {
  g_sys.heap = (cell_t *) CELL_ALIGNED(g_sys.heap);
  char *pos = (char *) g_sys.heap;
  for (cell_t n = length; n; --n) { *pos++ = *name++; }  // name
  g_sys.heap += CELL_LEN(length);
  *g_sys.heap++ = length;  // length
  *g_sys.heap++ = (cell_t) *g_sys.current;  // link
  *g_sys.heap++ = flags;  // flags
  *g_sys.current = g_sys.heap;
  *g_sys.heap++ = (cell_t) op;  // code
}

static int match(char sep, char ch) {
  return sep == ch || (sep == ' ' && (ch == '\t' || ch == '\n' || ch == '\r'));
}

static cell_t parse(cell_t sep, cell_t *ret) {
  while (g_sys.tin < g_sys.ntib &&
         match(sep, g_sys.tib[g_sys.tin])) { ++g_sys.tin; }
  *ret = (cell_t) (g_sys.tib + g_sys.tin);
  while (g_sys.tin < g_sys.ntib &&
         !match(sep, g_sys.tib[g_sys.tin])) { ++g_sys.tin; }
  cell_t len = g_sys.tin - (*ret - (cell_t) g_sys.tib);
  if (g_sys.tin < g_sys.ntib) { ++g_sys.tin; }
  return len;
}

static cell_t *evaluate1(cell_t *sp, float **fp) {
  cell_t call = 0;
  cell_t name;
  cell_t len = parse(' ', &name);
  if (len == 0) { *++sp = 0; return sp; }  // ignore empty
  cell_t xt = find((const char *) name, len);
  if (xt) {
    if (g_sys.state && !(((cell_t *) xt)[-1] & IMMEDIATE)) {
      *g_sys.heap++ = xt;
    } else {
      call = xt;
    }
  } else {
    cell_t n;
    if (convert((const char *) name, len, g_sys.base, &n)) {
      if (g_sys.state) {
        *g_sys.heap++ = g_sys.DOLIT_XT;
        *g_sys.heap++ = n;
      } else {
        *++sp = n;
      }
    } else {
      float f;
      if (fconvert((const char *) name, len, &f)) {
        if (g_sys.state) {
          *g_sys.heap++ = g_sys.DOFLIT_XT;
          *(float *) g_sys.heap++ = f;
        } else {
          *++(*fp) = f;
        }
      } else {
#if PRINT_ERRORS
        write(2, (void *) name, len);
        write(2, "\n", 1);
#endif
        *++sp = name;
        *++sp = len;
        *++sp = -1;
        call = g_sys.notfound;
      }
    }
  }
  *++sp = call;
  return sp;
}

static cell_t *forth_run(cell_t *initrp);

static void forth_init(int argc, char *argv[], void *heap,
                         const char *src, cell_t src_len) {
  g_sys.heap = ((cell_t *) heap) + 4;  // Leave a little room.
  cell_t *sp = g_sys.heap + 1; g_sys.heap += STACK_SIZE;
  cell_t *rp = g_sys.heap + 1; g_sys.heap += STACK_SIZE;
  float *fp = (float *) (g_sys.heap + 1); g_sys.heap += STACK_SIZE;

  // FORTH vocabulary
  *g_sys.heap++ = 0; cell_t *forth = g_sys.heap;
  *g_sys.heap++ = 0;  *g_sys.heap++ = 0;  *g_sys.heap++ = 0;
  // Vocabulary stack
  g_sys.current = (cell_t **) forth;
  g_sys.context = (cell_t ***) g_sys.heap;
  *g_sys.heap++ = (cell_t) forth;
  for (int i = 0; i < VOCABULARY_DEPTH; ++i) { *g_sys.heap++ = 0; }

  forth_run(0);
  (*g_sys.current)[-1] = IMMEDIATE;  // Make last word ; IMMEDIATE
  g_sys.DOLIT_XT = FIND("DOLIT");
  g_sys.DOFLIT_XT = FIND("DOFLIT");
  g_sys.DOEXIT_XT = FIND("EXIT");
  g_sys.YIELD_XT = FIND("YIELD");
  g_sys.notfound = FIND("DROP");
  cell_t *start = g_sys.heap;
  *g_sys.heap++ = FIND("EVALUATE1");
  *g_sys.heap++ = FIND("BRANCH");
  *g_sys.heap++ = (cell_t) start;
  g_sys.argc = argc;
  g_sys.argv = argv;
  g_sys.base = 10;
  g_sys.tib = src;
  g_sys.ntib = src_len;
  *++rp = (cell_t) sp;
  *++rp = (cell_t) fp;
  *++rp = (cell_t) start;
  g_sys.rp = rp;
  g_sys.runner = forth_run;
}

#define JMPW goto **(void **) w
#define NEXT w = *ip++; JMPW
#define ADDR_DOCOLON && OP_DOCOLON
#define ADDR_DOCREATE && OP_DOCREATE
#define ADDR_DODOES && OP_DODOES

static cell_t *forth_run(cell_t *init_rp) {
  if (!init_rp) {
#define X(name, op, code) create(name, sizeof(name) - 1, name[0] == ';', && OP_ ## op);
    PLATFORM_OPCODE_LIST
    OPCODE_LIST
#undef X
    return 0;
  }
  cell_t *ip, *rp, *sp, tos, w;
  float *fp;
  rp = init_rp;  ip = (cell_t *) *rp--;  sp = (cell_t *) *rp--;
  fp = (float *) *rp--;
  DROP; NEXT;
#define X(name, op, code) OP_ ## op: { code; } NEXT;
  PLATFORM_OPCODE_LIST
  OPCODE_LIST
#undef X
  OP_DOCOLON: ++rp; *rp = (cell_t) ip; ip = (cell_t *) (w + sizeof(cell_t)); NEXT;
  OP_DOCREATE: DUP; tos = w + sizeof(cell_t) * 2; NEXT;
  OP_DODOES: DUP; tos = w + sizeof(cell_t) * 2;
             ++rp; *rp = (cell_t) ip; ip = (cell_t *) *(cell_t *) (w + sizeof(cell_t)); NEXT;
}

const char boot[] =
": (   41 parse drop drop ; immediate\n"
": \\   10 parse drop drop ; immediate\n"
"\n"
"( Useful Basic Compound Words )\n"
": nip ( a b -- b ) swap drop ;\n"
": rdrop ( r: n n -- ) r> r> drop >r ;\n"
": */ ( n n n -- n ) */mod nip ;\n"
": * ( n n -- n ) 1 */ ;\n"
": /mod ( n n -- n n ) 1 swap */mod ;\n"
": / ( n n -- n ) /mod nip ;\n"
": mod ( n n -- n ) /mod drop ;\n"
": invert ( n -- ~n ) -1 xor ;\n"
": negate ( n -- -n ) invert 1 + ;\n"
": - ( n n -- n ) negate + ;\n"
": rot ( a b c -- b c a ) >r swap r> swap ;\n"
": -rot ( a b c -- c a b ) swap >r swap r> ;\n"
": < ( a b -- a<b ) - 0< ;\n"
": > ( a b -- a>b ) swap - 0< ;\n"
": <= ( a b -- a>b ) swap - 0< 0= ;\n"
": >= ( a b -- a<b ) - 0< 0= ;\n"
": = ( a b -- a!=b ) - 0= ;\n"
": <> ( a b -- a!=b ) = 0= ;\n"
": 0<> ( n -- n) 0= 0= ;\n"
": bl 32 ;   : nl 10 ;\n"
": 1+ 1 + ;   : 1- 1 - ;\n"
": 2* 2 * ;   : 2/ 2 / ;\n"
": 4* 4 * ;   : 4/ 4 / ;\n"
": +! ( n a -- ) swap over @ + swap ! ;\n"
"\n"
"( Cells )\n"
": cell+ ( n -- n ) cell + ;\n"
": cells ( n -- n ) cell * ;\n"
": cell/ ( n -- n ) cell / ;\n"
"\n"
"( Double Words )\n"
": 2drop ( n n -- ) drop drop ;\n"
": 2dup ( a b -- a b a b ) over over ;\n"
": 2@ ( a -- lo hi ) dup @ swap cell+ @ ;\n"
": 2! ( lo hi a -- ) dup >r cell+ ! r> ! ;\n"
"\n"
"( System Variables )\n"
": 'tib ( -- a ) 'sys 0 cells + ;\n"
": #tib ( -- a ) 'sys 1 cells + ;\n"
": >in ( -- a ) 'sys 2 cells + ;\n"
": state ( -- a ) 'sys 3 cells + ;\n"
": base ( -- a ) 'sys 4 cells + ;\n"
": 'heap ( -- a ) 'sys 5 cells + ;\n"
": current ( -- a ) 'sys 6 cells + ;\n"
": 'context ( -- a ) 'sys 7 cells + ;  : context 'context @ cell+ ;\n"
": 'notfound ( -- a ) 'sys 8 cells + ;\n"
"\n"
"( Dictionary )\n"
": here ( -- a ) 'heap @ ;\n"
": allot ( n -- ) 'heap +! ;\n"
": aligned ( a -- a ) cell 1 - dup >r + r> invert and ;\n"
": align   here aligned here - allot ;\n"
": , ( n --  ) here ! cell allot ;\n"
": c, ( ch -- ) here c! 1 allot ;\n"
"\n"
"( Compilation State )\n"
": [ 0 state ! ; immediate\n"
": ] -1 state ! ; immediate\n"
"\n"
"( Quoting Words )\n"
": ' bl parse 2dup find dup >r -rot r> 0= 'notfound @ execute 2drop ;\n"
": ['] ' aliteral ; immediate\n"
": char bl parse drop c@ ;\n"
": [char] char aliteral ; immediate\n"
": literal aliteral ; immediate\n"
"\n"
"( Core Control Flow )\n"
": begin   here ; immediate\n"
": again   ['] branch , , ; immediate\n"
": until   ['] 0branch , , ; immediate\n"
": ahead   ['] branch , here 0 , ; immediate\n"
": then   here swap ! ; immediate\n"
": if   ['] 0branch , here 0 , ; immediate\n"
": else   ['] branch , here 0 , swap here swap ! ; immediate\n"
": while   ['] 0branch , here 0 , swap ; immediate\n"
": repeat   ['] branch , , here swap ! ; immediate\n"
": aft   drop ['] branch , here 0 , here swap ; immediate\n"

" ( More Misc CAL words )\n"
": ?dup dup if dup then ;\n"
": between? ( n min-inc max-inc -- f ) rot >r r@ >= swap r> <= and ;\n"

"( Case support )\n"
": case 0 ; immediate\n"
": of ['] over , ['] = , ['] 0branch , here 0 , ['] drop , ; immediate\n"
": endof ['] branch , here 0 , swap here swap ! ; immediate\n"
": endcase ['] drop , begin ?dup while here swap ! repeat ; immediate\n"

"\n"
"( Recursion )\n"
": recurse current @ @ aliteral ['] execute , ; immediate\n"
"\n"
"( Compound words requiring conditionals )\n"
": min 2dup < if drop else nip then ;\n"
": max 2dup < if nip else drop then ;\n"
": abs ( n -- +n ) dup 0< if negate then ;\n"
"\n"
"( Dictionary Format )\n"
": >name ( xt -- a n ) 3 cells - dup @ swap over aligned - swap ;\n"
": >link& ( xt -- a ) 2 cells - ;   : >link ( xt -- a ) >link& @ ;\n"
": >flags ( xt -- flags ) cell - ;\n"
": >body ( xt -- a ) dup @ [ ' >flags @ ] literal = 2 + cells + ;\n"
"\n"
"( Postpone - done here so we have ['] and IF )\n"
": immediate? ( xt -- f ) >flags @ 1 and 0= 0= ;\n"
": postpone ' dup immediate? if , else aliteral ['] , , then ; immediate\n"
"\n"
"( Constants and Variables )\n"
": constant ( n \"name\" -- ) create , does> @ ;\n"
": variable ( \"name\" -- ) create 0 , ;\n"
"\n"
"( Stack Convience )\n"
"sp@ constant sp0\n"
"rp@ constant rp0\n"
"fp@ constant fp0\n"
": depth ( -- n ) sp@ sp0 - cell/ ;\n"
": fdepth ( -- n ) fp@ fp0 - 4 / ;\n"
"\n"
"( Rstack nest depth )\n"
"variable nest-depth\n"
"\n"
"( FOR..NEXT )\n"
": for   1 nest-depth +! postpone >r postpone begin ; immediate\n"
": next   -1 nest-depth +! postpone donext , ; immediate\n"
"\n"
"( DO..LOOP )\n"
"variable leaving\n"
": leaving,   here leaving @ , leaving ! ;\n"
": leaving(   leaving @ 0 leaving !   2 nest-depth +! ;\n"
": )leaving   leaving @ swap leaving !  -2 nest-depth +!\n"
"             begin dup while dup @ swap here swap ! repeat drop ;\n"

": (do) ( n n -- .. ) swap r> -rot >r >r >r ;\n"
": do ( lim s -- ) leaving( postpone (do) here ; immediate\n"
": (?do) ( n n -- n n f .. ) 2dup = if 2drop 0 else -1 then ;\n"
": ?do ( lim s -- ) leaving( postpone (?do) postpone 0branch leaving,\n"
"                   postpone (do) here ; immediate\n"
": unloop   postpone rdrop postpone rdrop ; immediate\n"
": leave   postpone unloop postpone branch leaving, ; immediate\n"
": (+loop) ( n -- f .. ) dup 0< swap r> r> rot + dup r@ < -rot >r >r xor 0= ;\n"
": +loop ( n -- ) postpone (+loop) postpone until\n"
"                 postpone unloop )leaving ; immediate\n"
": loop   1 aliteral postpone +loop ; immediate\n"
": i ( -- n ) postpone r@ ; immediate\n"
": j ( -- n ) rp@ 3 cells - @ ;\n"
": k ( -- n ) rp@ 5 cells - @ ;\n"
"\n"
"( Exceptions )\n"
"variable handler\n"
": catch ( xt -- n )\n"
"  fp@ >r sp@ >r handler @ >r rp@ handler ! execute\n"
"  r> handler ! rdrop rdrop 0 ;\n"
": throw ( n -- )\n"
"  dup if handler @ rp! r> handler !\n"
"         r> swap >r sp! drop r> r> fp! else drop then ;\n"
"' throw 'notfound !\n"
"\n"
"( Values )\n"
": value ( n -- ) create , does> @ ;\n"
": value-bind ( xt-val xt )\n"
"   >r >body state @ if aliteral r> , else r> execute then ;\n"
": to ( n -- ) ' ['] ! value-bind ; immediate\n"
": +to ( n -- ) ' ['] +! value-bind ; immediate\n"
"\n"
"( Deferred Words )\n"
": defer ( \"name\" -- ) create 0 , does> @ dup 0= throw execute ;\n"
": is ( xt \"name -- ) postpone to ; immediate\n"
"\n"
"( Defer I/O to platform specific )\n"
"defer type\n"
"defer key\n"
"defer key?\n"
"defer bye\n"
": emit ( n -- ) >r rp@ 1 type rdrop ;\n"
": space bl emit ;   : cr nl emit ;\n"
"\n"
"( Numeric Output )\n"
"variable hld\n"
": pad ( -- a ) here 80 + ;\n"
": digit ( u -- c ) 9 over < 7 and + 48 + ;\n"
": extract ( n base -- n c ) u/mod swap digit ;\n"
": <# ( -- ) pad hld ! ;\n"
": hold ( c -- ) hld @ 1 - dup hld ! c! ;\n"
": # ( u -- u ) base @ extract hold ;\n"
": #s ( u -- 0 ) begin # dup while repeat ;\n"
": sign ( n -- ) 0< if 45 hold then ;\n"
": #> ( w -- b u ) drop hld @ pad over - ;\n"
": str ( n -- b u ) dup >r abs <# #s r> sign #> ;\n"
": hex ( -- ) 16 base ! ;   : octal ( -- ) 8 base ! ;\n"
": decimal ( -- ) 10 base ! ;   : binary ( -- ) 2 base ! ;\n"
": u. ( u -- ) <# #s #> type space ;\n"
": . ( w -- ) base @ 10 xor if u. exit then str type space ;\n"
": ? ( a -- ) @ . ;\n"
": n. ( n -- ) base @ swap decimal <# #s #> type base ! ;\n"
"\n"
"( Strings )\n"
": parse-squote ( -- a n ) [char] ' parse ;\n"
": parse-quote ( -- a n ) [char] \" parse ;\n"
": $place ( a n -- ) for aft dup c@ c, 1+ then next drop ;\n"
": zplace ( a n -- ) $place 0 c, align ;\n"
": $@   r@ dup cell+ swap @ r> dup @ 1+ aligned + cell+ >r ;\n"
": s'   parse-squote state @ if postpone $@ dup , zplace\n"
"       else dup here swap >r >r zplace r> r> then ; immediate\n"
": s\"   parse-quote state @ if postpone $@ dup , zplace\n"
"       else dup here swap >r >r zplace r> r> then ; immediate\n"
": .\"   postpone s\" state @ if postpone type else type then ; immediate\n"
": z\"   postpone s\" state @ if postpone drop else drop then ; immediate\n"
": r\"   parse-quote state @ if swap aliteral aliteral then ; immediate\n"
": r|   [char] | parse state @ if swap aliteral aliteral then ; immediate\n"
": s>z ( a n -- z ) here >r zplace r> ;\n"
": z>s ( z -- a n ) 0 over begin dup c@ while 1+ swap 1+ swap repeat drop ;\n"
": z\". ( z -- ) z>s type ; \n"
"\n"
"( Fill, Move )\n"
": cmove ( a a n -- ) for aft >r dup c@ r@ c! 1+ r> 1+ then next 2drop ;\n"
": cmove> ( a a n -- ) for aft 2dup swap r@ + c@ swap r@ + c! then next 2drop ;\n"
": fill ( a n ch -- ) swap for swap aft 2dup c! 1 + then next 2drop ;\n"
": erase ( a n -- ) 0 fill ;\n"
"\n"
"( Better Errors )\n"
": notfound ( a n n -- )\n"
"   if cr .\" ERROR: \" type .\"  NOT FOUND!\" cr -1 throw then ;\n"
"' notfound 'notfound !\n"
"\n"
"( Input )\n"
": raw.s   depth 0 max for aft sp@ r@ cells - @ . then next ;\n"
"variable echo -1 echo !   variable arrow -1 arrow !\n"
": ?echo ( n -- ) echo @ if emit else drop then ;\n"
": ?arrow.   arrow @ if >r >r raw.s r> r> .\" --> \" then ;\n"
": accept ( a n -- n ) ?arrow. 0 swap begin 2dup < while\n"
"     key\n"
"     dup nl = over 13 = or if ?echo drop nip exit then\n"
"     dup 8 = over 127 = or if\n"
"       drop over if rot 1- rot 1- rot 8 ?echo bl ?echo 8 ?echo then\n"
"     else\n"
"       dup ?echo\n"
"       >r rot r> over c! 1+ -rot swap 1+ swap\n"
"     then\n"
"   repeat drop nip\n"
"   ( Eat rest of the line if buffer too small )\n"
"   begin key dup nl = over 13 = or if ?echo exit else drop then again\n"
";\n"
"200 constant input-limit\n"
": tib ( -- a ) 'tib @ ;\n"
"create input-buffer   input-limit allot\n"
": tib-setup   input-buffer 'tib ! ;\n"
": refill   tib-setup tib input-limit accept #tib ! 0 >in ! -1 ;\n"
"\n"
"( REPL )\n"
": prompt   .\"  ok\" cr ;\n"
": evaluate-buffer   begin >in @ #tib @ < while evaluate1 repeat ;\n"
": evaluate ( a n -- ) 'tib @ >r #tib @ >r >in @ >r\n"
"                      #tib ! 'tib ! 0 >in ! evaluate-buffer\n"
"                      r> >in ! r> #tib ! r> 'tib ! ;\n"
": quit    begin ['] evaluate-buffer catch\n"
"          if 0 state ! sp0 sp! fp0 fp! rp0 rp! .\" ERROR\" cr then\n"
"          prompt refill drop again ;\n"
"( Interpret time conditionals )\n"
"\n"
": DEFINED? ( \"name\" -- xt|0 )\n"
"   bl parse find state @ if aliteral then ; immediate\n"
"defer [SKIP]\n"
": [THEN] ;  immediate\n"
": [ELSE] [SKIP] ; immediate\n"
": [IF] 0= if [SKIP] then ; immediate\n"
": [SKIP]' 0 begin postpone defined? dup if\n"
"    dup ['] [IF] = if swap 1+ swap then\n"
"    dup ['] [ELSE] = if swap dup 0 <= if 2drop exit then swap then\n"
"    dup ['] [THEN] = if swap 1- dup 0< if 2drop exit then swap then\n"
"  then drop again ;\n"
"' [SKIP]' is [SKIP]\n"
"( Implement Vocabularies )\n"
"variable last-vocabulary\n"
"current @ constant forth-wordlist\n"
": forth   forth-wordlist context ! ;\n"
": vocabulary ( \"name\" ) create 0 , current @ 2 cells + , current @ @ last-vocabulary !\n"
"                        does> cell+ context ! ;\n"
": definitions   context @ current ! ;\n"
"\n"
"( Make it easy to transfer words between vocabularies )\n"
": xt-find& ( xt -- xt& ) context @ begin 2dup @ <> while @ >link& repeat nip ;\n"
": xt-hide ( xt -- ) xt-find& dup @ >link swap ! ;\n"
": xt-transfer ( xt --  ) dup xt-hide   current @ @ over >link& !   current @ ! ;\n"
": transfer ( \"name\" ) ' xt-transfer ;\n"
": }transfer ;\n"
": transfer{ begin ' dup ['] }transfer = if drop exit then xt-transfer again ;\n"
"\n"
"( Watered down versions of these )\n"
": only   forth 0 context cell+ ! ;\n"
": voc-stack-end ( -- a ) context begin dup @ while cell+ repeat ;\n"
": also   context context cell+ voc-stack-end over - 2 cells + cmove> ;\n"
": sealed   0 last-vocabulary @ >body cell+ ! ;\n"
"\n"
"( Hide some words in an Internals vocabulary )\n"
"vocabulary Internals   Internals definitions\n"
"\n"
"( Vocabulary chain for current scope, place at the -1 position )\n"
"variable scope   scope context cell - !\n"
"\n"
"transfer{\n"
"  xt-find& xt-hide xt-transfer\n"
"  voc-stack-end forth-wordlist\n"
"  last-vocabulary\n"
"  branch 0branch donext dolit\n"
"  'context 'notfound notfound\n"
"  immediate? input-buffer ?echo ?arrow. arrow\n"
"  evaluate1 evaluate-buffer\n"
"  'sys 'heap aliteral\n"
"  leaving( )leaving leaving leaving,\n"
"  (do) (?do) (+loop)\n"
"  parse-quote digit $@ raw.s\n"
"  tib-setup input-limit\n"
"  [SKIP] [SKIP]'\n"
"}transfer\n"
"forth definitions\n"
"\n"
"( Make DOES> switch to compile mode when interpreted )\n"
"(\n"
"forth definitions Internals\n"
"' does>\n"
": does>   state @ if postpone does> exit then\n"
"          ['] constant @ current @ @ dup >r !\n"
"          here r> cell+ ! postpone ] ; immediate\n"
"xt-hide\n"
"forth definitions\n"
")\n"
"( Cooperative Tasks )\n"
"\n"
"vocabulary tasks   tasks definitions\n"
"\n"
"variable task-list\n"
"\n"
"forth definitions tasks also Internals\n"
"\n"
": pause\n"
"  rp@ sp@ task-list @ cell+ !\n"
"  task-list @ @ task-list !\n"
"  task-list @ cell+ @ sp! rp!\n"
";\n"
"\n"
": task ( xt dsz rsz \"name\" )\n"
"   create here >r 0 , 0 , ( link, sp )\n"
"   swap here cell+ r@ cell+ ! cells allot\n"
"   here r@ cell+ @ ! cells allot\n"
"   dup 0= if drop else\n"
"     here r@ cell+ @ @ ! ( set rp to point here )\n"
"     , postpone pause ['] branch , here 3 cells - ,\n"
"   then rdrop ;\n"
"\n"
": start-task ( t -- )\n"
"   task-list @ if\n"
"     task-list @ @ over !\n"
"     task-list @ !\n"
"   else\n"
"     dup task-list !\n"
"     dup !\n"
"   then\n"
";\n"
"\n"
"DEFINED? ms-ticks [IF]\n"
"  : ms ( n -- ) ms-ticks >r begin pause ms-ticks r@ - over >= until rdrop drop ;\n"
"[THEN]\n"
"\n"
"tasks definitions\n"
"0 0 0 task main-task   main-task start-task\n"
"forth definitions\n"
"( Add a yielding task so pause yields )\n"
"Internals definitions\n"
"transfer{ yield raw-yield }transfer\n"
"' raw-yield 100 100 task yield-task\n"
"yield-task start-task\n"
"forth definitions\n"
"\n"
"( Set up Basic I/O )\n"
"Internals definitions\n"
": esp32-bye   0 terminate ;\n"
"' esp32-bye is bye\n"
": serial-type ( a n -- ) Serial.writeBuffer drop ;\n"
"' serial-type is type\n"
": serial-key ( -- n )\n"
"   begin pause Serial.available until 0 >r rp@ 1 Serial.readBytes drop r> ;\n"
"' serial-key is key\n"
": serial-key? ( -- n ) Serial.available ;\n"
"' serial-key? is key?\n"
"forth definitions\n"
"\n"
"( Map Arduino / ESP32 things to shorter names. )\n"
": pin ( n pin# -- ) swap digitalWrite ;\n"
": adc ( n -- n ) analogRead ;\n"

#ifdef ENABLE_LEDC_SUPPORT

": duty ( n n -- ) 255 min 8191 255 */ ledcWrite ;\n"
": freq ( n n -- ) 1000 * 13 ledcSetup drop ;\n"
": tone ( n n -- ) 1000 * ledcWriteTone drop ;\n"

#endif

"\n"
"0 constant LOW\n"
"1 constant HIGH\n"
"2 constant OUTPUT\n"
"1 constant INPUT\n"
"4 constant PULLUP\n"
"5 constant INPUT_PULLUP\n"
"9 constant INPUT_PULLDOWN\n"
"-1 constant TRUE\n"
"0 constant FALSE\n"
"\n"
"-1 echo !\n"
"115200 Serial.begin\n"
"100 ms\n"
"-1 z\" /spiffs\" 10 SPIFFS.begin drop\n"
"\n"
": ok cr .\" ESP32forth Copyright 2021 Bradley D. Nelson - With CAL Mods\" cr prompt refill drop quit ;\n"
"( Words with OS assist )\n"
": allocate ( n -- a ior ) malloc dup 0= ;\n"
": free ( a -- ior ) sysfree drop 0 ;\n"
": resize ( a n -- a ior ) realloc dup 0= ;\n"
"\n"
"( CAL misc words )\n"
": bytearray ( size -- ) ( i -- addr ) create allot does> + ;\n"
": array ( size -- ) ( i -- addr ) create cells allot does> swap cells + ;\n"
": initializedArray ( n2 n1 n0 cnt -- ) ( i -- n ) create 0 do , loop does> swap cells + @ ;\n"
": .hex ( n -- ) base @ swap hex . base ! ;\n"
"\n"

#ifdef ENABLE_I2C_SUPPORT

"vocabulary Wire   Wire definitions\n"
"transfer{\n"
"  Wire.begin Wire.setClock Wire.getClock\n"
"  Wire.setTimeout Wire.getTimeout\n"
"  Wire.beginTransmission Wire.endTransmission\n"
"  Wire.requestFrom Wire.write\n"
"  Wire.available Wire.read\n"
"  Wire.peek Wire.flush\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_SPI_SUPPORT

"vocabulary SPI   SPI definitions\n"
"transfer{\n"
"  VSPI.begin VSPI.end VSPI.setHwCs VSPI.setBitOrder VSPI.setDataMode\n"
"  VSPI.setFrequency VSPI.setClockDivider VSPI.getClockDivider VSPI.transfer\n"
"  VSPI.transfer8 VSPI.transfer16 VSPI.transfer32 VSPI.transferBytes VSPI.transferBits\n"
"  VSPI.write VSPI.write16 VSPI.write32 VSPI.writeBytes VSPI.writePixels VSPI.writePattern\n"
"  HSPI.begin HSPI.end HSPI.setHwCs HSPI.setBitOrder HSPI.setDataMode\n"
"  HSPI.setFrequency HSPI.setClockDivider HSPI.getClockDivider HSPI.transfer\n"
"  HSPI.transfer8 HSPI.transfer16 HSPI.transfer32 HSPI.transferBytes HSPI.transferBits\n"
"  HSPI.write HSPI.write16 HSPI.write32 HSPI.writeBytes HSPI.writePixels HSPI.writePattern\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_HTTP_SUPPORT

"vocabulary HTTP   HTTP definitions\n"
"\n"
"transfer{\n"
"  HTTP.begin HTTP.doGet\n"
"  HTTP.getPayload HTTP.end\n"
"}transfer\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_HTTPS_SUPPORT

"vocabulary HTTPS   HTTPS definitions\n"
"\n"
"transfer{\n"
"  HTTPS.setCert\n"
"  HTTPS.begin HTTPS.doGet\n"
"  HTTPS.getPayload HTTPS.end\n"
"}transfer\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_WIFI_SUPPORT

"vocabulary WiFi   WiFi definitions\n"
"\n"
"transfer{\n"
"  WiFi.config\n"
"  WiFi.begin WiFi.disconnect\n"
"  WiFi.status\n"
"  WiFi.macAddress WiFi.localIP\n"
"  WiFi.mode\n"
"  WiFi.setTxPower WiFi.getTxPower\n"
"  WiFi.hostByName\n"
"}transfer\n"
"\n"
"( WiFi Modes )\n"
"0 constant WIFI_MODE_NULL\n"
"1 constant WIFI_MODE_STA\n"
"2 constant WIFI_MODE_AP\n"
"3 constant WIFI_MODE_APSTA\n"
": ip# dup 255 and n. [char] . emit 256 / ;\n"
": ip. ( n -- ) ip# ip# ip# 255 and . ;\n"
": login ( z z -- )\n"
"   WIFI_MODE_STA Wifi.mode\n"
"   WiFi.begin begin WiFi.localIP 0= while 100 ms repeat WiFi.localIP ip. cr ;\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_NETWORK_SUPPORT

"vocabulary Networking   Networking definitions\n"
"\n"
"transfer{\n"
"  Net.connect Net.dispose Net.tcpWrite Net.udpSend\n"
"  Net.receiveTimeoutMS! Net.readTimeoutMS! Net.read Net.readLine\n"
"  Net.tcpServer Net.tcpServerAccept\n"
"}transfer\n"
"\n"
"( Networking Constants )\n"
"1 constant UDP\n"
"2 constant TCP\n"
"0 constant ERR_OK\n"
"-1 constant ERR_CLOSED\n"
"-2 constant ERR_OVERFLOW\n"
"-3 constant ERR_TIMEOUT\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_TEMPSENSOR_SUPPORT

"vocabulary TempSensor   TempSensor definitions\n"
"\n"
"transfer{\n"
"  TempSensor.begin TempSensor.getTempC TempSensor.getTempF\n"
"}transfer\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_SD_SUPPORT

"vocabulary SD   SD definitions\n"
"transfer{\n"
"  SD.begin_hSPI SD.begin_vSPI SD.cardType\n"
"  SD.end\n"
"  SD.totalBytes SD.usedBytes\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif 

#ifdef ENABLE_SD_MMC_SUPPORT

"vocabulary SD_MMC   SD_MMC definitions\n"
"( SD_MMC.begin - TODO: causing issues pulled in )\n"
"transfer{\n"
"  SD_MMC.cardType\n"
"  SD_MMC.end\n"
"  SD_MMC.totalBytes SD_MMC.usedBytes\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif 

#ifdef ENABLE_WS2812_SUPPORT

"vocabulary WS2812   WS2812 definitions\n"
"transfer{\n"
"  WS2812.begin WS2812.show\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_SPIFFS_SUPPORT

"vocabulary SPIFFS   SPIFFS definitions\n"
"transfer{\n"
"  SPIFFS.begin SPIFFS.end\n"
"  SPIFFS.format\n"
"  SPIFFS.totalBytes SPIFFS.usedBytes\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_LEDC_SUPPORT

"vocabulary ledc  ledc definitions\n"
"transfer{\n"
"  ledcSetup ledcAttachPin ledcDetachPin\n"
"  ledcRead ledcReadFreq\n"
"  ledcWrite ledcWriteTone ledcWriteNote\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

"vocabulary Serial   Serial definitions\n"
"transfer{\n"
"  Serial.begin Serial.end\n"
"  Serial.available Serial.readBytes\n"
"  Serial.write Serial.writeBuffer Serial.flush\n"
"  Serial1.begin Serial1.end\n"
"  Serial1.available Serial1.readBytes\n"
"  Serial1.write Serial1.writeBuffer Serial1.flush\n"
"  Serial2.begin Serial2.end\n"
"  Serial2.available Serial2.readBytes\n"
"  Serial2.write Serial2.writeBuffer Serial2.flush\n"
"}transfer\n"
"forth definitions\n"
"\n"

#ifdef ENABLE_INTERRUPTS_SUPPORT

"vocabulary Interrupts   Interrupts definitions\n"
"transfer{\n"
"  gpio_config\n"
"  gpio_reset_pin gpio_set_intr_type\n"
"  gpio_intr_enable gpio_intr_disable\n"
"  gpio_set_level gpio_get_level\n"
"  gpio_set_direction\n"
"  gpio_set_pull_mode\n"
"  gpio_wakeup_enable gpio_wakeup_disable\n"
"  gpio_pullup_en gpio_pullup_dis\n"
"  gpio_pulldown_en gpio_pulldown_dis\n"
"  gpio_hold_en gpio_hold_dis\n"
"  gpio_deep_sleep_hold_en gpio_deep_sleep_hold_dis\n"
"  gpio_install_isr_service gpio_uninstall_isr_service\n"
"  gpio_isr_handler_add gpio_isr_handler_remove\n"
"  gpio_set_drive_capability gpio_get_drive_capability\n"
"  esp_intr_alloc esp_intr_free\n"
"}transfer\n"
"\n"
"0 constant ESP_INTR_FLAG_DEFAULT\n"
": ESP_INTR_FLAG_LEVELn ( n=1-6 -- n ) 1 swap << ;\n"
"1 7 << constant ESP_INTR_FLAG_NMI\n"
"1 8 << constant ESP_INTR_FLAG_SHARED\n"
"1 9 << constant ESP_INTR_FLAG_EDGE\n"
"1 10 << constant ESP_INTR_FLAG_IRAM\n"
"1 11 << constant ESP_INTR_FLAG_INTRDISABLED\n"
"\n"
"( Prefix these with # because GPIO_INTR_DISABLE conflicts with a function. )\n"
"0 constant #GPIO_INTR_DISABLE\n"
"1 constant #GPIO_INTR_POSEDGE\n"
"2 constant #GPIO_INTR_NEGEDGE\n"
"3 constant #GPIO_INTR_ANYEDGE\n"
"4 constant #GPIO_INTR_LOW_LEVEL\n"
"5 constant #GPIO_INTR_HIGH_LEVEL\n"
"\n"
"( Easy word to trigger on any change to a pin )\n"
"ESP_INTR_FLAG_DEFAULT gpio_install_isr_service drop\n"
": pinchange ( xt pin ) dup #GPIO_INTR_ANYEDGE gpio_set_intr_type throw\n"
"                       swap 0 gpio_isr_handler_add throw ;\n"
"\n"
"forth definitions\n"
"\n"

#endif

#ifdef ENABLE_FREERTOS_SUPPORT

"vocabulary rtos   rtos definitions\n"
"transfer{\n"
"  xPortGetCoreID xTaskCreatePinnedToCore vTaskDelete\n"
"}transfer\n"
"forth definitions\n"
"\n"

#endif

"Internals definitions\n"
"transfer{\n"
"  malloc sysfree realloc\n"
"  heap_caps_malloc heap_caps_free heap_caps_realloc\n"
"}transfer\n"
"\n"
"( Heap Capabilities )\n"
"binary\n"
"0001 constant MALLOC_CAP_EXEC\n"
"0010 constant MALLOC_CAP_32BIT\n"
"0100 constant MALLOC_CAP_8BIT\n"
"1000 constant MALLOC_CAP_DMA\n"
": MALLOC_CAP_PID ( n -- ) 10000 over 11 ( 3 ) - for 2* next ;\n"
"000010000000000 constant MALLOC_CAP_SPIRAM\n"
"000100000000000 constant MALLOC_CAP_INTERNAL\n"
"001000000000000 constant MALLOC_CAP_DEFAULT\n"
"010000000000000 constant MALLOC_CAP_IRAM_8BIT\n"
"010000000000000 constant MALLOC_CAP_RETENTION\n"
"decimal\n"
"forth definitions\n"
"\n"
"( Including Files )\n"
": included ( a n -- )\n"
"   r/o open-file dup if nip throw else drop then\n"
"   dup file-size throw\n"
"   dup allocate throw\n"
"   swap 2dup >r >r\n"
"   rot dup >r read-file throw drop\n"
"   r> close-file throw\n"
"   r> r> over >r evaluate\n"
"   r> free throw ;\n"
": include ( \"name\" -- ) bl parse included ; \n"
"\n"
"( Floating Point Functions )\n"
": f= ( r r -- f ) f- f0= ;\n"
": f< ( r r -- f ) f- f0< ;\n"
": f> ( r r -- f ) fswap f< ;\n"
": f<> ( r r -- f ) f= 0= ;\n"
": f<= ( r r -- f ) f> 0= ;\n"
": f>= ( r r -- f ) f< 0= ;\n"
"\n"
"4 constant sfloat\n"
": sfloats ( n -- n*4 ) sfloat * ;\n"
": sfloat+ ( a -- a ) sfloat + ;\n"
": sf, ( r -- ) here sf! sfloat allot ;\n"
"\n"
": afliteral ( r -- ) ['] DOFLIT , sf, align ;\n"
": fliteral   afliteral ; immediate\n"
"\n"
": fconstant ( r \"name\" ) create sf, align does> sf@ ;\n"
": fvariable ( \"name\" ) create sfloat allot align ;\n"
": farray ( size -- ) ( i -- addr ) create sfloats allot does> swap sfloats + ;\n"
"\n"
"3.14159265359e fconstant pi\n"
"\n"
"6 value precision\n"
": set-precision ( n -- ) to precision ;\n"
"\n"
"internals definitions\n"
": #f+s ( r -- ) fdup precision 0 ?do 10e f* loop\n"
"                precision 0 ?do fdup f>s 10 mod [char] 0 + hold 0.1e f* loop\n"
"                [char] . hold fdrop f>s #s ;\n"
"transfer doflit\n"
"forth definitions internals\n"
"\n"
": #fs ( r -- ) fdup f0< if fnegate #f+s [char] - hold else #f+s then ;\n"
": f. ( r -- ) <# #fs #> type space ;\n"
"\n"
"forth definitions\n"
": dump-file ( a n a n -- )\n"
"  w/o create-file if drop .\" failed create-file\" exit then\n"
"  >r r@ write-file if r> drop .\" failed write-file\" exit then\n"
"  r> close-file drop\n"
";\n"
"\n"
"Internals definitions\n"
"( Leave some room for growth of starting system. )\n"
"$4000 constant growth-gap\n"
"here growth-gap + growth-gap 1- + growth-gap 1- invert and constant saving-base\n"
": park-heap ( -- a ) saving-base ;\n"
": park-forth ( -- a ) saving-base cell+ ;\n"
": 'cold ( -- a ) saving-base 2 cells + ;   0 'cold !\n"
"\n"
": save-name\n"
"  cr 'heap @ park-heap !\n"
"  forth-wordlist @ park-forth !\n"
"  w/o create-file throw >r\n"
"  saving-base here over - dup . cr r@ write-file throw\n"
"  r> close-file throw ;\n"
"\n"
": restore-name ( \"name\" -- )\n"
"  r/o open-file throw >r\n"
"  saving-base r@ file-size throw r@ read-file throw drop\n"
"  r> close-file throw\n"
"  park-heap @ 'heap !\n"
"  park-forth @ forth-wordlist !\n"
"  'cold @ dup if execute else drop then ;\n"
"\n"
"defer remember-filename\n"
": default-remember-filename   s\" myforth\" ;\n"
"' default-remember-filename is remember-filename\n"
"\n"
"forth definitions also Internals\n"
"\n"
": save ( \"name\" -- ) bl parse save-name ;\n"
": restore ( \"name\" -- ) bl parse restore-name ;\n"
": remember   remember-filename save-name ;\n"
": startup: ( \"name\" ) ' 'cold ! remember ;\n"
": revive   remember-filename restore-name ;\n"
": reset   remember-filename delete-file throw ;\n"
"\n"
"only forth definitions\n"
"( Words built after boot )\n"
"\n"
"( For tests and asserts )\n"
": assert ( f -- ) 0= throw ;\n"
"\n"
"( Examine Memory )\n"
": dump ( a n -- )\n"
"   cr 0 do i 16 mod 0= if cr then dup i + c@ . loop drop cr ;\n"
"\n"
"( Remove from Dictionary )\n"
": forget ( \"name\" ) ' dup >link current @ !  >name drop here - allot ;\n"
"\n"
"2 constant SMUDGE\n"
": :noname ( -- xt ) 0 , current @ @ , SMUDGE , here dup current @ ! ['] = @ , postpone ] ;\n"
"\n"
"Internals definitions\n"
": mem= ( a a n -- f)\n"
"   for aft 2dup c@ swap c@ <> if 2drop rdrop 0 exit then 1+ swap 1+ then next 2drop -1 ;\n"
"forth definitions also Internals\n"
": str= ( a n a n -- f) >r swap r@ <> if rdrop 2drop 0 exit then r> mem= ;\n"
": startswith? ( a n a n -- f ) >r swap r@ < if rdrop 2drop 0 exit then r> mem= ;\n"
": .s   .\" <\" depth n. .\" > \" raw.s cr ;\n"
"only forth definitions\n"
"\n"
"( Definitions building to SEE and ORDER )\n"
"Internals definitions\n"
": see. ( xt -- ) >name type space ;\n"
": see-one ( xt -- xt+1 )\n"
"   dup cell+ swap @\n"
"   dup ['] DOLIT = if drop dup @ . cell+ exit then\n"
"   dup ['] DOFLIT = if drop dup sf@ <# [char] e hold #fs #> type space cell+ exit then\n"
"   dup ['] $@ = if drop ['] s\" see.\n"
"                   dup @ dup >r >r dup cell+ r> type cell+ r> aligned +\n"
"                   [char] \" emit space exit then\n"
"   dup  ['] BRANCH =\n"
"   over ['] 0BRANCH = or\n"
"   over ['] DONEXT = or\n"
"       if see. cell+ exit then\n"
"   see. ;\n"
": exit= ( xt -- ) ['] exit = ;\n"
": see-loop   >body begin dup @ exit= 0= while see-one repeat drop ;\n"
": see-xt ( xt -- )\n"
"        dup @ ['] see-loop @ <>\n"
"        if .\" Unsupported word type: \" see. cr exit then\n"
"        ['] : see.  dup see.  space see-loop   ['] ; see. cr ;\n"
": see-all   0 context @ @ begin dup while dup see-xt >link repeat 2drop cr ;\n"
": voc. ( voc -- ) dup forth-wordlist = if .\" FORTH \" drop exit then 3 cells - see. ;\n"
"forth definitions also Internals\n"
": see   ' see-xt ;\n"
": order   context begin dup @ while dup @ voc. cell+ repeat drop cr ;\n"
"only forth definitions\n"
"\n"
"( List words in Dictionary / Vocabulary )\n"
"Internals definitions\n"
"75 value line-width\n"
": onlines ( n xt -- n xt )\n"
"   swap dup line-width > if drop 0 cr then over >name nip + 1+ swap ;\n"
": >name-length ( xt -- n ) dup 0= if exit then >name nip ;\n"
"forth definitions also Internals\n"
": vlist cr 0 context @ @ begin dup >name-length while onlines dup see. >link repeat 2drop cr ;\n"
": words cr 0 context @ @ begin dup while onlines dup see. >link repeat 2drop cr ;\n"
"only forth definitions\n"
"\n"
"( Extra Task Utils )\n"
"tasks definitions also Internals\n"
": .tasks   task-list @ begin dup 2 cells - see. @ dup task-list @ = until drop ;\n"
"only forth definitions\n"

"( Local Variables )\n"
"\n"
"( NOTE: These are not yet gforth compatible )\n"
"\n"
"Internals definitions\n"
"\n"
"( Leave a region for locals definitions )\n"
"1024 constant locals-capacity  128 constant locals-gap\n"
"create locals-area locals-capacity allot\n"
"variable locals-here  locals-area locals-here !\n"
": <>locals   locals-here @ here locals-here ! here - allot ;\n"
"\n"
": local@ ( n -- ) rp@ + @ ;\n"
": local! ( n -- ) rp@ + ! ;\n"
": local+! ( n -- ) rp@ + +! ;\n"
"\n"
"variable scope-depth\n"
"variable local-op   ' local@ local-op !\n"
": scope-clear\n"
"   scope-depth @ negate nest-depth +!\n"
"   scope-depth @ for aft postpone rdrop then next\n"
"   0 scope-depth !   0 scope !   locals-area locals-here ! ;\n"
": do-local ( n -- ) nest-depth @ + cells negate aliteral\n"
"                    local-op @ ,  ['] local@ local-op ! ;\n"
": scope-create ( a n -- )\n"
"   dup >r $place align r> , ( name )\n"
"   scope @ , 1 , ( IMMEDIATE ) here scope ! ( link, flags )\n"
"   ['] scope-clear @ ( docol) ,\n"
"   nest-depth @ negate aliteral postpone do-local ['] exit ,\n"
"   1 scope-depth +!  1 nest-depth +!\n"
";\n"
"\n"
": ?room   locals-here @ locals-area - locals-capacity locals-gap - >\n"
"          if scope-clear -1 throw then ;\n"
"\n"
": }? ( a n -- ) 1 <> if drop 0 exit then c@ [char] } = ;\n"
": --? ( a n -- ) s\" --\" str= ;\n"
": (to) ( xt -- ) ['] local! local-op ! execute ;\n"
": (+to) ( xt -- ) ['] local+! local-op ! execute ;\n"
"\n"
"also forth definitions\n"
"\n"
": (local) ( a n -- )\n"
"   dup 0= if 2drop exit then \n"
"   ?room <>locals scope-create <>locals postpone >r ;\n"
": {   bl parse\n"
"      dup 0= if scope-clear -1 throw then\n"
"      2dup --? if 2drop [char] } parse 2drop exit then\n"
"      2dup }? if 2drop exit then\n"
"      recurse (local) ; immediate\n"
"( TODO: Hide the words overriden here. )\n"
": ;   scope-clear postpone ; ; immediate\n"
": to ( n -- ) ' dup >flags @ if (to) else ['] ! value-bind then ; immediate\n"
": +to ( n -- ) ' dup >flags @ if (+to) else ['] +! value-bind then ; immediate\n"
"\n"
"only forth definitions\n"

"( Byte Stream / Ring Buffer )\n"
"\n"
"vocabulary streams   streams definitions\n"
"\n"
": stream ( n \"name\" ) create 1+ dup , 0 , 0 , allot align ;\n"
": >write ( st -- wr ) cell+ ;   : >read ( st -- rd ) 2 cells + ;\n"
": >offset ( n st -- a ) 3 cells + + ;\n"
": stream# ( sz -- n ) >r r@ >write @ r@ >read @ - r> @ mod ;\n"
": full? ( st -- f ) dup stream# swap @ 1- = ;\n"
": empty? ( st -- f ) stream# 0= ;\n"
": wait-write ( st -- ) begin dup full? while pause repeat drop ;\n"
": wait-read ( st -- ) begin dup empty? while pause repeat drop ;\n"
": ch>stream ( ch st -- )\n"
"   dup wait-write\n"
"   >r r@ >write @ r@ >offset c!\n"
"   r@ >write @ 1+ r@ @ mod r> >write ! ;\n"
": stream>ch ( st -- ch )\n"
"   dup wait-read\n"
"   >r r@ >read @ r@ >offset c@\n"
"   r@ >read @ 1+ r@ @ mod r> >read ! ;\n"
": >stream ( a n st -- )\n"
"   swap for aft over c@ over ch>stream swap 1+ swap then next 2drop ;\n"
": stream> ( a n st -- )\n"
"   begin over 1 > over empty? 0= and while\n"
"   dup stream>ch >r rot dup r> swap c! 1+ rot 1- rot repeat 2drop 0 swap c! ;\n"
"\n"
"forth definitions\n"
"\n"
"only forth definitions\n"
"vocabulary registers   registers definitions\n"
"\n"
"( Tools for working with bit masks )\n"
": m! ( val shift mask a -- )\n"
"   dup >r @ over invert and >r >r << r> and r> or r> ! ;\n"
": m@ ( shift mask a -- val ) @ and swap >> ;\n"
"\n"
"only forth definitions\n"

"vocabulary timers   timers definitions   also registers also interrupts\n"
"\n"
"$3ff5f000 constant TIMG_BASE\n"
"( group n = 0/1, timer x = 0/1, watchdog m = 0-5 )\n"
": TIMGn ( n -- a ) $10000 * TIMG_BASE + ;\n"
": TIMGn_Tx ( n x -- a ) $24 * swap TIMGn + ;\n"
": TIMGn_TxCONFIG_REG ( n x -- a ) TIMGn_Tx 0 cells + ;\n"
": TIMGn_TxLOHI_REG ( n x -- a ) TIMGn_Tx 1 cells + ;\n"
": TIMGn_TxUPDATE_REG ( n x -- a ) TIMGn_Tx 3 cells + ;\n"
": TIMGn_TxALARMLOHI_REG ( n x -- a ) TIMGn_Tx 4 cells + ;\n"
": TIMGn_TxLOADLOHI_REG ( n x -- a ) TIMGn_Tx 6 cells + ;\n"
": TIMGn_TxLOAD_REG ( n x -- a ) TIMGn_Tx 8 cells + ;\n"
"\n"
": TIMGn_Tx_WDTCONFIGm_REG ( n m -- a ) swap TIMGn cells + $48 + ;\n"
": TIMGn_Tx_WDTFEED_REG ( n -- a ) TIMGn $60 + ;\n"
": TIMGn_Tx_WDTWPROTECT_REG ( n -- a ) TIMGn $6c + ;\n"
"\n"
": TIMGn_RTCCALICFG_REG ( n -- a ) TIMGn $68 + ;\n"
": TIMGn_RTCCALICFG1_REG ( n -- a ) TIMGn $6c + ;\n"
"\n"
": TIMGn_Tx_INT_ENA_REG ( n -- a ) TIMGn $98 + ;\n"
": TIMGn_Tx_INT_RAW_REG ( n -- a ) TIMGn $9c + ;\n"
": TIMGn_Tx_INT_ST_REG ( n -- a ) TIMGn $a0 + ;\n"
": TIMGn_Tx_INT_CLR_REG ( n -- a ) TIMGn $a4 + ;\n"
"\n"
": t>nx ( t -- n x ) dup 2/ 1 and swap 1 and ;\n"
"\n"
": timer@ ( t -- lo hi )\n"
"   dup t>nx TIMGn_TxUPDATE_REG 0 swap !\n"
"       t>nx TIMGn_TxLOHI_REG 2@ ;\n"
": timer! ( lo hi t -- )\n"
"   dup >r t>nx TIMGn_TxLOADLOHI_REG 2!\n"
"       r> t>nx TIMGn_TxLOAD_REG 0 swap ! ;\n"
": alarm ( t -- a ) t>nx TIMGn_TxALARMLOHI_REG ;\n"
"\n"
": enable! ( v t ) >r 31 $80000000 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": increase! ( v t ) >r 30 $40000000 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": autoreload! ( v t ) >r 29 $20000000 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": divider! ( v t ) >r 13 $1fffc000 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": edgeint! ( v t ) >r 12 $1000 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": levelint! ( v t ) >r 11 $800 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": alarm-enable! ( v t ) >r 10 $400 r> t>nx TIMGn_TxCONFIG_REG m! ;\n"
": alarm-enable@ ( v t ) >r 10 $400 r> t>nx TIMGn_TxCONFIG_REG m@ ;\n"
"\n"
": int-enable! ( f t -- )\n"
"   t>nx swap >r dup 1 swap << r> TIMGn_Tx_INT_ENA_REG m! ;\n"
"\n"
": onalarm ( xt t ) swap >r t>nx r> 0 ESP_INTR_FLAG_EDGE 0\n"
"                   timer_isr_register throw ;\n"
": interval ( xt usec t ) 80 over divider!\n"
"                         swap over 0 swap alarm 2!\n"
"                         1 over increase!\n"
"                         1 over autoreload!\n"
"                         1 over alarm-enable!\n"
"                         1 over edgeint!\n"
"                         0 over 0 swap timer!\n"
"                         dup >r onalarm r>\n"
"                         1 swap enable! ;\n"
": rerun ( t -- ) 1 swap alarm-enable! ;\n"
"\n"
"only forth definitions\n"
"Internals definitions\n"
"( Setup remember file )\n"
": arduino-remember-filename   s\" /spiffs/myforth\" ;\n"
"' arduino-remember-filename is remember-filename\n"
"\n"
"( Check for autoexec.fs and run if present.\n"
"  Failing that, try to revive save image. )\n"
": autoexec\n"
"   300 for key? if rdrop exit then 10 ms next\n"
"   s\" /spiffs/autoexec.fs\" ['] included catch 2drop drop\n"
"   ['] revive catch drop ;\n"
"' autoexec ( leave on the stack for fini.fs )\n"
"\n"
"forth definitions\n"
"Internals\n"
"( Bring a forth to the top of the vocabulary. )\n"
"transfer forth\n"
"( Move heap to save point, with a gap. )\n"
"saving-base 16 cells + 'heap !\n"
"forth\n"
"execute ( assumes an xt for autoboot is on the dstack )\n"
"ok\n"
"\n";

// Work around lack of ftruncate
static cell_t ResizeFile(cell_t fd, cell_t size) {
  struct stat st;
  char buf[256];
  cell_t t = fstat(fd, &st);
  if (t < 0) { return errno; }
  if (size < st.st_size) {
    // TODO: Implement truncation
    return ENOSYS;
  }
  cell_t oldpos = lseek(fd, 0, SEEK_CUR);
  if (oldpos < 0) { return errno; }
  t = lseek(fd, 0, SEEK_END);
  if (t < 0) { return errno; }
  memset(buf, 0, sizeof(buf));
  while (st.st_size < size) {
    cell_t len = sizeof(buf);
    if (size - st.st_size < len) {
      len = size - st.st_size;
    }
    t = write(fd, buf, len);
    if (t != len) {
      return errno;
    }
    st.st_size += t;
  }
  t = lseek(fd, oldpos, SEEK_SET);
  if (t < 0) { return errno; }
  return 0;
}

struct handle_interrupt_args {
  cell_t xt;
  cell_t arg;
};

static void IRAM_ATTR HandleInterrupt(void *arg) {
  struct handle_interrupt_args *args = (struct handle_interrupt_args *) arg;
  cell_t code[2];
  code[0] = args->xt;
  code[1] = g_sys.YIELD_XT;
  cell_t stack[INTERRUPT_STACK_CELLS];
  cell_t rstack[INTERRUPT_STACK_CELLS];
  stack[0] = args->arg;
  cell_t *rp = rstack;
  *++rp = (cell_t) (stack + 1);
  *++rp = (cell_t) code;
  forth_run(rp);
}

static cell_t EspIntrAlloc(cell_t source, cell_t flags, cell_t xt, cell_t arg, void *ret) {
  // NOTE: Leaks memory.
  struct handle_interrupt_args *args = (struct handle_interrupt_args *) malloc(sizeof(struct handle_interrupt_args));
  args->xt = xt;
  args->arg = arg;
  return esp_intr_alloc(source, flags, HandleInterrupt, args, (intr_handle_t *) ret);
}

static cell_t GpioIsrHandlerAdd(cell_t pin, cell_t xt, cell_t arg) {
  // NOTE: Leaks memory.
  struct handle_interrupt_args *args = (struct handle_interrupt_args *) malloc(sizeof(struct handle_interrupt_args));
  args->xt = xt;
  args->arg = arg;
  return gpio_isr_handler_add((gpio_num_t) pin, HandleInterrupt, args);
}

static cell_t TimerIsrRegister(cell_t group, cell_t timer, cell_t xt, cell_t arg, cell_t flags, void *ret) {
  // NOTE: Leaks memory.
  struct handle_interrupt_args *args = (struct handle_interrupt_args *) malloc(sizeof(struct handle_interrupt_args));
  args->xt = xt;
  args->arg = arg;
  return timer_isr_register((timer_group_t) group, (timer_idx_t) timer, HandleInterrupt, args, flags, (timer_isr_handle_t *) ret);
}

#ifdef ENABLE_WS2812_SUPPORT

// The maximum number of pixels that can be controlled with
// the following code
#define MAX_PIXELS 192

// Driver data
rmt_item32_t items[MAX_PIXELS * 24 + 1];

/**
 * Set two levels of RMT output to the WS2812 value for a "1".
 * This is:
 * a logic 1 for 0.7us
 * a logic 0 for 0.6us
 */
static void setItem1(rmt_item32_t* pItem) {
  pItem->level0    = 1;
  pItem->duration0 = 7;
  pItem->level1    = 0;
  pItem->duration1 = 6;
}

/**
 * Set two levels of RMT output to the WS2812 value for a "0".
 * This is:
 * a logic 1 for 0.4us
 * a logic 0 for 0.8us
 */

static void setItem0(rmt_item32_t* pItem) {
  pItem->level0    = 1;
  pItem->duration0 = 4;
  pItem->level1    = 0;
  pItem->duration1 = 8;
}

// Add an RMT terminator into the RMT data.
static void setTerminator(rmt_item32_t* pItem) {
  pItem->level0    = 0;
  pItem->duration0 = 0;
  pItem->level1    = 0;
  pItem->duration1 = 0;
}

/**
 * Initialize the WS2812 driver to use RMT channel 0
 * gpioPin is the pin the neopixel string is connected to
 */
static void initWS2812Driver(int gpioPin) {

  // Setup the RMT controller for driving a pixel string
  rmt_config_t config;
  config.rmt_mode                  = RMT_MODE_TX;
  config.channel                   = RMT_CHANNEL_0;
  config.gpio_num                  = (gpio_num_t) gpioPin;
  config.mem_block_num             = 8;
  config.clk_div                   = 8;
  config.tx_config.loop_en         = 0;
  config.tx_config.carrier_en      = 0;
  config.tx_config.idle_output_en  = 1;
  config.tx_config.idle_level      = (rmt_idle_level_t) 0;
  config.tx_config.carrier_freq_hz = 10000;
  config.tx_config.carrier_level   = (rmt_carrier_level_t) 1;
  config.tx_config.carrier_duty_percent = 50;

  ESP_ERROR_CHECK(rmt_config(&config));
  ESP_ERROR_CHECK(rmt_driver_install((rmt_channel_t) 0, 0, 0));
}

/**
 * Show the current Neopixel data.
 * Drive the LEDs with the values that were previously set
 * pPixel is a pointer to an array of pixels (24 bit RGB values) maintained by Forth
 * The order of the color components is dictated by how the data is put
 * into the pixel array at the Forth level
 * pixelCount is the number of pixels being controlled
 */
 static void showPixels(uint8_t *pPixel, int pixelCount) {

  // Make sure we have a valid number of pixels
  if ((pixelCount == 0) || (pixelCount > MAX_PIXELS)) {
    fprintf(stderr, "Bad pixelCount specified. Must be 0 < pixelCount <= %d\n", MAX_PIXELS);
    return;
  }

  // Get a pointer to the first RMT item
  rmt_item32_t *pCurrentItem = &items[0];

  for (int i = 0; i < pixelCount; i++) {
    uint32_t _c1 = pPixel[i * 3];
    uint32_t _c2 = pPixel[i * 3 + 1]; 
    uint32_t _c3 = pPixel[i * 3 + 2];
    uint32_t currentPixel = (_c1 << 16) | (_c2 << 8) | _c3;

   // We have 24 bits of data representing the red, green amd blue color components. 
   // The value of the 24 bits to output is in the variable currentPixel.  We now need
   // to stream this value to RMT by iterating through each of the 24 bits from MSB to LSB.

    for (int j = 23; j >= 0; j--) {
      if (currentPixel & (1 << j)) {
        setItem1(pCurrentItem);
      } else {
        setItem0(pCurrentItem);
      }
      pCurrentItem++;
    }
  }
  // Write the RMT terminator
  setTerminator(pCurrentItem);

  // Write the data to show the pixels
  ESP_ERROR_CHECK(rmt_write_items(RMT_CHANNEL_0, items, pixelCount * 24, 1 /* wait till done */));
}

#endif

#ifdef ENABLE_NETWORK_SUPPORT

#include "lwip/api.h"
#include "lwip/ip_addr.h"

#define RECEIVE_TIMEOUT_MS  250
#define READ_TIMEOUT_MS    3000
#define ERR_OK        0
#define ERR_CLOSED   -1
#define ERR_OVERFLOW -2
#define ERR_TIMEOUT  -3

struct forth_netconn {
  struct netconn *conn;
  struct netbuf  *nbuf;
  int bufpos;
  int readTimeoutMS;
};

// Set esp-idf internal receive timeout. Default is RECEIVE_TIMEOUT_MS
static void setReceiveTimeoutMS(struct forth_netconn *connection, int timeout) {
  netconn_set_recvtimeout(connection->conn, timeout);
}

// Set read timeout. Default is READ_TIMEOUT_MS
static void setReadTimeoutMS(struct forth_netconn *connection, int timeout) {
  connection->readTimeoutMS = timeout;
}

static struct forth_netconn *make_forth_netconn(struct netconn *conn) {

  if (conn == NULL) {
    return NULL;
  }

  struct forth_netconn *result = (struct forth_netconn *) malloc(sizeof(struct forth_netconn));
  result->conn = conn;
  result->nbuf = NULL;
  result->bufpos = 0;
  result->readTimeoutMS = READ_TIMEOUT_MS;
  return result;
}

static struct forth_netconn *forth_netcon_new(int type) {
  enum netconn_type con_type;
  // fprintf(stderr, "\nNew netcon type: %d\n", type);
  switch (type) {
    case 1: 
      con_type = NETCONN_UDP;
      break;
    case 2: 
      con_type = NETCONN_TCP;
      break;
    default:
      return NULL;
  }
  struct netconn* conn = netconn_new(con_type);
  // fprintf(stderr, "\nConnection: %p\n", conn);
  netconn_set_recvtimeout(conn, RECEIVE_TIMEOUT_MS);
  return make_forth_netconn(conn);
}

static int forth_netcon_connect(struct forth_netconn *conn, char *host, uint16_t port) {   
  err_t err; 
  ip_addr_t ip;

  // fprintf(stderr, "\nGetting hostname: %s\n", host);
  err = netconn_gethostbyname(host, &ip);
  if (err != ERR_OK) {
    fprintf(stderr, "Failed to resolve host %s. Error: %d\n", host, err);
    return err;
  }
  // fprintf(stderr, "\nRemote IP address: %s\n", ip4addr_ntoa(&ip));

  // fprintf(stderr, "\nConnecting to %s:%d, conn: %p\n", host, port, conn);
  err = netconn_connect(conn->conn, &ip, port);
  if (err != ERR_OK) {
    fprintf(stderr, "Failed to connect to %s:%d. Error: %d\n", host, port, err);
  }
  return err;
}

// High level network connection function
static struct forth_netconn *netConnect(int type, char *hostPtr, int port) {

  struct forth_netconn *cPtr = forth_netcon_new(type);
  if (cPtr == NULL) {
    fprintf(stderr, "netConnect: failed netcon_new\n");
    return NULL;
  }

  int result = forth_netcon_connect(cPtr, hostPtr, (uint16_t) port);
  if (result == ERR_OK) {
    return cPtr;
  } else {
    fprintf(stderr, "netConnect: failed to connect\n");
    return NULL;
  }
}

// Closes network connection but doesn't free resources
static void forth_netcon_close(struct forth_netconn *conn) {
  // fprintf(stderr, "Closing connection %p\n", conn);
  netconn_close(conn->conn);
}

// Closes network connection and frees resources
static void forth_netcon_delete(struct forth_netconn *conn) {
  // fprintf(stderr, "Deleting connection %p\n", conn);
  netconn_delete(conn->conn);
  if (conn->nbuf != NULL) {
    netbuf_delete(conn->nbuf);
  }
  free(conn);
}

static void netDispose(cell_t conn) {

  if ((struct forth_netconn*) conn != NULL) {
    forth_netcon_close((struct forth_netconn*) conn);
    forth_netcon_delete((struct forth_netconn*) conn);
  } else {
    fprintf(stderr, "netDispose: Cannot dispose of Null handle\n");
  }
}

// Send the content of the given buffer to a UDP socket.
static int udpSend(cell_t conn, uint8_t *data, cell_t len) {

  // fprintf(stderr, "Sending data len: %d conn: %p\n", (int) len, (struct forth_netconn*) conn);
  err_t err;
  struct netbuf* buffer = netbuf_new();
  if (buffer == NULL) {
    return ERR_MEM;
  }
  void* memory = netbuf_alloc(buffer, (int) len);
  if (memory == NULL) {
    return ERR_MEM;
  }
  memcpy(memory, (void *) data, (int) len);
  err = netconn_send(((struct forth_netconn*) conn)->conn, buffer);
  if (err != ERR_OK) {
    fprintf(stderr, "Failed to send data. Conn: %p. Error: %d\n", (struct forth_netconn*) conn, err);
  }   
  netbuf_delete(buffer);
  return err;
}

// Write the content of the given buffer to a TCP socket.
static int tcpWrite(cell_t conn, uint8_t *data, cell_t len) {

  err_t err = netconn_write(((struct forth_netconn*) conn)->conn, (uint8_t *) data, (uint16_t) len, NETCONN_COPY);
  if (err != ERR_OK) {
    fprintf(stderr, "Failed to write data. Conn: %p. Error: %d\n", (struct forth_netconn*) conn, err);
  }   
  return err;
}

// RECEIVE FUNCTIONS

static int _forth_netcon_receive(struct forth_netconn* conn, uint8_t* buffer, int size) {

  if (conn->nbuf == NULL) {
    struct netbuf *inbuf;

    // Attempt to receive network data
    err_t err = netconn_recv(conn->conn, &inbuf);
    if (err != ERR_OK) {
      if (err == -13) {
        err = ERR_CLOSED;
      }
      return err;
    }
    // If we get here we have some data
    conn->nbuf = inbuf;
    conn->bufpos = 0;
  }

  // Copy the received data to user's buffer
  int count = netbuf_copy_partial(conn->nbuf, buffer, size, conn->bufpos);
  if (count > 0) {
    conn->bufpos += count;
    return count;
  }

  // No more data to copy
  netbuf_delete(conn->nbuf);
  conn->nbuf = NULL;
  conn->bufpos = 0;
  return ERR_OK; 
}

static int forth_netcon_receive(struct forth_netconn* conn, uint8_t* buffer, int size) {

  err_t err = ERR_OK;
  uint32_t endTime = millis() + conn->readTimeoutMS;
 
  while (endTime > millis()) {
    // Attempt to receive network data
    err = _forth_netcon_receive(conn, buffer, size);

    // If > 0 then data has been copied into buffer, return count of bytes copied
    if (err > 0) {
      return err;
    }
    // Timeout ?
    else if ((err == ERR_TIMEOUT) || (err == ERR_OK)) {
      delay(100);
    } else {
      return err;
    }
  }
  return ERR_CLOSED;
}

// Read maximum `size` amount of bytes into the buffer.
// Returns count of bytes read or error if result < 0
// Typical errors are ERR_TIMEOUT or ERR_CLOSED if connection was closed
static int netRead(cell_t conn, uint8_t *buffer, cell_t size) {

  return forth_netcon_receive((struct forth_netconn*) conn, buffer, (uint16_t) size);
}

// Read one line into the given buffer. The line terminator is CRLF.
// Returns count of bytes read or error if result < 0
// CRLF is returned in buffer and are part of count
// Typical errors are ERR_TIMEOUT or ERR_CLOSED if connection was closed
static int netReadLn(cell_t conn, uint8_t *buffer, cell_t size) {

  uint8_t *buf = (uint8_t *) buffer;

  for (int i = 0; i < (int) size; i++) {
    // Read a single char into the buffer   
    int err = forth_netcon_receive((struct forth_netconn*) conn, buf + i, 1);
    if (err < 0) {   // Was EOF reached or an error occurred ?
      if (i >= 1) {  // Was a previous char read ?
        return i;
      } else {
        return err;
      }
    }
    // If the char read was a LF and there are other chars in the buffer
    if ((buf[i] == 10) && (i >= 1)) {
      if (buf[i - 1] == 13) {  // Was previous char a CR ?
        return i + 1;
      }
    }
  }
  // Buffer overflow
  return ERR_OVERFLOW;
}

// TCP SERVER FUNCTIONS

// Create a TCP server which will listen on the specified port for client connections.
// This function returns a handle to the created server which must be passed to
// netTCPServerAccept. A return value < 0 indicates an error has occurred.
static struct netconn* netTCPServer(int port) {

  struct netconn* conn = netconn_new(NETCONN_TCP);

  // Bind connection to any IP address at port
  err_t err = netconn_bind(conn, NULL, (int) port);
  if (err != ERR_OK) {
    fprintf(stderr, "Error: %d binding to port: %d\n", err, (int) port);
    return NULL;
  }
  // Tell connection to go into listening mode.
  err = netconn_listen(conn);
  if (err != ERR_OK) {
    fprintf(stderr, "Error: %d on netconn_listen\n", err);
    return NULL;
  }
  return conn;
}

// Wait for a client to connect on the server specified by the serverHandle
// When a client connection is sensed, this function will return a handle to
// the client which the application can manipulate. After the client is
// handled an application can call this again for the next client.
static struct forth_netconn* netTCPServerAccept(cell_t serverHandle) {

  struct netconn* conn;

  while (true) {
    delay(1);

    err_t err = netconn_accept((struct netconn *) serverHandle, &conn);
    if (err != ERR_TIMEOUT) {
      netconn_set_recvtimeout(conn, RECEIVE_TIMEOUT_MS);
      return make_forth_netconn(conn);
    }
  }
}

#endif

void setup() {
  cell_t *heap = (cell_t *) malloc(HEAP_SIZE);
  forth_init(0, 0, heap, boot, sizeof(boot));
}

void loop() {
  g_sys.rp = forth_run(g_sys.rp);
}
