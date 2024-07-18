#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ESPmDNS.h>
#include "FirebaseESP32.h"
#include <Preferences.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ESP32Servo.h>
#include <Keypad.h>
#include <NTPClient.h>
#include <TimeLib.h>

// real time
WiFiUDP ntpUDP;
NTPClient real_time(ntpUDP, "pool.ntp.org", 0, 60000);
// Tạo EEPROM
Preferences eeprom;
// Tạo một đối tượng AsyncWebServer trên cổng 80
AsyncWebServer server(80);
// Mật khẩu cửa
String PASS = "";
// Led lcd
LiquidCrystal_I2C lcd(0x27, 16, 2);

////////////////////////// Thông tin kết nối WiFi///////////////////////////////////////////////////////
// String WIFI_SSID = "BMTNLK 2.4G";
// String WIFI_PASSWORD = "10042022";
String WIFI_SSID = "";
String WIFI_PASSWORD = "";

//////////////////////// Khởi tạo FireBase ///////////////////////////////////////////////////////////////////////////////
#define FIREBASE_HOST "https://smart-home-87097-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define FIREBASE_AUTH "AIzaSyAn9GxD1KR6PuzDwuOXuBa4YY035a6hfgY"
String USER_EMAIL = "nam@gmail.com";
String USER_PASSWORD = "nam1234";
String UID = "";
String userPath = "";
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

bool isFirebaseConnected = false;
bool isWifiConnected = false;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// // Xử lý yêu cầu để lấy UID của thiết bị
// void handleGetUIDRequest(AsyncWebServerRequest *request) {
//   request->send(200, "text/plain", UID);
// }

// Xử lý yêu cầu để thiết lập USER_EMAIL của thiết bị
void handleSetUSEREMAILRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("user-email")) {
    USER_EMAIL = request->getParam("user-email")->value();
    setFirebaseInfo();
    request->send(200, "text/plain", "USER_EMAIL set to " + USER_EMAIL);
  } else {
    request->send(400, "text/plain", "Missing USER_EMAIL parameter");
  }
}

void handleSetUSERPASSWORDRequest(AsyncWebServerRequest *request) {
  if (request->hasParam("user-password")) {
    USER_PASSWORD = request->getParam("user-password")->value();
    setFirebaseInfo();
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
    if (Firebase.setString(fbdo, userPath + "/esp32-door/password", PASS)) {
      Serial.println("change ok");
    } else {
      Serial.println("fail");
    }
  } else {
    request->send(400, "text/plain", "UID does not match");
  }
}

//////////////////////////// Đọc/Ghi EEPROM ////////////////////////////////////////////////////////////////////////////
bool hasCharacters(String str) {
  return str.length() > 0;
}

// Hàm kiểm tra thông tin Pass
bool checkPassInfo() {
  eeprom.begin("my-app", true);
  bool check = eeprom.isKey("pass") && eeprom.getString("pass").length() > 0;
  if (check) {
    PASS = eeprom.getString("pass");  // Gán giá trị từ EEPROM cho biến PASS
  }
  eeprom.end();
  return check;
}

