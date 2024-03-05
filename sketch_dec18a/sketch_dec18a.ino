#include <Wire.h>
#include "RTClib.h"
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
// #include <EEPROMWearLevel.h>
#include <EEPROM.h>
#include <Servo.h>
// EEPROMWearLevel eeprom;

LiquidCrystal_I2C lcd(0x27, 16, 2);


const byte rows = 4;     //số hàng
const byte columns = 4;  //số cột

int holdDelay = 700;  //Thời gian trễ để xem là nhấn 1 nút nhằm tránh nhiễu
int n = 3;            //
int state = 0;        //nếu state =0 ko nhấn,state =1 nhấn thời gian nhỏ , state = 2 nhấn giữ lâu
char key = 0;
//Định nghĩa các giá trị trả về
char keys[rows][columns] = {
  { '1', '2', '3', 'A' },
  { '4', '5', '6', 'B' },
  { '7', '8', '9', 'C' },
  { '*', '0', '#', 'D' },
};
byte rowPins[rows] = { 2, 3, 4, 5 };  //Cách nối chân với Arduino
byte columnPins[columns] = { 6, 7, 8, 9 };
//cài đặt thư viện keypad
Keypad keypad = Keypad(makeKeymap(keys), rowPins, columnPins, rows, columns);

int LDR = 10;
Servo sv;
String pass;

void writeToEEPROM(String data, int address, int length) {
  for (int i = 0; i < length; i++) {
    EEPROM.write(address + i, data[i]);
  }
}

String readFromEEPROM(int address, int length) {
  String result = "";
  for (int i = 0; i < length; i++) {
    char ch = EEPROM.read(address + i);
    result += ch;
  }
  return result;
}

