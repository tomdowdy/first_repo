q
NOTE: the Arduino ESP32Forth code is available in the Arduino/ESP32/ESP32Forth/ESP32forth_V2. This code must be flashed to the ESP32 before attempting to use
the ESP32 Forth Loader described below.


ESP32 Forth Loader Running Instructions
Craig A. Lindley
July 2021

Prerequisites
====================
1. ESP32ForthLoader.jar
2. jssc-2.8.0.jar (or newer)

Executing From Shell
====================
1. Change directory to where the Forth jar files are located 
2. export FORTH_HOME=<“full path to directory with esp32Forth project files>”
3. export CLASSPATH=“./ESP32ForthLoader.jar:./jssc-2.9.6.jar”
4. java com.craigl.esp32ForthLoader.ESP32ForthLoader

Alternatively add the following to your .profile/.zshenv file in your home directory
====================
# Items for ESP32 Forth Loader
export FORTH_HOME=~/Documents/dev/ESP32Forth/projects
export CLASSPATH=~/Documents/dev/ESP32Forth/ESP32ForthLoader.jar:~/Documents/dev/ESP32ForthLoader/jssc-2.9.6.jar
alias fl="java com.craigl.esp32ForthLoader.ESP32ForthLoader"

Operation
====================
1. Connect your ESP32 device to your computer
2. Execute ESP32pForthLoader as described above
3. Once loader is operational, select appropriate Serial Port from drop down list
4. Click Open button in the UI to open the selected Serial Port
5. Type #help into the Input Area to see the help info
6. Type Forth commands to interact with ESP32forth
7. Type #include <filename> to load Forth code from a file
8. Use up/down cursor keys to retrieve command history
9. Type #bye to terminate the loader


NOTES:
1. The loader's window can be resized as necessary
