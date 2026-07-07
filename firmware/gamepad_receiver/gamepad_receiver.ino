// Requires an ESP32-S2 or S3 board (native USB OTG needed for HID).
// Board settings in Arduino IDE: Tools > USB Mode > "USB-OTG (TinyUSB)"
//
// This presents the ESP32 itself as a real USB gamepad to whatever it's
// plugged into — no drivers, no companion script, works identically on
// Windows, Linux, and macOS, exactly like a physical USB controller.
//
// NOTE: Serial.print() is deliberately not used here. Mixing Serial output
// with USB HID on native USB causes known timing issues in the Arduino-ESP32
// core that can corrupt HID reports. If you need to debug, use log_d()
// (routes to JTAG) instead of Serial, or temporarily disable HID.

#include <WiFi.h>
#include <WiFiUdp.h>
#include "USB.h"
#include "USBHIDGamepad.h"

USBHIDGamepad Gamepad;

// --- SoftAP config -------------------------------------------------------
const char *AP_SSID = "GamepadESP32";
const char *AP_PASS = "12345678";
const int UDP_PORT = 4210;

// Frame layout, must match _sendPacket() in the Flutter app exactly:
// [0] 0xAA start byte
// [1..4] 32-bit button mask, little-endian (b0 = low byte)
// [5] joystick X (0-255, 128 = center)
// [6] joystick Y (0-255, 128 = center)
// [7] checksum = XOR of bytes 0 through 6
const int FRAME_SIZE = 8;

WiFiUDP udp;
uint8_t packetBuffer[FRAME_SIZE];

// Bit positions matching the Btn class in the Flutter app
#define BIT_DPAD_UP (1UL << 0)
#define BIT_DPAD_DOWN (1UL << 1)
#define BIT_DPAD_LEFT (1UL << 2)
#define BIT_DPAD_RIGHT (1UL << 3)
// Bits 4-17 (cross, circle, square, triangle, extra1-5, l, r, select,
// start, pause) map 1:1 onto gamepad button IDs 0-13.

uint32_t prevMask = 0;

bool validateFrame(uint8_t *buf) {
  if (buf[0] != 0xAA) return false;
  uint8_t checksum = 0;
  for (int i = 0; i < FRAME_SIZE - 1; i++) {
    checksum ^= buf[i];
  }
  return checksum == buf[FRAME_SIZE - 1];
}

void applyMask(uint32_t mask) {
  uint32_t changed = mask ^ prevMask;
  if (!changed) return;

  // D-pad reported as a hat switch (point-of-view), matching how real
  // gamepads report it — most games expect this rather than 4 buttons.
  if (changed & (BIT_DPAD_UP | BIT_DPAD_DOWN | BIT_DPAD_LEFT | BIT_DPAD_RIGHT)) {
    bool up = mask & BIT_DPAD_UP;
    bool down = mask & BIT_DPAD_DOWN;
    bool left = mask & BIT_DPAD_LEFT;
    bool right = mask & BIT_DPAD_RIGHT;

    if (up && right) Gamepad.hat(HAT_UP_RIGHT);
    else if (down && right) Gamepad.hat(HAT_DOWN_RIGHT);
    else if (down && left) Gamepad.hat(HAT_DOWN_LEFT);
    else if (up && left) Gamepad.hat(HAT_UP_LEFT);
    else if (up) Gamepad.hat(HAT_UP);
    else if (down) Gamepad.hat(HAT_DOWN);
    else if (left) Gamepad.hat(HAT_LEFT);
    else if (right) Gamepad.hat(HAT_RIGHT);
    else Gamepad.hat(HAT_CENTER);
  }

  // Remaining buttons (bits 4-17) map straight onto gamepad button IDs 0-13
  for (int bit = 4; bit <= 17; bit++) {
    uint32_t bitMask = (1UL << bit);
    if (changed & bitMask) {
      int gamepadButtonId = bit - 4;
      if (mask & bitMask) {
        Gamepad.pressButton(gamepadButtonId);
      } else {
        Gamepad.releaseButton(gamepadButtonId);
      }
    }
  }

  prevMask = mask;
}

void setup() {
  Gamepad.begin();
  USB.begin();

  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  // Gateway is always 192.168.4.1 — must match espIp in the Flutter app

  udp.begin(UDP_PORT);
}

void loop() {
  int packetSize = udp.parsePacket();

  if (packetSize == FRAME_SIZE) {
    int len = udp.read(packetBuffer, FRAME_SIZE);

    if (len == FRAME_SIZE && validateFrame(packetBuffer)) {
      uint32_t mask = packetBuffer[1] | (packetBuffer[2] << 8) | (packetBuffer[3] << 16) | ((uint32_t)packetBuffer[4] << 24);
      uint8_t joyX = packetBuffer[5];
      uint8_t joyY = packetBuffer[6];

      applyMask(mask);
      // 0-255 with 128 as center maps directly onto -128..127
      Gamepad.leftStick((int8_t)(joyX - 128), (int8_t)(joyY - 128));

      // Tiny ack so the phone can detect it's actually still connected —
      // UDP itself has no connection state, so this is our heartbeat.
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write(0xAC);
      udp.endPacket();
    }
  } else if (packetSize > 0) {
    udp.read(packetBuffer, FRAME_SIZE);
  }
}
