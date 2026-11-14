#pragma once
// ElderGuard wearable configuration. Keep BLE UUIDs and packet keys in sync with
// docs/SUMMARY.md and frontend/lib/services/ble/ble_protocol.dart.

#define FIRMWARE_VERSION "1.0.0"
#define DEVICE_NAME_PREFIX "ElderGuard-"  // + last 4 hex digits of the MAC

// ---------- Pins (ESP32-S3-N16R8; GPIO 35-37 are taken by the octal PSRAM) ----------
#define PIN_I2C_SDA 8       // MAX30102 + MPU6050 share the I2C bus
#define PIN_I2C_SCL 9
#define PIN_DS18B20 4       // 4.7k pull-up to 3.3V
#define PIN_BATTERY_ADC 1   // ADC1_CH0; LiPo through a 100k/100k divider
#define BATTERY_DIVIDER_RATIO 2.0f
#define BATTERY_EMPTY_V 3.30f
#define BATTERY_FULL_V 4.20f

// ---------- BLE (custom GATT service) ----------
#define BLE_SERVICE_UUID "6e1f0001-8b3a-4c2e-9d5a-6f1e2d3c4b5a"
#define BLE_TELEMETRY_UUID "6e1f0002-8b3a-4c2e-9d5a-6f1e2d3c4b5a"  // READ + NOTIFY, JSON packet
#define BLE_CONTROL_UUID "6e1f0003-8b3a-4c2e-9d5a-6f1e2d3c4b5a"    // WRITE: "SYNC" | "PING"
#define BLE_MTU 247

// ---------- Transmission policy (power saving) ----------
#define PERIODIC_TX_MS 60000UL         // normal summary every 60 s
#define ABNORMAL_COOLDOWN_MS 15000UL   // min gap between two "abnormal" packets
#define PENDING_QUEUE_SIZE 8           // abnormal/fall packets kept while disconnected

// Immediate send when a value jumps this much since the last transmitted packet
#define DELTA_HR_BPM 15
#define DELTA_SPO2_PCT 3
#define DELTA_TEMP_C 0.6f

// Coarse device-side abnormal limits (the backend applies the patient's personal baseline)
#define ABN_HR_LOW 50
#define ABN_HR_HIGH 115
#define ABN_SPO2_LOW 92
#define ABN_TEMP_LOW 35.0f
#define ABN_TEMP_HIGH 37.8f

// ---------- Sensors ----------
#define FINGER_IR_THRESHOLD 50000UL  // IR below this = sensor not on skin
// Finger placement and movement produce short bursts of wrong values (e.g. 148 BPM) that must
// not raise alerts. Heart rate comes from evenly spaced beats over 8 s (pulse_oximeter.cpp);
// SpO2 is reported only once its per-second readings agree.
#define PPG_SETTLE_MS 5000UL          // ignore SpO2 readings right after the finger touches the sensor
#define PPG_WINDOW 8                  // judge the last 8 per-second SpO2 readings
#define PPG_MIN_AGREE 6               // at least 6 of them must agree
#define PPG_SPO2_AGREE_ABS 2.0f       // within 2 percentage points of the median
#define PPG_BEAT_REGULARITY 0.15f     // a beat interval counts as regular within 15% of the median
#define PPG_MIN_REGULAR_SHARE 0.70f   // at least 70% of intervals must be regular, else it is movement
#define TEMP_READ_INTERVAL_MS 5000UL
// DS18B20 on the wrist reads skin temperature, which is lower than core temperature.
// Calibrate against a clinical thermometer and set the difference here.
#define TEMP_OFFSET_C 0.0f

// ---------- Fall detection (MPU6050) ----------
#define MOTION_SAMPLE_MS 20          // 50 Hz
#define FALL_FREEFALL_G 0.40f        // phase 1: near free fall
#define FALL_IMPACT_G 2.50f          // phase 2: impact within the window
#define FALL_IMPACT_WINDOW_MS 1000UL
#define FALL_STILLNESS_MS 2000UL     // phase 3: lying still after impact
#define FALL_STILL_DYNAMIC_G 0.15f
#define ACTIVITY_WINDOW_MS 60000UL   // activity index = mean dynamic acceleration (mg) per window
