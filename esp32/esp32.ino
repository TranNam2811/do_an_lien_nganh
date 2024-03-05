#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClient.h>
//#include <ESP8266WiFi.h>
//#include "FirebaseESP8266.h"
#include "FirebaseESP32.h"
#include <ArduinoJson.h>
#include <LiquidCrystal_I2C.h>
#include <Wire.h>
#include "RTClib.h"
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// #include<SoftwareSerial.h> //Included SoftwareSerial Library
// //Started SoftwareSerial at RX and TX pin of ESP8266/NodeMCU
// //SoftwareSerial s(3, 1);

// #define WIFI_SSID "Dam Giang T5"
// #define WIFI_PASSWORD "17181921"

#define WIFI_SSID "P1202"
#define WIFI_PASSWORD "88888888"
// #define WIFI_SSID "Bunn"
// #define WIFI_PASSWORD "20032022"


#define FIREBASE_HOST "https://henhung01-default-rtdb.firebaseio.com/"  //Thay bằng địa chỉ firebase của bạn
#define FIREBASE_AUTH "AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw"         //projec setting > service account > database secrets
#define USER_EMAIL "ptn@gmail.com"
#define USER_PASSWORD "01102003"
// #define fan D1

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;
RTC_DS1307 RTC;
void setup() {
  Serial.begin(115200);
  Serial2.begin(9600);
  //s.begin(9600);
  // Két nối wifi.
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("connecting");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();
  Serial.print("connected: ");
  Serial.println(WiFi.localIP());

Wire.begin();
  Wire.beginTransmission(0x68);// địa chỉ của ds1307
  Wire.write(0x07); // 
  Wire.write(0x10); // 
  Wire.endTransmission();
  
  RTC.begin();

  config.api_key = FIREBASE_AUTH;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = FIREBASE_HOST;
  Firebase.reconnectWiFi(true);
  firebaseData.setResponseSize(4096);
  config.token_status_callback = tokenStatusCallback;
  config.max_token_generation_retry = 5;
  Firebase.begin(&config, &auth);
  // pinMode(fan, OUTPUT);
}
bool checkdoor = false;
void loop() {
  Firebase.getInt(firebaseData, "/led");
  int changed = firebaseData.intData();

  if (changed) {
    Firebase.getString(firebaseData, "/password");
    String passValue = firebaseData.stringData();
    char charArray[passValue.length() + 1];
    passValue.toCharArray(charArray, passValue.length() + 1);
    Serial2.write(charArray);
    delay(500);
    int data = Serial2.read();
    if (data) {
      Firebase.setInt(firebaseData, "/led", 0);
    }
  }

  Firebase.getBool(firebaseData, "/door");
  bool door = firebaseData.boolData();
  Serial.println(door);
  DateTime now = RTC.now();
String x = String(int(now.hour()));
  x+= ':';
  x+= String(int(now.minute()));
  x+= ':';
  x+= String(int(now.second()));
  x+= '-';
  x+= String(int(now.day()));
  x+= '/';
  x+= String(int(now.month()));
  x+= '/';
  x+= String(int(now.year()));

  Serial.println(x);
  if (checkdoor == false) {
    if (door == true) {
      String pass = "ope";
      Serial.println(checkdoor);
      char charArray[pass.length() + 1];
      pass.toCharArray(charArray, pass.length() + 1);
      Serial2.write(charArray);
      checkdoor = true;
      Serial.println(checkdoor);
      Firebase.pushString( firebaseData,"/open", x);
      // Firebase.setInt( firebaseData,"/bbb", 100);
    }
  } else {
    char data = Serial2.read();
    Serial.println(data);
    if (data == '9') {
      checkdoor = false;
      Firebase.setBool(firebaseData, "/door", false);
      Firebase.pushString( firebaseData,"/close", x);
      Serial.println(checkdoor);
    }
  }
}
