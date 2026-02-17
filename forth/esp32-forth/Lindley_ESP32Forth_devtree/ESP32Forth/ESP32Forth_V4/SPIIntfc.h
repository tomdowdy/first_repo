/*
 * SPI Interface file for ESP32Forth
 *
 * This is necessary because with the advent of the ESP32-S2 and ESP32-S3
 * chips the SPI interface required by ESP32Forth keeps changing.
 *
 * Concept, Design and Implementation by: Craig A. Lindley
 * Last Update: 05/18/2023
 *
 */

#include <SPI.h>

#if CONFIG_IDF_TARGET_ESP32
SPIClass vSPI(VSPI);
SPIClass hSPI(HSPI);
#else
SPIClass vSPI(FSPI);
SPIClass hSPI(HSPI);
#endif
