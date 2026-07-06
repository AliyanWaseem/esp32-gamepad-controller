# Setup Guide

End-to-end steps to get the phone app talking to the ESP32 and the ESP32
acting as a USB gamepad on your PC.

## What you'll need

- An **ESP32-S2 or ESP32-S3** board (native USB OTG required — a plain
  ESP32 will not work for the HID part)
- A USB cable connected to the board's **native USB** port
- A phone with the Flutter app installed (Android or iOS)
- Arduino IDE with the `esp32` board package installed
- A PC/laptop (or console with USB gamepad support) to plug the ESP32 into

## 1. Flash the firmware

1. Open `firmware/gamepad_receiver/gamepad_receiver.ino` in Arduino IDE
2. Select your board under **Tools > Board** (e.g. "ESP32S3 Dev Module")
3. **Tools > USB Mode > "USB-OTG (TinyUSB)"** — this step is required; HID
   will not work in the default USB mode
4. (Optional) Change `AP_SSID`, `AP_PASS`, or `UDP_PORT` at the top of the
   file if you don't want the defaults
5. Click **Upload**

If you changed `UDP_PORT`, remember it — you'll need it in step 3.

## 2. Power the ESP32 and confirm the access point

Once flashed, the board starts broadcasting a Wi-Fi network:

- **SSID:** `GamepadESP32` (or whatever you set `AP_SSID` to)
- **Password:** `12345678` (or whatever you set `AP_PASS` to)
- **Gateway IP:** `192.168.4.1` (fixed — this is how ESP32 SoftAP works)

You should see this network appear in your phone's Wi-Fi list within a few
seconds of the board powering on.

## 3. Configure and run the Flutter app

1. Open `app/lib/screens/controller_screen.dart`
2. Confirm these match your firmware's config:
   ```dart
   static const String espIp = '192.168.4.1';
   static const int espPort = 4210;
   ```
3. From the `app/` directory:
   ```bash
   flutter pub get
   flutter run
   ```
4. Install the app on your phone (via `flutter run` with the phone
   connected, or a built APK/IPA)

## 4. Connect the phone to the ESP32's network

On your phone, connect to the `GamepadESP32` Wi-Fi network using the
password from step 1.

> ⚠️ Your phone will likely lose internet access while connected to the
> ESP32's SoftAP, since the ESP32 isn't routing traffic anywhere else. This
> is expected — you only need the local link for gameplay.

## 5. Plug the ESP32 into your PC

Connect the ESP32 to your PC/console over USB (the **native USB** port,
not a secondary UART-only port some boards expose). It should enumerate as
a standard USB HID gamepad — no driver installation needed.

You can confirm this is working:
- **Windows:** Control Panel → Devices and Printers, or
  `joy.cpl` (Set up USB game controllers)
- **Linux:** `jstest /dev/input/js0` (or whichever `jsX` device shows up)
- **macOS:** System Information → USB, or a controller-test app/site

## 6. Open the app and play

With the phone connected to the ESP32's Wi-Fi and the ESP32 plugged into
your PC, launch the app and start pressing buttons — input should appear
immediately in whatever game or controller-test tool you're using on the
PC side.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| ESP32's Wi-Fi network never appears | Firmware didn't flash correctly, or wrong board selected in Arduino IDE |
| Phone connects to Wi-Fi but nothing happens in-game | Check `espIp`/`espPort` in the app match the firmware; confirm phone didn't silently reconnect to a different known Wi-Fi network |
| PC doesn't recognize the ESP32 as a gamepad at all | USB Mode wasn't set to "USB-OTG (TinyUSB)" before flashing, or you're using a non-native-USB port on the board |
| Input feels laggy or drops occasionally | Expected to some degree over UDP/Wi-Fi; check for Wi-Fi interference, and confirm you're not also using the ESP32's Wi-Fi for anything else |
| Joystick doesn't recenter properly | Check the app's release/reset handler is firing (`onPanEnd`/`onPanCancel`) — should reset to `128,128` on release |

## Next steps

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — how the pieces fit together
- [`PROTOCOL.md`](PROTOCOL.md) — full packet/bit-mask reference if you want
  to add new buttons or change behavior
