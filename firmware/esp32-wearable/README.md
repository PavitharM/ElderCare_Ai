# ElderGuard Wearable Firmware (ESP32)

This firmware runs on an ESP32. It reads heart rate, SpO₂, skin temperature and motion, detects falls, and streams the data to the ElderGuard Android app over Bluetooth Low Energy (BLE).

## Hardware

| Part | Purpose | ESP32 pin |
|---|---|---|
| MAX30102 | Heart rate and SpO₂ | SDA 21, SCL 22, 3.3 V |
| MPU6050 | Motion, activity, fall detection | SDA 21, SCL 22, 3.3 V (shares the I2C bus) |
| DS18B20 | Skin temperature | Data on GPIO 4, with a 4.7 kΩ pull-up resistor to 3.3 V |
| LiPo battery + 100k/100k divider | Battery level | GPIO 34 |

All pins and thresholds are defined in `include/config.h`.

## Build and flash

1. Install the PlatformIO extension in VS Code.
2. Open this folder (`firmware/esp32-wearable`).
3. Run:

```bash
pio run -t upload
pio device monitor
```

The serial monitor runs at 115200 baud and prints every transmitted packet.

## How it saves power

The sensors are sampled continuously on the ESP32, but the radio transmits only when needed:

| Trigger (`t`) | When it is sent |
|---|---|
| `periodic` | Every 60 s (`PERIODIC_TX_MS`) |
| `abnormal` | Immediately, when a value leaves the safe band or changes sharply. At most once every 15 s. |
| `fall` | Immediately, when a fall is confirmed (free fall, then an impact above 2.5 G, then 2 s lying still) |
| `sync` | When the phone connects or writes `SYNC` |

While the phone is disconnected:
- `fall` and `abnormal` packets are queued (up to 8) and delivered when it reconnects.
- `periodic` packets are dropped, because a fresh `sync` packet replaces them.

## BLE interface

- **Advertised name:** `ElderGuard-XXXX`
- **Service:** `6e1f0001-8b3a-4c2e-9d5a-6f1e2d3c4b5a`
  - **Telemetry characteristic** `6e1f0002-…` (READ, NOTIFY): JSON packet
  - **Control characteristic** `6e1f0003-…` (WRITE): `SYNC` or `PING`
- **Battery Service:** `0x180F` / `0x2A19`
- **Firmware revision:** `0x180A` / `0x2A26`

Example packet (fields are omitted when a sensor has no valid reading, e.g. the sensor is not on the skin):

```json
{"v":1,"seq":12,"t":"abnormal","hr":118,"spo2":97,"temp":36.4,"act":85,"bat":91,"fw":"1.0.0"}
```

| Key | Meaning |
|---|---|
| `hr` | Heart rate (BPM) |
| `spo2` | Blood oxygen (%) |
| `temp` | Temperature (°C) |
| `act` | Mean dynamic acceleration over the last minute (milli-g) |
| `bat` | Battery level (%) |
| `fall_g` | Peak impact (G), only present in `fall` packets |

## Calibration

- **Temperature:** the DS18B20 measures skin temperature, which is lower than core body temperature. Compare it with a clinical thermometer and set the difference in `TEMP_OFFSET_C`.
- **Fall detection:** tune `FALL_*` in `config.h` after controlled tests. Record any false positives or negatives for the evaluation (SRS NFR-15).