// Hàm thiết lập thông tin Pass
bool setPassInfo(String pass) {
  if (hasCharacters(pass)) {
    eeprom.begin("my-app", false);
    eeprom.putString("pass", pass);
    eeprom.end();
    PASS = pass;  // Cập nhật giá trị mới cho biến PASS
    return true;
  } else {
    return false;
  }
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////// Thiết lập mDNS //////////////////////////////////////////////////////////////////////////////////



///////////////////////// Kết nối Wifi ////////////////////////////////////////////////////////////////////////////////////

const int MAX_NETWORKS = 20;        // Số lượng mạng tối đa để lưu lại
String wifiNetworks[MAX_NETWORKS];  // Mảng để lưu các SSID
int numNetworks = 0;                // Số lượng mạng tìm được
bool isConnectedWifi;
void scanWifi() {
  WiFi.mode(WIFI_STA);
  //WiFi.disconnect();
  numNetworks = 0;
  lcd.setCursor(0, 0);
  lcd.print("Scaning WiFi...");
  int numScanNetworks = WiFi.scanNetworks();
  lcd.clear();

  if (numScanNetworks == -1) {
    lcd.setCursor(0, 0);
    lcd.print("Couldn't get a WiFi");
    delay(2000);
    lcd.clear();
  } else {
    Serial.print("Found ");
    Serial.print(numScanNetworks);
    Serial.println(" networks");

    // Lưu các SSID vào mảng
    for (int i = 0; i < numScanNetworks; ++i) {
      if (numNetworks < MAX_NETWORKS) {
        wifiNetworks[numNetworks] = WiFi.SSID(i);
        numNetworks++;
      } else {
        Serial.println("Exceeded max number of networks");
        break;
      }
    }
  }
}

bool connectToWiFi() {
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(WIFI_SSID);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting Wifi");
  lcd.setCursor(0, 1);
  lcd.print(WIFI_SSID);
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID.c_str(), WIFI_PASSWORD.c_str());
  String dot = "";
  int timer = 0;
  bool iscnt = true;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    timer++;
    dot += ".";
    if (dot.length() == 4) {
      dot = "";
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Connecting Wifi");
    }
    lcd.setCursor(0, 1);
    lcd.print(WIFI_SSID + dot);
    Serial.print(".");
    if (timer == 30) {
      iscnt = false;
      //WiFi.disconnect(true);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Unable to/nconnect WiFi");
      delay(2000);
      lcd.clear();
      break;
    }
  }
  if (iscnt) {
    Serial.println("");
    Serial.println("WiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi connected");
    lcd.setCursor(0, 1);
    lcd.print("IP: ");
    lcd.print(WiFi.localIP());
    lcd.clear();
    return true;
  }
  return false;  // Trả về false nếu không kết nối được WiFi
}

///////////////////////// Kết nối Firebase ////////////////////////////////////////////////////////////////////////////////

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
    userPath = "/users/" + UID;
    
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
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Status connect //////////////////////////////////////////////////////////////////////////////

