#include <EEPROM.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WiFi.h>

#define BAUD_RATE 1200

#define MODE_ACCEPT_COMMAND 1
#define MODE_EXECUTE_COMMAND 2

#define COMMAND_SET_SSID "SSID$"
#define COMMAND_SET_PASS "PASS$"
#define COMMAND_START_WIFI "WIFION"
#define COMMAND_STOP_WIFI "WIFIOFF"
#define COMMAND_HTTP_GET "GET$"
#define COMMAND_HTTP_POST "POST$"
#define COMMAND_SET_BODY "BODY$"
#define COMMAND_ECHO_ON "ECHOON"
#define COMMAND_ECHO_OFF "ECHOOFF"


String command = "";
String payload = "";

String ssid = "";
String pass = "";

int mode = MODE_ACCEPT_COMMAND;
bool echo = false;

void reportError(const String& errorMessage) {
  Serial.println("ERROR");
  Serial.println(errorMessage);
}

void reportSuccess() {
  Serial.println("OK");
}

String WiFiStatusToString(int status) {
    switch(status) {
      case WL_IDLE_STATUS:
        return "WL_IDLE_STATUS";
      case WL_NO_SSID_AVAIL:
        return "WL_NO_SSID_AVAIL";
      case WL_SCAN_COMPLETED:
        return "WL_SCAN_COMPLETED";
      case WL_CONNECTED:
        return "WL_CONNECTED";
      case WL_CONNECT_FAILED:
        return "WL_CONNECT_FAILED";
      case WL_CONNECTION_LOST:
        return "WL_CONNECTION_LOST";
      case WL_DISCONNECTED:
        return "WL_DISCONNECTED";
      default:
        return String(status);
    }
}

void wifiConnect() {
  if (ssid == "") {
    reportError("Empty SSID");
    return;
  }
  WiFi.begin(ssid, pass);
  for (int i = 0; i < 100; ++i) {
    delay(100);
    if (WiFi.status() == WL_CONNECTED) {
      reportSuccess();
      return;
    }
  }

  return reportError(WiFiStatusToString(WiFi.status()));
}

void wifiDisconnect() {
  WiFi.disconnect();
  reportSuccess();
}

void sendHttpRequest(const char* method, const String& url, const String& payload) {
  HTTPClient httpClient;
  httpClient.begin(url);
  int statusCode = httpClient.sendRequest(method, payload);
  if (statusCode < 0) {
    reportError(String(statusCode, DEC));
  } else {
    reportSuccess();
    Serial.print(statusCode);
    Serial.print(" ");
    // Serial.println(httpClient.getSize());
    const String& body = httpClient.getString();
    Serial.println(body.length());
    yield();
    const int batchSize = 256;
    for (int i = 0; i < body.length(); i += batchSize) {
      Serial.print(body.substring(i, i + batchSize));
      yield();
    }
  }

  httpClient.end();
}

void httpGet(const String& url) {
  sendHttpRequest("GET", url, "");
}

void httpPost(const String& url) {
  sendHttpRequest("POST", url, payload);
}

void executeCommand() {
  mode = MODE_EXECUTE_COMMAND;
  command.trim();
  String upperCaseCommand = command;
  upperCaseCommand.toUpperCase();
  if (upperCaseCommand.startsWith(COMMAND_SET_SSID)) {
    ssid = command.substring(strlen(COMMAND_SET_SSID));
    reportSuccess();
  } else if (upperCaseCommand.startsWith(COMMAND_SET_PASS)) {
    pass = command.substring(strlen(COMMAND_SET_PASS));
    reportSuccess();
  } else if (upperCaseCommand == COMMAND_START_WIFI) {
    wifiConnect();
  } else if (upperCaseCommand == COMMAND_STOP_WIFI) {
    wifiDisconnect();
  } else if (upperCaseCommand.startsWith(COMMAND_HTTP_GET)) {
    httpGet(command.substring(strlen(COMMAND_HTTP_GET)));
  } else if (upperCaseCommand.startsWith(COMMAND_HTTP_POST)) {
    httpPost(command.substring(strlen(COMMAND_HTTP_POST)));
  } else if (upperCaseCommand == COMMAND_ECHO_ON) {
    echo = true;
    reportSuccess();
  } else if (upperCaseCommand == COMMAND_ECHO_OFF) {
    echo = false;
    reportSuccess();
  } else {
    reportError("Invalid command");
  }

  command = "";
  mode = MODE_ACCEPT_COMMAND;
}

void setup() {
  Serial.begin(BAUD_RATE);
  reportSuccess();
  mode = MODE_ACCEPT_COMMAND;
}

void loop() {
  if (mode != MODE_ACCEPT_COMMAND || Serial.available() == 0) {
    return;
  }

  int c = Serial.read();
  if (c < 0) {
    return;
  }

  if (c == '\n' || c == '\r') {
    if (echo) {
    Serial.println();
    }
    executeCommand();
  } else {
    command.concat((char)c);
    if (echo) {
      Serial.write(c);
    }
  }
}