void setup() {
  Serial.begin(9600);  //bật serial, baudrate 9600
  String existingData = readFromEEPROM(0, 8);

  if (existingData.length() == 0) {
    // Nếu chưa có dữ liệu, lưu chuỗi vào EEPROM
    writeToEEPROM("12345678", 0, 8);
    //Serial.println("Data written to EEPROM");
    pass = "12345678";
  } else {
    // Nếu có dữ liệu, in ra Serial Monitor
    //Serial.println("Existing data in EEPROM: " + existingData);
    pass = existingData;
  }
  pinMode(12, INPUT_PULLUP);
  pinMode(LDR, INPUT);
  sv.attach(11);
  sv.write(180);
  lcd.init();
  lcd.backlight();   //đèn nền bật
  lcd.begin(16, 2);  // cài đặt số cột và số dòng
  // in logo lên màn hình
  lcd.print("nhom 4");
  lcd.setCursor(0, 1);
  lcd.print("PHENIKAA");
  delay(2500);
  lcd.clear();
}
String str = "";
String new_pass = "";
//String passWord = "1234";
bool close = true;
bool open = false;
bool new_password = false;
String data = "";
bool closed = true;
int ldr;
int time = 0;
int vitri;
String hidden = "";
int x = 0;
bool checkdoor = false;
void loop() {
  if (digitalRead(12) == 1) {
    if (open == false) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Opening!");
      for (vitri = 180; vitri > 0; vitri--) {
        sv.write(vitri);
        delay(15);
      }
      close = false;
      open = true;
      closed = false;
      delay(2500);
      lcd.clear();
      delay(500);
    }
    if (open == true) {
      if (time < 50) {
        time += 1;
        //Serial.println(time);
        delay(100);
        if (digitalRead(LDR)) {
          time = 0;
        }
      }

      if (time == 50) {
        for (vitri = 0; vitri < 180; vitri++) {
          int ldr1 = digitalRead(LDR);
          sv.write(vitri);
          delay(20);
          if (ldr1) {
            time = 0;
            for (int j = vitri; j >= 0; j--) {
              sv.write(j);
              //Serial.println(j);
              delay(15);
            }
            break;
          }
        }
        if (vitri == 180) {
          open = false;
          close = true;
          time = 0;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("closed!");
          delay(2000);
          lcd.clear();
        }
      }
    }
  }
  if (close) {
    lcd.setCursor(0, 0);
    lcd.print("Enter Password:");
    char temp = keypad.getKey();

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp != 'A' && (char)temp != 'B' && (char)temp != 'C' && (char)temp != 'D' && temp != 0) {
        str += temp;
        hidden += "*";
        lcd.setCursor(x++, 1);
        lcd.print(temp);
        delay(250);
        lcd.setCursor(0, 1);
        lcd.print(hidden);
        //Serial.println(str);
        if (str.length() == 8 && str == pass) {
          delay(600);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Opening!");
          for (vitri = 180; vitri > 0; vitri--) {
            sv.write(vitri);
            delay(15);
          }
          close = false;
          open = true;
          closed = false;
          str = "";
          hidden = "";
          x = 0;
          delay(2500);
          lcd.clear();
        } else if (str.length() == 8 && str != pass) {
          delay(500);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("incorrect");
          lcd.setCursor(0, 1);
          lcd.print("Password!");
          str = "";
          hidden = "";
          x = 0;
          delay(2000);
          lcd.clear();
        }
      }
      if (temp == 'C' && temp != 0) {
        if (str.length() > 0) {
          str.remove(str.length() - 1);
          hidden.remove(hidden.length() - 1);
          x--;
          lcd.clear();
        }
        lcd.setCursor(0, 1);
        lcd.print(hidden);
        //Serial.println(str);
      }
      if (temp == 'D' && temp != 0) {
        str = "";
        new_password = true;
        close = false;
        lcd.clear();
      }
    }
  }
  while (open) {
    lcd.setCursor(0, 0);
    lcd.print("not closed!");
    if (time < 50) {
      time += 1;
      //Serial.println(time);
      delay(100);
      if (digitalRead(LDR)) {
        time = 0;
      }
    }

    if (time == 50) {
      for (vitri = 0; vitri < 180; vitri++) {
        int ldr1 = digitalRead(LDR);
        sv.write(vitri);
        delay(20);
        if (ldr1) {
          time = 0;
          for (int j = vitri; j >= 0; j--) {
            sv.write(j);
            //Serial.println(j);
            delay(15);
          }
          break;
        }
      }
      if (vitri == 180) {
        open = false;
        close = true;
        time = 0;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("closed!");
        if (checkdoor){
          Serial.write('9');
          checkdoor = false;
        }
        
        delay(2000);
        lcd.clear();
      }
    }
  }

  if (new_password) {
    //lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("New Password:");

    char temp = keypad.getKey();

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp != 'A' && (char)temp != 'B' && (char)temp != 'C' && (char)temp != 'B' && temp != 0) {
        new_pass += temp;
        lcd.setCursor(0, 1);
        lcd.print(new_pass);
       //Serial.println(new_pass);
      }
      if (temp == 'B' && temp != 0) {
        new_password = false;
        close = true;
        new_pass = "";
        lcd.clear();
      }
      if (temp == 'C' && temp != 0) {
        if (new_pass.length() > 0) {
          new_pass.remove(new_pass.length() - 1);
          lcd.clear();
        }
        lcd.setCursor(0, 1);
        lcd.print(new_pass);
        //Serial.println(new_pass);
      }
      if (temp == 'A' && temp != 0 && new_pass.length() == 8) {
        writeToEEPROM(new_pass, 0, 8);
        pass = new_pass;
        //Serial.println("Data written to EEPROM");
        //Serial.println(readFromEEPROM(0, 8));
        delay(500);
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("changed!");
        new_pass = "";
        delay(2500);
        lcd.clear();
      }
    }
    delay(100);
  }
  while (Serial.available() > 0) {
    char receivedChar = Serial.read();
    data += receivedChar;
  }
  if (!data.equals("")) {
    if (data.length() == 8) {
      //Serial.println("New Password: " + data);
      lcd.clear();
      lcd.println("changed pass!");
      delay(500);
      lcd.clear();
      writeToEEPROM(data, 0, 8);
      pass = data;
      Serial.write(1);
      data = "";
    } else if (data.equals("ope")){
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Opening!");
      for (vitri = 180; vitri > 0; vitri--) {
        sv.write(vitri);
        delay(15);
      }
      close = false;
      open = true;
      closed = false;
      checkdoor = true;
      delay(2500);
      lcd.clear();
      delay(500);
      //Serial.println(data);
      data = "";
      //Serial.println(data);
      

    }
  }
}