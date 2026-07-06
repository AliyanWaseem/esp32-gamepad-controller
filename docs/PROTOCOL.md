# Wire Protocol

This is the single source of truth for the packet format shared between the
[Flutter app](../app) and the [ESP32 firmware](../firmware). If you change
anything here, update **both** sides — they must agree byte-for-byte.

## Transport

- **Protocol:** UDP
- **Port:** `4210` (configurable, must match on both ends)
- **Direction:** Phone → ESP32 (input), ESP32 → Phone (1-byte heartbeat ack)
- **Trigger:** the app sends a new packet on every input change (button
  press/release or joystick movement) — not on a fixed timer

## Packet format (phone → ESP32)

8 bytes total:

| Byte offset | Field | Description |
|---|---|---|
| 0 | Start marker | Always `0xAA` |
| 1 | Mask byte 0 | Bits 0–7 of the 32-bit button mask (low byte) |
| 2 | Mask byte 1 | Bits 8–15 |
| 3 | Mask byte 2 | Bits 16–23 |
| 4 | Mask byte 3 | Bits 24–31 (high byte) |
| 5 | Joystick X | `0–255`, `128` = centered |
| 6 | Joystick Y | `0–255`, `128` = centered |
| 7 | Checksum | XOR of bytes 0–6 |

Button mask is **little-endian**: reassemble on the receiving end as

```c
uint32_t mask = buf[1] | (buf[2] << 8) | (buf[3] << 16) | ((uint32_t)buf[4] << 24);
```

Joystick values are sent as unsigned `0–255` with `128` as center, then
converted to signed `-128..127` on the firmware side:

```c
int8_t x = (int8_t)(joyX - 128);
int8_t y = (int8_t)(joyY - 128);
```

### Checksum validation

```c
uint8_t checksum = 0;
for (int i = 0; i < 7; i++) checksum ^= buf[i];
bool valid = (checksum == buf[7]) && (buf[0] == 0xAA);
```

Any packet that fails this check is dropped — no partial/best-effort
application of a corrupt frame.

## Heartbeat (ESP32 → phone)

After successfully validating and applying a packet, the firmware sends a
single byte back to the sender:

| Byte | Value |
|---|---|
| 0 | `0xAC` |

UDP has no connection state, so this is the only signal the app has that
the ESP32 is actually receiving and processing input. If the app doesn't
implement a heartbeat listener yet, this is a good next feature to add on
the Flutter side.

## Button bit assignments

32-bit mask, defined in `app/lib/models/btn_constants.dart` (Dart) and
mirrored as `#define`s in the firmware:

| Bit | Name | Notes |
|---|---|---|
| 0 | D-pad Up | |
| 1 | D-pad Down | |
| 2 | D-pad Left | |
| 3 | D-pad Right | Bits 0–3 combined into a single **hat switch** value on the firmware side (see below) — not sent to the OS as 4 separate buttons |
| 4 | Cross (X) | → USB gamepad button ID `0` |
| 5 | Circle (O) | → USB gamepad button ID `1` |
| 6 | Square | → USB gamepad button ID `2` |
| 7 | Triangle | → USB gamepad button ID `3` |
| 8 | Extra 1 | → USB gamepad button ID `4` |
| 9 | Extra 2 | → USB gamepad button ID `5` |
| 10 | Extra 3 | → USB gamepad button ID `6` |
| 11 | Extra 4 | → USB gamepad button ID `7` |
| 12 | Extra 5 | → USB gamepad button ID `8` |
| 13 | L (shoulder) | → USB gamepad button ID `9` |
| 14 | R (shoulder) | → USB gamepad button ID `10` |
| 15 | Select | → USB gamepad button ID `11` |
| 16 | Start | → USB gamepad button ID `12` |
| 17 | Pause | → USB gamepad button ID `13` |
| 18–31 | Reserved | Unused, available for future buttons |

General rule: **USB gamepad button ID = bit position − 4** (this only
applies to bits 4–17; bits 0–3 are the D-pad and are never sent as
individual buttons).

## D-pad → hat switch mapping

Real gamepads report directional input as a single 8-way hat switch (a.k.a.
POV hat) rather than 4 independent buttons, since that's what most
games/emulators expect. The firmware translates bits 0–3 accordingly:

| Up | Down | Left | Right | Hat value |
|---|---|---|---|---|
| ✓ | | | | `HAT_UP` |
| | ✓ | | | `HAT_DOWN` |
| | | ✓ | | `HAT_LEFT` |
| | | | ✓ | `HAT_RIGHT` |
| ✓ | | | ✓ | `HAT_UP_RIGHT` |
| | ✓ | | ✓ | `HAT_DOWN_RIGHT` |
| | ✓ | ✓ | | `HAT_DOWN_LEFT` |
| ✓ | | ✓ | | `HAT_UP_LEFT` |
| | | | | `HAT_CENTER` |

Opposing directions (e.g. Up+Down simultaneously) aren't a defined case in
the current firmware logic — the app's own D-pad UI prevents that
combination from being physically possible to press anyway.

## Versioning this protocol

There's currently no version byte in the packet. If you need to make a
breaking change (resizing the mask, changing byte order, adding fields),
consider:
- Adding a version byte and bumping `FRAME_SIZE`
- Updating this doc, `btn_constants.dart`, and the firmware's `#define`s
  in the same commit
- Testing both directions before merging — a mismatch here fails silently
  (packets just get dropped by the checksum/size check, with no error
  surfaced to the user)