void statusConnect() {
  if (isFirebaseConnected) {
    digitalWrite(8, HIGH);
  } else {
    digitalWrite(8, LOW);
  }
  if (isWifiConnected) {
    digitalWrite(9, HIGH);
  } else {
    digitalWrite(9, LOW);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////// get real time ///////////////////////////////////////////////////////////////////////////////

String getRTC() {
  real_time.begin();
  real_time.update();
  unsigned long currentTime = real_time.getEpochTime();
  currentTime += 7 * 3600;
  setTime(currentTime);
  real_time.end();
  return String(hour()) + ":" + String(minute()) + ":" + String(second()) + " " + String(day()) + "/" + String(month()) + "/" + String(year());
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////// Khởi tạo keypad ///////////////////////////////////////////////////////////////////////////////////////////////////
const byte rows = 4;     //số hàng
const byte columns = 4;  //số cột
//Định nghĩa các giá trị trả về
char keys[rows][columns] = {
  { '1', '2', '3', 'A' },
  { '4', '5', '6', 'B' },
  { '7', '8', '9', 'C' },
  { '*', '0', '#', 'D' },
};
uint8_t rowPins[rows] = { 33, 25, 26, 14 };
uint8_t columnPins[columns] = { 27, 13, 19, 4 };
Keypad keypad = Keypad(makeKeymap(keys), rowPins, columnPins, rows, columns);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int LDR = 2;
int buzzer = 15;
Servo sv;

void setup() {
  Serial.begin(115200);
  lcd.init();
  lcd.backlight();   //đèn nền bật
  lcd.begin(16, 2);  // cài đặt số cột và số dòng
  pinMode(buzzer, OUTPUT);
  pinMode(LDR, INPUT);
  sv.attach(5);
  sv.write(180);

  // Setup pass
  if (checkPassInfo()) {
    Serial.println("PASS loaded from EEPROM: " + PASS);
  } else {
    setPassInfo("12345678");  // Nếu không có, thiết lập mặc định
    Serial.println("Default PASS set: " + PASS);
  }
  bool wf;
  // Kết nối WiFi
  if (checkWifiInfo()) {

    Serial.println(WIFI_SSID);
    Serial.println(WIFI_PASSWORD);
    wf = connectToWiFi();
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
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error connect");
    lcd.setCursor(0, 1);
    lcd.print("server");
    delay(2000);
    lcd.clear();
  }

  // configMDNS();
  if (!MDNS.begin("esp32-door")) {
    Serial.println("Error setting up mDNS responder!");
    while (1) {
      delay(100);
    }
  }
  Serial.println("mDNS responder started");

  // Thêm dịch vụ HTTP
  MDNS.addService("http", "tcp", 80);

  // Đăng ký các xử lý yêu cầu HTTP
  // server.on("/get_uid", HTTP_GET, handleGetUIDRequest);
  server.on("/set_user-email", HTTP_GET, handleSetUSEREMAILRequest);
  server.on("/set_user-password", HTTP_GET, handleSetUSERPASSWORDRequest);
  server.on("/check_uid", HTTP_GET, handleCheckUIDRequest);

  // Bắt đầu server
  server.begin();
  Serial.println("HTTP server started");

  // in logo lên màn hình
  lcd.print("nhom 4");
  lcd.setCursor(0, 1);
  lcd.print("PHENIKAA");
  delay(2500);
  lcd.clear();
}

String str = "";
String new_pass = "";
String selectedSSID = "";
String passWifi = "";
bool isClose = true;
bool isOpen = false;
bool isMode = false;
bool isChangePassword = false;
bool isConnect = false;
bool isWifi = false;
bool isScanWifi = false;
bool isSelected = false;
bool isPassTrue = false;
String hidden = "";
int x = 0;
int i = 0;
int k = 47;
unsigned long t;

void loop() {
  if (isClose) {
    lcd.setCursor(0, 0);
    lcd.print("Enter Password:");
    char temp = keypad.getKey();
    if (millis() - t > 3000) {
      if (WiFi.status() == WL_CONNECTED && Firebase.ready()) {
        if (Firebase.getBool(fbdo, userPath + "/esp32-door/status")) {
          Serial.println(random(0, 99));
          if (fbdo.boolData()) {
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Open");
            for (int vitri = 180; vitri > 0; vitri--) {
              sv.write(vitri);
            }
            if (Firebase.pushString(fbdo, userPath + "/esp32-door/hisopen", getRTC())) {
              Serial.println("ok");
            } else {
              Serial.println("fail");
            }
            isClose = false;
            isOpen = true;
            str = "";
            hidden = "";
            x = 0;
            t = millis();
            lcd.clear();
          }
        }
        if (Firebase.getString(fbdo, userPath + "/esp32-door/password")) {
          if (fbdo.stringData() != PASS) {
            PASS = fbdo.stringData();
            setPassInfo(PASS);
            Serial.println("newpass");
          }
        }
      }
      t = millis();
    }

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp != 'A' && (char)temp != 'B' && (char)temp != 'C' && (char)temp != 'D' && temp != 0) {
        str += temp;
        Serial.println(str);
        hidden += "*";
        lcd.setCursor(x++, 1);
        lcd.print(temp);
        delay(250);
        lcd.setCursor(0, 1);
        lcd.print(hidden);
        if (str.length() == 8 && str == PASS) {
          delay(600);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Open");
          for (int vitri = 180; vitri >= 90; vitri--) {
            sv.write(vitri);
          }
          if (WiFi.status() == WL_CONNECTED && Firebase.ready()) {

            if (Firebase.pushString(fbdo, userPath + "/esp32-door/hisopen", getRTC())) {
              Serial.println("ok");
            } else {
              Serial.println("fail");
            }
            Firebase.setBool(fbdo, userPath + "/esp32-door/status", true);
          }

          isClose = false;
          isOpen = true;
          str = "";
          hidden = "";
          x = 0;
          t = millis();
          lcd.clear();
        } else if (str.length() == 8 && str != PASS) {
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
      }
      if (temp == 'D' && temp != 0) {
        str = "";
        isMode = true;
        isClose = false;
        lcd.clear();
      }
    }
  }
  if (isOpen) {
    lcd.setCursor(0, 0);
    lcd.print("Open");

    if (millis() - t > 10000) {
      t = millis();
      digitalWrite(buzzer, HIGH);
    }
    char temp = keypad.getKey();
    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp == 'B') {
        digitalWrite(buzzer, LOW);
        for (int vitri = 90; vitri <= 180; vitri++) {
          sv.write(vitri);
        }
        isOpen = false;
        isClose = true;
        lcd.clear();
        if (WiFi.status() == WL_CONNECTED && Firebase.ready()) {

          if (Firebase.pushString(fbdo, userPath + "/esp32-door/hisclose", getRTC())) {
            Serial.println("ok");
          } else {
            Serial.println("fail");
          }
          Firebase.setBool(fbdo, userPath + "/esp32-door/status", false);
        }
      }
    }
  }
  if (isMode) {
    lcd.setCursor(0, 0);
    lcd.print("1:Change Password");
    lcd.setCursor(0, 1);
    lcd.print("2:Connect");
    char temp = keypad.getKey();

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp == '1') {
        isMode = false;
        isChangePassword = true;
        lcd.clear();
      }
      if ((char)temp == '2') {
        isMode = false;
        isConnect = true;
        lcd.clear();
      }
      if ((char)temp == 'B') {
        isMode = false;
        isClose = true;
        isOpen = false;
        lcd.clear();
      }
    }
  }
  if (isConnect) {
    lcd.setCursor(0, 0);
    lcd.print("1:Wifi");
    lcd.setCursor(0, 1);
    lcd.print("2:Bluetooh");
    char temp = keypad.getKey();

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp == '1') {
        isWifi = true;
        isConnect = false;
        lcd.clear();
      }
      if ((char)temp == '2') {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("null");
        delay(2000);
        lcd.clear();
      }
      if ((char)temp == 'B') {
        isMode = true;
        isConnect = false;
        lcd.clear();
      }
    }
  }
  if (isWifi) {
    lcd.setCursor(0, 0);
    lcd.print("1:Scan Wifi");
    lcd.setCursor(0, 1);
    lcd.print("2:Disconnect");
    char temp = keypad.getKey();

    if ((int)keypad.getState() == PRESSED) {
      if ((char)temp == '1') {
        isScanWifi = true;
        isWifi = false;
        lcd.clear();
      }
      if ((char)temp == '2') {
      }
      if ((char)temp == 'B') {
        isConnect = true;
        isWifi = false;
        lcd.clear();
      }
    }
  }
  if (isScanWifi) {
    if (WiFi.status() != WL_CONNECTED && numNetworks == 0) {
      WiFi.disconnect(true);
    }
    if (numNetworks == 0) {
      scanWifi();
    }
    char temp = keypad.getKey();
    if (!isSelected) {
      lcd.setCursor(0, 0);
      lcd.print("Select Wifi:");
      lcd.setCursor(0, 1);
      lcd.print(wifiNetworks[i]);
      if ((int)keypad.getState() == PRESSED) {
        if ((char)temp == '6') {
          lcd.clear();
          i++;
          if (i == numNetworks) {
            i = 0;
            lcd.setCursor(0, 1);
            lcd.print(wifiNetworks[i]);
          } else {
            lcd.setCursor(0, 1);
            lcd.print(wifiNetworks[i]);
          }
        }
        if ((char)temp == '4') {
          lcd.clear();
          i--;
          if (i < 0) {
            i = numNetworks - 1;
            lcd.setCursor(0, 1);
            lcd.print(wifiNetworks[i]);
          } else {
            lcd.setCursor(0, 1);
            lcd.print(wifiNetworks[i]);
          }
        }
        if ((char)temp == '5') {
          WIFI_SSID = wifiNetworks[i];
          Serial.println(WIFI_SSID);
          isSelected = true;
          lcd.clear();
        }
        if ((char)temp == 'B') {
          isScanWifi = false;
          isWifi = true;
          numNetworks = 0;
          lcd.clear();
        }
      }
    }
    if (isSelected) {
      lcd.setCursor(0, 0);
      lcd.print("Enter password:");
      if ((int)keypad.getState() == PRESSED) {
        if ((char)temp == '2') {
          k++;
          if (k > 122) {
            k = 48;
          }
          lcd.setCursor(passWifi.length(), 1);
          lcd.print(char(k));
        }
        if ((char)temp == '8') {
          k--;
          if (k < 48) {
            k = 122;
          }
          lcd.setCursor(passWifi.length(), 1);
          lcd.print(char(k));
        }
        if ((char)temp == '5') {
          if (k >= 48 && k <= 122) {
            passWifi += char(k);
            k = 47;
          }
          lcd.setCursor(0, 1);
          lcd.print(passWifi + "_");
        }
        if ((char)temp == 'C') {
          if (passWifi.length() > 0) {
            passWifi.remove(passWifi.length() - 1);
            lcd.clear();
          }
          lcd.setCursor(0, 1);
          lcd.print(passWifi + "_");
        }
        if ((char)temp == 'B') {
          isSelected = false;
          numNetworks = 0;
          lcd.clear();
        }
        if ((char)temp == 'A') {
          WIFI_PASSWORD = passWifi;
          passWifi = "";
          Serial.println(WIFI_PASSWORD);
          bool a = connectToWiFi();
          if (a) {
            setWiFiInfo();
          }
          if (a && !Firebase.ready()) {
            connectFirebase();
          }
          delay(2000);
          isSelected = false;
          numNetworks = 0;
          isWifi = true;
          isScanWifi = false;
          lcd.clear();
        }
      }
    }
  }

  if (isChangePassword) {


    char temp = keypad.getKey();
    if (!isPassTrue) {
      lcd.setCursor(0, 0);
      lcd.print("Old Password:");
      if ((int)keypad.getState() == PRESSED) {
        if ((char)temp != 'A' && (char)temp != 'B' && (char)temp != 'C' && (char)temp != 'B' && temp != 0) {
          new_pass += temp;
          Serial.println(new_pass);
          hidden += "*";
          lcd.setCursor(x++, 1);
          lcd.print(temp);
          delay(250);
          lcd.setCursor(0, 1);
          lcd.print(hidden);
        }
        if (temp == 'B' && temp != 0) {
          isChangePassword = false;
          isMode = true;
          new_pass = "";
          hidden = "";
          x = 0;
          lcd.clear();
        }
        if (temp == 'C' && temp != 0) {
          if (new_pass.length() > 0) {
            str.remove(new_pass.length() - 1);
            hidden.remove(hidden.length() - 1);
            x--;
            lcd.clear();
          }
          lcd.setCursor(0, 1);
          lcd.print(hidden);
        }
        if (temp == 'A' && temp != 0 && new_pass == PASS) {
          new_pass = "";
          isPassTrue = true;
          hidden = "";
          x = 0;
          lcd.clear();
        } else if (temp == 'A' && temp != 0 && new_pass != PASS) {
          new_pass = "";
          hidden = "";
          x = 0;
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("incorect");
          lcd.setCursor(0, 1);
          lcd.print("password");
          delay(2000);
          lcd.clear();
        }
      }
    }
    if (isPassTrue) {
      lcd.setCursor(0, 0);
      lcd.print("New Password:");
      if ((int)keypad.getState() == PRESSED) {
        if ((char)temp != 'A' && (char)temp != 'B' && (char)temp != 'C' && (char)temp != 'B' && temp != 0) {
          new_pass += temp;
          Serial.println(new_pass);
          hidden += "*";
          lcd.setCursor(x++, 1);
          lcd.print(temp);
          delay(250);
          lcd.setCursor(0, 1);
          lcd.print(hidden);
        }
        if (temp == 'B' && temp != 0) {
          isChangePassword = false;
          isMode = true;
          new_pass = "";
          hidden = "";
          x = 0;
          lcd.clear();
        }
        if (temp == 'C' && temp != 0) {
          if (new_pass.length() > 0) {
            str.remove(new_pass.length() - 1);
            hidden.remove(hidden.length() - 1);
            x--;
            lcd.clear();
          }
          lcd.setCursor(0, 1);
          lcd.print(hidden);
        }
        if (temp == 'A' && temp != 0 && new_pass.length() == 8) {
          PASS = new_pass;
          setPassInfo(new_pass);
          if (Firebase.setString(fbdo, userPath + "/esp32-door/password", PASS)) {
            Serial.println("change ok");
          } else {
            Serial.println("fail");
          }
          isPassTrue = false;
          isChangePassword = false;
          isMode = true;
          hidden = "";
          x = 0;
          delay(500);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Password is");
          lcd.setCursor(0, 1);
          lcd.print("change complete");
          new_pass = "";
          delay(2000);
          lcd.clear();
        }
      }
    }
  }
}