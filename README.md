# esp32-gamepad-controller

Turn a phone into a wireless game controller. A Flutter app renders a
custom, PSP-style gamepad UI and streams input over Wi-Fi/UDP to an ESP32
board, which re-emits it as a real USB HID gamepad — so it shows up as an
actual controller on any PC, with no drivers and no companion desktop
software.

```
 Phone (Flutter app)  --Wi-Fi / UDP-->  ESP32 (firmware)  --USB HID-->  PC/Console
```

## Features

- Custom PSP/PPSSPP-inspired controller UI: analog joystick, D-pad, action
  button diamond (Cross / Circle / Square / Triangle), 5 extra buttons, L/R
  shoulders, Start/Select/Pause
- Fully custom-painted Flutter widgets — no external icon assets
- Real-time input streamed over UDP as a compact 8-byte packet
- ESP32-S2/S3 firmware presents itself as a genuine USB HID gamepad —
  works identically on Windows, Linux, and macOS
- D-pad reported as a hat switch, matching how real controllers report it,
  for maximum game/emulator compatibility

## Repository structure

```
esp32-gamepad-controller/
├── README.md                  ← you are here
├── LICENSE
│
├── docs/
│   ├── ARCHITECTURE.md        # how the app and firmware fit together
│   ├── PROTOCOL.md            # exact UDP packet spec, bit assignments
│   └── SETUP.md               # end-to-end setup walkthrough
│
├── app/                        # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
│
└── firmware/                    # ESP32 firmware
    ├── gamepad_receiver/
    │   └── gamepad_receiver.ino
    └── README.md
```

See [`app/README.md`](app/README.md) and [`firmware/README.md`](firmware/README.md)
for details specific to each half of the project.

## Quick start

0. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/esp32-gamepad-controller.git
   cd esp32-gamepad-controller
   ```
1. **Flash the firmware** onto an ESP32-S2 or S3 board (native USB OTG
   required). See [`firmware/README.md`](firmware/README.md) for board
   settings and wiring.
2. **Run the Flutter app** on your phone. See [`app/README.md`](app/README.md).
3. **Connect** your phone to the ESP32's Wi-Fi access point (`GamepadESP32`
   by default).
4. **Plug the ESP32 into your PC** over USB — it enumerates as a standard
   USB gamepad.
5. Open the app and start playing; input streams over UDP and comes out the
   other end as native gamepad button/stick events.

## The protocol, in short

Every input change sends an 8-byte UDP packet:

| Byte | Meaning |
|------|---------|
| 0 | `0xAA` frame start marker |
| 1–4 | 32-bit button mask, little-endian |
| 5 | Joystick X (0–255, 128 = center) |
| 6 | Joystick Y (0–255, 128 = center) |
| 7 | XOR checksum of bytes 0–6 |

The firmware also sends a single-byte heartbeat back to the phone after each
valid packet, since UDP itself has no connection state. Full spec, including
every button's bit position, lives in [`docs/PROTOCOL.md`](docs/PROTOCOL.md).

## Requirements

- Flutter SDK (stable channel) + a physical Android/iOS phone
- An ESP32-S2 or ESP32-S3 board
- Arduino IDE with the ESP32 board package, USB Mode set to
  **USB-OTG (TinyUSB)**

## Known limitations / roadmap

- App layout assumes landscape orientation; no portrait fallback yet
- ESP32 IP/port are hardcoded in the app rather than configurable in-app
- SoftAP has a fixed password — fine for local play, not hardened for
  anything security-sensitive
- No reconnect/retry logic beyond the heartbeat byte if the link drops

## License

MIT — see [`LICENSE`](LICENSE)

![Controller UI](docs/images/connected.jpeg)
