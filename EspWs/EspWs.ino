#include <EEPROM.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>

#define BAUD_RATE 1200

#define MODE_ACCEPT_COMMAND 1
#define MODE_EXECUTE_COMMAND 2

#define COMMAND_SET_SSID 1
#define COMMAND_SET_PASS 2
#define COMMAND_START_WIFI 3
#define COMMAND_STOP_WIFI 4
#define COMMAND_START_WEBSOCKET 5
#define COMMAND_WEBSOCKET_SEND 6

#define RESULT_OK 1
#define RESULT_ERROR 2
#define RESULT_DATA 3
#define RESULT_WS 4

String payload = "";

String ssid = "";
String pass = "";

int mode = MODE_ACCEPT_COMMAND;
char command[258];
unsigned int commandIndex = 0;
unsigned int remainingBytes = 0;

WebSocketsClient webSocket;

void report(int8_t resultCode, uint8_t* payload, size_t len) {
  // max payload length 255 for simplicity
  len = len > 255 ? 255: len;
  Serial.write(resultCode);
  Serial.write(len & 0xff);
  if (len > 0) {
    Serial.write(payload, len);
  }
}

void reportSuccess() {
  report(RESULT_OK, NULL, 0);
}

void reportError(const String& errorMessage) {
  report(RESULT_ERROR, (uint8_t*)(errorMessage.c_str()), errorMessage.length());
}

void reportData(uint8_t* payload, size_t len) {
  report(RESULT_DATA, payload, len);
}

void reportWebSocketStatus(const char* status) {
  report(RESULT_WS, (uint8_t*)(status), strlen(status));
}

String WiFiStatusToString(int status) {
  switch (status) {
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

void webSocketEvent(WStype_t type, uint8_t* payload, size_t len) {
  switch (type) {
    case WStype_DISCONNECTED:
      reportWebSocketStatus("Disconnected");
      break;
    case WStype_CONNECTED:
      reportWebSocketStatus("Connected");
      break;
    case WStype_TEXT:
    case WStype_BIN:
      reportData(payload, len);
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
  if (url.startsWith("wss://")) {
    hostIndex = 6;
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
  port = url.substring(portIndex + 1, pathIndex);
  path = url.substring(pathIndex);

  webSocket.onEvent(webSocketEvent);
  if (url.startsWith("wss://")) {
    webSocket.beginSSL(host.c_str(), port.toInt(), path.c_str());
  } else {
    webSocket.begin(host, port.toInt(), path);
  }
}

void wsSend(const char* message, unsigned int len) {
  if (webSocket.sendBIN((uint8_t*)message, len)) {
    reportSuccess();
  } else {
    reportError("Send failed");
  }
}

void executeCommand() {
  mode = MODE_EXECUTE_COMMAND;
  char command_id = command[0];
  switch (command_id) {
    case COMMAND_SET_SSID:
      ssid = String(command + 2);
      reportSuccess();
      break;
    case COMMAND_SET_PASS:
      pass = String(command + 2);
      reportSuccess();
      break;
    case COMMAND_START_WIFI:
      wifiConnect();
      break;
    case COMMAND_STOP_WIFI:
      wifiDisconnect();
      break;
    case COMMAND_START_WEBSOCKET:
      wsStart(command + 2);
      break;
    case COMMAND_WEBSOCKET_SEND:
      wsSend(command + 2, commandIndex - 2);
      break;
    default:
      reportError("Invalid command");
  }

  mode = MODE_ACCEPT_COMMAND;
}

void setup() {
  Serial.begin(BAUD_RATE);
  mode = MODE_ACCEPT_COMMAND;
  remainingBytes = 0;
  commandIndex = 0;
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

  command[commandIndex++] = (char)c;
  if (commandIndex == 2) {
    remainingBytes = c + 1;
  }

  remainingBytes--;
  if (remainingBytes == 0) {
    command[commandIndex] = '\0';
    executeCommand();
    commandIndex = 0;
  }
}
