#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ESPmDNS.h>
#include <ArduinoJson.h>
#include "FirebaseESP32.h"
#include <Preferences.h>
#include <NTPClient.h>
#include <TimeLib.h>

String WIFI_SSID = "";
String WIFI_PASSWORD = "";

#define FIREBASE_HOST "https://smart-home-87097-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define FIREBASE_AUTH "AIzaSyAn9GxD1KR6PuzDwuOXuBa4YY035a6hfgY"
String USER_EMAIL = "";
String USER_PASSWORD = "";
String UID = "";
String userPath = "";
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

///////////////////------------------------ Xử lí kết nối -------------------------------/////////////////////////////////////////////////////////////
////// WiFi --- Firebase
bool connectToWiFi() {
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(WIFI_SSID);
  // lcd.clear();
  // lcd.setCursor(0, 0);
  // lcd.print("Connecting Wifi");
  // lcd.setCursor(0, 1);
  // lcd.print(WIFI_SSID);
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID.c_str(), WIFI_PASSWORD.c_str());
  String dot = "";
  int timer = 0;
  bool iscnt = true;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    timer++;
    dot += ".";
    // if (dot.length() == 4) {
    //   dot = "";
    //   lcd.clear();
    //   lcd.setCursor(0, 0);
    //   lcd.print("Connecting Wifi");
    // }
    // lcd.setCursor(0, 1);
    // lcd.print(WIFI_SSID + dot);
    Serial.print(".");
    if (timer == 30) {
      iscnt = false;
      //WiFi.disconnect(true);
      // lcd.clear();
      // lcd.setCursor(0, 0);
      // lcd.print("Unable to/nconnect WiFi");
      // delay(2000);
      // lcd.clear();
      break;
    }
  }
  if (iscnt) {
    Serial.println("");
    Serial.println("WiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // lcd.clear();
    // lcd.setCursor(0, 0);
    // lcd.print("WiFi connected");
    // lcd.setCursor(0, 1);
    // lcd.print("IP: ");
    // lcd.print(WiFi.localIP());
    // lcd.clear();
    return true;
  }
  return false;  // Trả về false nếu không kết nối được WiFi
}
bool hasCharacters(String str) {
  return str.length() > 0;
}
bool connectFirebase() {
  if (hasCharacters(FIREBASE_AUTH) && hasCharacters(FIREBASE_HOST) && hasCharacters(USER_EMAIL) && hasCharacters(USER_PASSWORD)) {
    // Cấu hình Firebase
    config.api_key = FIREBASE_AUTH;
    config.database_url = FIREBASE_HOST;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    // Khởi động Firebase
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    //Firebase.signUp(&config, &auth, USER_EMAIL, USER_PASSWORD);
    UID = String(auth.token.uid.c_str());
    userPath = "/users/" + UID + "/esp32-led";

    if (Firebase.ready()) {
      Serial.println(userPath);
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////------------------------- Lưu trữ dữ thông tin --------------------------////////////////////////////////////////////////////////////
// Tạo EEPROM
Preferences eeprom;

int pin[5] = { 19, 5, 16, 0, 15 };
int spin[5];
String pinName[5] = { "pin1", "pin2", "pin3", "pin4", "pin5" };
String ledName[5];
String pinNotUsed[5];
String pinUsed[5];
int numPinNotUsed = 0;
int numPinUsed = 0;
int numLed = 0;
int findIndex(String arr[], String value) {
  for (int i = 0; i < 5; i++) {
    if (arr[i] == value) {
      return i;
    }
  }
  return -1;
}

void getLed() {
  numLed = 0;
  eeprom.begin("led", false);
  for (int i = 0; i <= 4; i++) {
    bool check = eeprom.isKey(String(pin[i]).c_str()) && eeprom.getString(String(pin[i]).c_str()).length() > 0;
    if (check) {
      ledName[i] = eeprom.getString(String(pin[i]).c_str());
      numLed++;
    } else {
      eeprom.putString(String(pin[i]).c_str(), "");
    }
  }
  eeprom.end();
}
void setLed(String spin, String ledname) {
  int i = findIndex(pinName, spin);
  eeprom.begin("led", false);
  eeprom.putString(String(pin[i]).c_str(), ledname);
  eeprom.end();
}
void unSetLed(String spin) {
  int i = findIndex(pinName, spin);
  eeprom.begin("led", false);
  eeprom.putString(String(pin[i]).c_str(), "");
  eeprom.end();
}
void getPin() {
  numPinNotUsed = 0;
  numPinUsed = 0;
  eeprom.begin("pin", false);
  for (int i = 0; i <= 4; i++) {
    if (eeprom.isKey(pinName[i].c_str())) {
      if (eeprom.getBool(pinName[i].c_str())) {
        pinUsed[numPinUsed] = pinName[i];
        numPinUsed++;
      } else {
        pinNotUsed[numPinNotUsed] = pinName[i];
        numPinNotUsed++;
      }
    } else {
      eeprom.putBool(pinName[i].c_str(), false);
    }
  }
  eeprom.end();
}
void setPin(String pinname) {
  eeprom.begin("pin", false);
  eeprom.putBool(pinname.c_str(), true);
  eeprom.end();
}
void unSetPin(String pinname) {
  eeprom.begin("pin", false);
  eeprom.putBool(pinname.c_str(), false);
  eeprom.end();
}
bool setWiFiInfo() {
  if (hasCharacters(WIFI_SSID) && hasCharacters(WIFI_PASSWORD)) {
    eeprom.begin("my-app", false);
    eeprom.putString("ssid", WIFI_SSID);
    eeprom.putString("password", WIFI_PASSWORD);
    eeprom.end();
    return true;
    Serial.println("ok");
  } else {
    return false;
  }
}
bool checkWifiInfo() {
  eeprom.begin("my-app", true);
  bool check = eeprom.isKey("ssid") && eeprom.isKey("password") && eeprom.getString("ssid").length() > 0 && eeprom.getString("password").length() > 0;
  if (check) {
    WIFI_SSID = eeprom.getString("ssid");
    WIFI_PASSWORD = eeprom.getString("password");
  }
  eeprom.end();
  return check;
}
bool setFirebaseInfo() {
  if (hasCharacters(USER_EMAIL) && hasCharacters(USER_PASSWORD)) {
    eeprom.begin("my-app", false);
    eeprom.putString("user_email", USER_EMAIL);
    eeprom.putString("user_password", USER_PASSWORD);
    eeprom.end();
    return true;
  } else {
    return false;
  }
}
bool checkFirebaseInfo() {
  eeprom.begin("my-app", true);
  bool check = eeprom.isKey("user_email") && eeprom.isKey("user_password") && eeprom.getString("user_email").length() > 0 && eeprom.getString("user_password").length() > 0;
  if (check) {
    USER_EMAIL = eeprom.getString("user_email");
    USER_PASSWORD = eeprom.getString("user_password");
  }
  eeprom.end();
  return check;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////------------------------- Xử lí kết nối server -----------------------------------------//////////////////////////////////////////////////////////////
// Tạo một đối tượng AsyncWebServer trên cổng 80
AsyncWebServer server(80);

void handleGetPinRequest(AsyncWebServerRequest *request) {
  request->send(200, "text/plain", pinName[0] + " " + pinName[1] + " " + pinName[2] + " " + pinName[3] + " " + pinName[4]);
}

void handleGetPinNotUsedRequest(AsyncWebServerRequest *request) {
  StaticJsonDocument<200> jsonDoc;
  JsonArray pinArray = jsonDoc.createNestedArray("pins");
  getPin();
  for (int i = 0; i < numPinNotUsed; i++) {
    pinArray.add(pinNotUsed[i]);
  }
  String jsonString;
  serializeJson(jsonDoc, jsonString);
  request->send(200, "application/json", jsonString);
}
void handleSetLedRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("led")) {
    String led = request->getParam("led")->value();
    setLed(sPin,led);
    request->send(200, "text/plain", "add pin" + led);
  } else {
    request->send(400, "text/plain", "fail");
  }
}
void handleUnSetLedRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("pin")) {
    String pin = request->getParam("pin")->value();
    unSetPin(pin);
    request->send(200, "text/plain", "remove pin" + pin);
  } else {
    request->send(400, "text/plain", "fail");
  }
}
String sPin = "";
void handleSetPinRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("pin")) {
    sPin = request->getParam("pin")->value();
    setPin(sPin);
    request->send(200, "text/plain", "add pin" + sPin);
  } else {
    request->send(400, "text/plain", "fail");
  }
}

void handleUnSetPinRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("pin")) {
    String pin = request->getParam("pin")->value();
    unSetPin(pin);
    request->send(200, "text/plain", "remove pin" + pin);
  } else {
    request->send(400, "text/plain", "fail");
  }
}
void handleSaveDataRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("save")) {
    if (request->getParam("save")->value() == "save") {
      setFirebaseInfo();
      request->send(200, "text/plain", "USER_PASSWORD set to ");
    }
  } else {
    request->send(400, "text/plain", "Missing USER_PASSWORD parameter");
  }
}
void handleSetUSEREMAILRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("user-email")) {
    USER_EMAIL = request->getParam("user-email")->value();
    request->send(200, "text/plain", "USER_EMAIL set to " + USER_EMAIL);
  } else {
    request->send(400, "text/plain", "Missing USER_EMAIL parameter");
  }
}

void handleSetUSERPASSWORDRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("user-password")) {
    USER_PASSWORD = request->getParam("user-password")->value();
    request->send(200, "text/plain", "USER_PASSWORD set to " + USER_PASSWORD);
  } else {
    request->send(400, "text/plain", "Missing USER_PASSWORD parameter");
  }
}
// Xử lý yêu cầu kiểm tra UID của thiết bị
void handleCheckUIDRequest(AsyncWebServerRequest *request) {
  String currentUID = request->getParam("uid")->value();
  connectFirebase();
  if (currentUID.equals(UID)) {
    request->send(200, "text/plain", "ok");

  } else {
    request->send(400, "text/plain", "UID does not match");
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void setup() {
  Serial.begin(115200);
  bool wf;
  // Kết nối WiFi
  if (checkWifiInfo()) {
    Serial.println(WIFI_SSID);
    Serial.println(WIFI_PASSWORD);
    wf = connectToWiFi();
  } else {
    setWiFiInfo();
  }

  // setup user auth
  if (checkFirebaseInfo() && wf) {
    Serial.println(USER_EMAIL);
    Serial.println(USER_PASSWORD);
    if (connectFirebase()) {
      Serial.println("ok");
    }
  } else {
    setFirebaseInfo();
  }
  // configMDNS();
  if (!MDNS.begin("esp32-led")) {
    Serial.println("Error setting up mDNS responder!");
    while (1) {
      delay(100);
    }
  }
  Serial.println("mDNS responder started");

  // Thêm dịch vụ HTTP
  MDNS.addService("http", "tcp", 80);

  server.on("/get-pin", HTTP_GET, handleGetPinRequest);
  server.on("/get-pinNotUsed", HTTP_GET, handleGetPinNotUsedRequest);
  server.on("/set-pin", HTTP_GET, handleSetPinRequest);
  server.on("/unset-pin", HTTP_GET, handleUnSetPinRequest);
  server.on("/set_user-email", HTTP_GET, handleSetUSEREMAILRequest);
  server.on("/set_user-password", HTTP_GET, handleSetUSERPASSWORDRequest);
  server.on("/save-data", HTTP_GET, handleSaveDataRequest);
  server.on("/check_uid", HTTP_GET, handleCheckUIDRequest);
  server.begin();
  Serial.println("HTTP server started");
  getLed();
  getPin();
  for (int i = 0; i < numPinUsed; i++) {
    pinMode(pin[findIndex(pinName, pinUsed[i])], OUTPUT);
    spin[i] = pin[findIndex(pinName, pinUsed[i])];
  }
}

void loop() {
  // delay(3000);
  // if (Firebase.getJSON(fbdo, userPath)) {
  //   FirebaseJson json = fbdo.jsonObject();
  //   FirebaseJsonData jsondata;

  //   // for(int i = 0; i < numLed; i++)
  //   // Lấy thông tin cho đèn den2
  //   if (json.get(jsondata, "den2")) {
  //     Serial.println("Den2 Status:");
  //     Serial.println("AutoMode: " + String(jsondata.to<FirebaseJson>()->get("AutoMode").as<bool>()));
  //     Serial.println("OffTime: " + jsondata.to<FirebaseJson>()->get("offTime").as<String>());
  //     Serial.println("OnTime: " + jsondata.to<FirebaseJson>()->get("onTime").as<String>());
  //     Serial.println("Status: " + String(jsondata.to<FirebaseJson>()->get("status").as<bool>()));
  //   }

  //   // Lấy thông tin cho đèn den3
  //   if (json.get(jsondata, "den3")) {
  //     Serial.println("Den3 Status:");
  //     Serial.println("AutoMode: " + String(jsondata.to<FirebaseJson>()->get("AutoMode").as<bool>()));
  //     Serial.println("OffTime: " + jsondata.to<FirebaseJson>()->get("offTime").as<String>());
  //     Serial.println("OnTime: " + jsondata.to<FirebaseJson>()->get("onTime").as<String>());
  //     Serial.println("Status: " + String(jsondata.to<FirebaseJson>()->get("status").as<bool>()));
  //   }
  // } else {
  //   Serial.println("Failed to get data from Firebase.");
  //   Serial.println("Reason: " + fbdo.errorReason());
  // }
}
