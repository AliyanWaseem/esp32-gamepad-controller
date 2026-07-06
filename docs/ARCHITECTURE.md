# Architecture

## Overview

```
┌─────────────────────────┐         ┌──────────────────────────────┐         ┌─────────────┐
│   Phone (Flutter app)   │  UDP    │   ESP32-S2/S3 (firmware)      │  USB    │   PC /      │
│                          │ ──────► │                                │ ──────► │  Console    │
│  Joystick, D-pad,        │  :4210  │  Wi-Fi SoftAP + UDP listener   │  HID    │  (sees a    │
│  action buttons, etc.    │ ◄────── │  → USBHIDGamepad               │         │  real       │
│                          │  ack    │                                │         │  gamepad)   │
└─────────────────────────┘         └──────────────────────────────┘         └─────────────┘
```

Two independent pieces, connected by one contract — the
[UDP packet format](PROTOCOL.md):

1. **App (`/app`)** — a Flutter mobile UI that tracks button/joystick state
   and streams it out over UDP whenever it changes
2. **Firmware (`/firmware`)** — an ESP32 sketch that receives those packets,
   validates them, and re-emits them as USB HID gamepad events

Nothing about this design is app-specific or firmware-specific beyond the
packet format — either side could be swapped out (a different phone app, a
different microcontroller) as long as it speaks the same protocol.

## Why UDP instead of TCP or BLE

- **UDP** was chosen for low latency and simplicity — input state is
  time-sensitive but tolerant of the occasional dropped packet (the next
  state update arrives moments later anyway), which is exactly UDP's
  tradeoff profile
- **TCP** would add unnecessary overhead (ack/retransmit machinery) for data
  that's inherently "latest value wins"
- **BLE** was considered but Wi-Fi SoftAP + UDP keeps both ends simpler:
  no pairing flow, no BLE GATT service definitions, and higher achievable
  throughput/lower latency for frequent small packets

## Why the ESP32 presents as USB HID rather than a network gamepad

Rather than have the receiving PC run companion software to interpret UDP
packets, the ESP32-S2/S3's native USB OTG capability lets it show up as a
**real USB HID gamepad device**. This means:

- Zero drivers or install steps on the PC/console side
- Works identically across Windows, Linux, and macOS
- Any game or emulator that already supports a physical controller works
  with no extra configuration

The tradeoff: this restricts the firmware to ESP32-**S2/S3** boards
specifically, since the original ESP32 doesn't have native USB OTG.

## Data flow, step by step

1. User touches a button or drags the joystick in the Flutter UI
2. `ControllerScreen` updates its local button-mask/joystick state
3. `_sendPacket()` builds an 8-byte UDP packet (see
   [PROTOCOL.md](PROTOCOL.md)) and sends it to the ESP32's SoftAP gateway
   IP (`192.168.4.1:4210`)
4. The firmware's `loop()` polls for incoming UDP packets, validates the
   frame (start byte + XOR checksum), and decodes the button mask and
   joystick bytes
5. `applyMask()` diffs the new mask against the previous one and only emits
   HID events for buttons whose state actually changed — D-pad bits are
   translated into a single hat-switch value, all other bits map directly
   to USB gamepad button IDs
6. The firmware sends a 1-byte heartbeat back to the phone, confirming the
   packet was received and applied
7. The OS/game on the receiving end sees standard gamepad input — it has no
   awareness that a phone and Wi-Fi link are involved at all

## Design decisions worth knowing about

- **Change-driven sends, not polling**: the app only sends a packet when
  something actually changes, rather than on a fixed interval. This keeps
  UDP traffic low but means a dropped packet leaves the firmware holding
  stale state until the next change — there's currently no periodic
  resync/keepalive of full state.
- **Change-driven HID emission on the firmware side too**: `applyMask()`
  XORs the new mask against `prevMask` and only touches buttons that
  actually changed, rather than replaying the entire button state every
  packet.
- **No `Serial.print()` in the firmware**: mixing `Serial` output with
  native USB HID is a known source of report corruption on the
  Arduino-ESP32 core. Debug via `log_d()` (JTAG) instead.

## Where to look next

- [`PROTOCOL.md`](PROTOCOL.md) — exact byte layout and bit assignments
- [`SETUP.md`](SETUP.md) — how to get both halves running together
- [`../app/README.md`](../app/README.md) — Flutter app internals
- [`../firmware/README.md`](../firmware/README.md) — firmware internals
