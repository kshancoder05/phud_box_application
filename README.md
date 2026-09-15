# PHUD BOX — Flutter app + Raspberry Pi BLE peripheral

Two pieces:

1. **`lib/`** — Flutter/Android app source (drop into a fresh Flutter project).
2. **`raspberrypi_ble_peripheral/`** — Python BLE GATT server for the Pi, using BlueZ via `bluezero`.

No Flutter SDK or internet access was available in the environment that generated
this, so nothing here has been compiled or run — treat it as a solid, complete
starting point, and expect to fix small API-version mismatches (noted inline)
on first build.

## 1. Set up the Flutter project

```bash
flutter create phud_box
cd phud_box
```

Then overlay this package's files on top:

- Copy `pubspec.yaml` over the generated one, then `flutter pub get`.
- Copy the entire `lib/` folder over the generated `lib/`.
- Open `android/app/src/main/AndroidManifest.xml` and merge in the permissions
  from `android_manifest_snippet/AndroidManifest_additions.xml` (inside
  `<manifest>`, above `<application>`; also add the `xmlns:tools` attribute
  noted at the top of that file).
- In `android/app/build.gradle`, set `minSdkVersion 21` and
  `compileSdkVersion 34` / `targetSdkVersion 34` (flutter_blue_plus needs a
  recent SDK for the Android 12+ Bluetooth permissions).

Run on a physical Android device (BLE doesn't work in the emulator):

```bash
flutter run
```

The app opens on a scan screen, lists nearby devices advertising the PHUD BOX
service UUID, and moves to the Overview/Logs/Control tabs once connected.

## 2. Run the Raspberry Pi peripheral

```bash
cd raspberrypi_ble_peripheral
pip install -r requirements.txt
sudo python3 gatt_peripheral.py
```

Root is required because registering a GATT server and advertising go through
BlueZ's D-Bus API, which needs elevated privileges. Make sure `bluetoothd` is
running (`sudo systemctl status bluetooth`) and the Pi's Bluetooth radio is on
(`bluetoothctl power on`).

The script simulates a door sensor, battery gauge, and UV lamp with plain
Python state so you can test the full app flow before wiring real GPIO —
swap `read_door_sensor()`, `read_battery_percent()`, and `set_uv_lamp()` for
your actual hardware calls (`gpiozero`, `RPi.GPIO`, an I2C fuel gauge, etc).

`bluezero`'s exact method names shift a bit between versions; if
`telemetry_char.set_value(...)` doesn't match what's installed, check
`site-packages/bluezero/examples` for the current pattern — the surrounding
protocol logic (framing, commands, cycle state machine) doesn't need to
change.

## Protocol

One custom GATT service, two characteristics. Every message in either
direction is a JSON object encoded as UTF-8 and terminated with a `\n`. Long
messages are split across multiple BLE packets and reassembled by buffering
until a newline appears — this is handled on both ends already.

| | UUID |
|---|---|
| Service | `b3f1e100-0a1e-4b8b-9a53-4f0e6d6a10a0` |
| Telemetry (notify, peripheral → phone) | `b3f1e101-0a1e-4b8b-9a53-4f0e6d6a10a0` |
| Command (write, phone → peripheral) | `b3f1e102-0a1e-4b8b-9a53-4f0e6d6a10a0` |

**Telemetry**, pushed roughly once a second and whenever state changes:

```json
{
  "type": "telemetry",
  "battery": 92,
  "status": "idle",
  "door_open": true,
  "chamber_slots_left": 3,
  "seconds_left": 0,
  "active_batch": null
}
```

**Log entry**, pushed once per completed cycle:

```json
{
  "type": "log_entry",
  "id": "#004",
  "color": "RED",
  "date": "08/05/2026",
  "result": "PASS",
  "instruments": "Scalpel, Forceps",
  "time": "10:30 AM - 10:40 AM",
  "uv_intensity": "275nm",
  "expiry": "08/06/2026 @ 10:30 AM",
  "error": null
}
```

**Commands** the app sends:

```json
{"cmd": "start_cycle"}
{"cmd": "end_cycle"}
```

The Pi script rejects `start_cycle` if the door is open or a cycle is already
running — same guard the app's Control screen enforces client-side.

## Notes on ESP32 support later

The same protocol (custom GATT service, JSON-over-newline framing, two
characteristics) works unchanged on an ESP32 using the Arduino `BLEDevice` /
`BLEServer` / `BLECharacteristic` classes — the Flutter side doesn't care
which peripheral it's talking to. If/when you want that firmware sketch, the
Pi script's `start_cycle()` / `end_cycle()` / `cycle_ticker()` state machine
translates directly.
