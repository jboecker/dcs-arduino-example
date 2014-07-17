REM Specify the number of the COM port your Arduino is connected to:

set COMPORT=3



set /A TTYNUM=%COMPORT%-1
mode COM%COMPORT% BAUD=115200 PARITY=N DATA=8 STOP=1 TO=off DTR=on
socat\socat -v udp-recv:7777!!udp-sendto:localhost:7778 /dev/ttyS%TTYNUM%

