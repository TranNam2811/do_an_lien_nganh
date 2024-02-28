#include <Arduino.h>
#include<ESP8266WiFi.h>
#include "FirebaseESP8266.h"
#include <ArduinoJson.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

#include<SoftwareSerial.h> //Included SoftwareSerial Library
//Started SoftwareSerial at RX and TX pin of ESP8266/NodeMCU
SoftwareSerial s(3, 1);

// #define WIFI_SSID "Dam Giang T5"
// #define WIFI_PASSWORD "17181921"

// #define WIFI_SSID "P1202"
// #define WIFI_PASSWORD "88888888"
#define WIFI_SSID "Bunn"
#define WIFI_PASSWORD "20032022"


#define FIREBASE_HOST "https://henhung01-default-rtdb.firebaseio.com/" //Thay bằng địa chỉ firebase của bạn
#define FIREBASE_AUTH "AIzaSyAgXEgWLu3swzvs0q6LHSVbYwukdBiqthw" //projec setting > service account > database secrets
#define USER_EMAIL "ptn@gmail.com"
#define USER_PASSWORD "01102003"
// #define fan D1

FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
   //Serial.begin(115200);
   s.begin(9600);
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
int data;
void loop() {
  Firebase.getInt(firebaseData, "/led");
  int changed = firebaseData.intData();
  
  if(changed) {
    Firebase.getString(firebaseData, "/password");
    String passValue = firebaseData.stringData();
    char charArray[passValue.length() + 1];
    passValue.toCharArray(charArray, passValue.length() + 1);
    s.write(charArray);
    delay(5000);
    int data = s.read();
    if(data){
      Firebase.setInt(firebaseData, "/led", 0);
    }
    // Firebase.setInt(firebaseData, "/led", 0);  // Đặt lại giá trị của /led sau khi xử lý
  }
}
