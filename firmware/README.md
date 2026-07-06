# Gamepad Firmware (ESP32)

Firmware for an ESP32-S2/S3 board that turns it into a **real USB HID
gamepad**. It receives control input wirelessly over UDP from the
[Flutter gamepad app](../app) and re-emits it as native USB gamepad reports —
no drivers, no companion desktop app. Plug the board into a PC/laptop over
USB and it shows up exactly like a physical controller, on Windows, Linux,
and macOS alike.

This directory is the **firmware** half of the
[esp32-gamepad-controller](../) project. For the phone app, see
[`../app`](../app). For the full wire protocol spec, see
[`../docs/PROTOCOL.md`](../docs/PROTOCOL.md).

## How it works

```
 Phone (Flutter app)  --Wi-Fi / UDP-->  ESP32 (this firmware)  --USB HID-->  PC/Console
```

1. The ESP32 boots into Wi-Fi SoftAP mode and starts a UDP listener
2. The phone connects to the ESP32's access point and streams 8-byte input
   packets over UDP on every button/joystick change
3. The firmware validates each packet, decodes the button mask and stick
   position, and forwards them as USB HID gamepad events via `USBHIDGamepad`
4. A single-byte heartbeat is sent back over UDP after each valid packet so
   the phone app can confirm the link is alive (UDP has no built-in
   connection state)

## Hardware requirements

- **ESP32-S2 or ESP32-S3** — native USB OTG is required for HID; a plain
  ESP32 (original) does **not** support this
- USB cable connected to the board's **native USB** port (not the
  UART/programming-only port, if your board breaks them out separately)

## Arduino IDE setup

1. Install the `esp32` board package (Espressif Arduino core)
2. Select your board (e.g. "ESP32S3 Dev Module")
3. **Tools > USB Mode > "USB-OTG (TinyUSB)"** — this is required for HID to work
4. Flash `gamepad_receiver.ino` (or your renamed `.ino`)

## Configuration

Update these constants at the top of the file to match your setup:

```cpp
const char *AP_SSID = "GamepadESP32";
const char *AP_PASS = "12345678";
const int UDP_PORT = 4210;
```

The SoftAP gateway is always `192.168.4.1` — make sure this matches `espIp`
in the Flutter app's `controller_screen.dart`.

## Wire protocol (must match the Flutter app exactly)

8-byte UDP frame:

| Byte | Meaning |
|------|---------|
| 0 | `0xAA` frame start marker |
| 1–4 | 32-bit button mask, little-endian |
| 5 | Joystick X (0–255, 128 = center) |
| 6 | Joystick Y (0–255, 128 = center) |
| 7 | XOR checksum of bytes 0–6 |

- Bits 0–3 (D-pad up/down/left/right) are translated into a single **hat
  switch** value, since that's what most games/emulators expect rather than
  four separate buttons
- Bits 4–17 (Cross, Circle, Square, Triangle, 5 extra buttons, L, R, Select,
  Start, Pause) map 1:1 onto USB gamepad button IDs 0–13
- Joystick bytes (0–255, centered at 128) are converted to signed `-128..127`
  for `Gamepad.leftStick()`

Full details in [`../docs/PROTOCOL.md`](../docs/PROTOCOL.md).

## ⚠️ Debugging note

Don't use `Serial.print()` in this sketch. Mixing `Serial` output with native
USB HID is a known source of report-timing corruption in the Arduino-ESP32
core. If you need to debug:
- Use `log_d()` instead (routes over JTAG, not USB)
- Or temporarily disable `Gamepad.begin()` / `USB.begin()` while debugging
  over Serial, then re-enable once you're done

## Known limitations / TODO

- No pairing/security on the SoftAP beyond the fixed password — fine for
  local play, not intended for anything security-sensitive
- No reconnect handling if the phone disconnects mid-session beyond the
  heartbeat byte
- Only one client is expected to send packets at a time; concurrent senders
  will race on `prevMask`

## License

MIT (or match the root repo license)
