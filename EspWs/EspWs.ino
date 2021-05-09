#include <EEPROM.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#define BAUD_RATE 1200

#define MODE_ACCEPT_COMMAND 1
#define MODE_EXECUTE_COMMAND 2

#define COMMAND_SET_SSID "SSID$"
#define COMMAND_SET_PASS "PASS$"
#define COMMAND_START_WIFI "WIFION"
#define COMMAND_STOP_WIFI "WIFIOFF"
#define COMMAND_WS_START "WSSTART$"
#define COMMAND_WS_SEND "WSSEND$"


String command = "";
String payload = "";

String ssid = "";
String pass = "";

int mode = MODE_ACCEPT_COMMAND;

WebSocketsClient webSocket;

void reportError(const String& errorMessage) {
  Serial.println("ERROR");
  Serial.println(errorMessage);
}

void reportSuccess() {
  Serial.println("OK");
}

void reportData(const String& data) {
  Serial.println("DATA " + String(data.length()));
  Serial.println(data);
}

void reportWebSocketStatus(const String& status) {
  Serial.println("WS");
  Serial.println(status);
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

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      reportWebSocketStatus("Disconnected");
      break;
    case WStype_CONNECTED:
      reportWebSocketStatus("Connected");
      break;
    case WStype_TEXT:
      reportData(String((const char*)payload));
      break;
    default:
      break;
  }
}

void wsStart(const String& url) {
  if (webSocket.isConnected()) {
    reportSuccess();
    return;
  }

  int hostIndex = 0;
  bool isSecureWs = false;
  if (url.startsWith("wss://")) {
    reportError("Secure WebSocket not supported");
    return;
  }
  if (url.startsWith("ws://")) {
    hostIndex = 5;
  }
  int portIndex = url.indexOf(':', hostIndex);
  int pathIndex = url.indexOf('/', portIndex);

  if (portIndex == -1 || pathIndex == -1) {
    reportError("Malformed URL");
    return;
  }

  String host, port, path;
  host = url.substring(hostIndex, portIndex);
  port = url.substring(portIndex+1, pathIndex);
  path = url.substring(pathIndex);

  webSocket.onEvent(webSocketEvent);
  webSocket.begin(host, port.toInt(), path);
}

void wsSend(const String& message) {
  if (webSocket.sendBIN((uint8_t*)(message).c_str(), message.length())) {
    reportSuccess();
  } else {
    reportError("Send failed");
  }
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
  } else if (upperCaseCommand.startsWith(COMMAND_WS_START)) {
    wsStart(command.substring(strlen(COMMAND_WS_START)));
  } else if (upperCaseCommand.startsWith(COMMAND_WS_SEND)) {
    wsSend(command.substring(strlen(COMMAND_WS_SEND)));
  } else {
    reportError("Invalid command");
  }

  command = "";
  mode = MODE_ACCEPT_COMMAND;
}

void setup() {
  Serial.begin(BAUD_RATE);
  mode = MODE_ACCEPT_COMMAND;
}

void loop() {
  webSocket.loop();

  if (mode != MODE_ACCEPT_COMMAND || Serial.available() == 0) {
    return;
  }

  int c = Serial.read();
  if (c < 0) {
    return;
  }

  if (c == '\n' || c == '\r') {
    executeCommand();
  } else {
    command.concat((char)c);
  }
}
