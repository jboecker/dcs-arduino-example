/*
 CMSP Export Example
 
 The circuit:
 * LCD RS pin to digital pin 12
 * LCD Enable pin to digital pin 11
 * LCD D4 pin to digital pin 5
 * LCD D5 pin to digital pin 4
 * LCD D6 pin to digital pin 3
 * LCD D7 pin to digital pin 2
 * LCD R/W pin to ground
 * 10K potentiometer:
 *   ends to +5V and ground
 *   wiper to LCD VO pin (pin 3)
 * Push button between digital pin 10 and ground
 * LED on digital pin 13 (built into Arduino board)
 
 */

#include <LiquidCrystal.h>

// initialize the LCD library with the numbers of the interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

int buttonState = 0;
int lastButtonState = 0;

void setup(){
  pinMode(13, OUTPUT);
  pinMode(10, INPUT_PULLUP); 
    // set up the LCD's number of columns and rows: 
  lcd.begin(20, 2);
  // initialize the serial communications:
  Serial.begin(115200);
  lcd.setCursor(0,0);
  lcd.clear();
}

int lcdpos = 0;
char cmd_buf[16];
unsigned char cmd_len = 0;
#define STATE_READ_CMD 1
#define STATE_ERROR 2

#define STATE_CMD_CMSP 10
#define STATE_CMD_MC_LED 11
unsigned char state = STATE_READ_CMD;

void loop()
{
  // if the button changes, send data to DCS
  buttonState = digitalRead(10);
  if (lastButtonState != buttonState) {
    lastButtonState = buttonState;
    // buttonState == HIGH means the button is NOT pushed
    // and the pin is pulled high by the internal pull-up resistor
    if (buttonState == HIGH) {
      Serial.write("MASTER-CAUTION-BTN 0\n");
    } else {
      Serial.write("MASTER-CAUTION-BTN 1\n");
    }
  }
  
  
  // when characters arrive over the serial port...
  while (Serial.available()) {
    char c = Serial.read();
    
    // handle newline character
    if (c == '\n') {
      // whenever we receive a newline character,
      // we reset and expect to receive a command again
      cmd_len = 0;
      state = STATE_READ_CMD;
      continue; // skip the rest of the while loop
    }
    
    // READ_CMD state -- read a command
    if (state == STATE_READ_CMD) {
      if (cmd_len == 16) {
        // if the command buffer fills up, something went wrong.
        // wait for the next newline to reset everything.
        state = STATE_ERROR;
        continue;
      };
      if (c != ' ') {
        // not a space, append character to command buffer
        cmd_buf[cmd_len] = c;
        cmd_len++;
      } else {
        // we are reading a command and got a space.
        // that means the command is complete, so execute it.
        cmd_buf[cmd_len] = '\0'; // null-terminate our command string
        if (strcmp(cmd_buf, "CMSP1") == 0) {
          lcd.setCursor(0,0); // set cursor to beginning of line 1
          state = STATE_CMD_CMSP;
        } else if (strcmp(cmd_buf, "CMSP2") == 0) {
          lcd.setCursor(0,1); // set cursor to beginning of line 2
          state = STATE_CMD_CMSP;
        } else if (strcmp(cmd_buf, "MC-LED") == 0) {
          state = STATE_CMD_MC_LED;
        } else {
          // unknown command, wait for next newline
          state = STATE_ERROR;
        }
      }
    }
    
    // CMD_CMSP state -- copy received characters to LCD
    if (state == STATE_CMD_CMSP) {
      lcd.write(c);
    }
    
    if (state == STATE_CMD_MC_LED) {
      if (c == '0') {
        digitalWrite(13, 0);
      }
      if (c == '1') {
        digitalWrite(13, 1);
      }
    }
    
  }
}
