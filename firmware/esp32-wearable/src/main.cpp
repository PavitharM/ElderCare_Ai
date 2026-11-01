// ElderGuard AI wearable: samples vitals and motion continuously, transmits sparingly.
//   - periodic summary every PERIODIC_TX_MS
//   - immediate "abnormal" packet when a value leaves the safe band or jumps sharply
//   - immediate "fall" packet on a confirmed fall
#include <Arduino.h>
#include <Wire.h>

#include <cstdio>
#include <string>

#include "ble_link.h"
#include "config.h"
#include "motion_monitor.h"
#include "pulse_oximeter.h"
#include "temperature_sensor.h"

static PulseOximeter oximeter;
static MotionMonitor motion;
static TemperatureSensor thermometer;
static BleLink ble;

static bool oximeterOk = false, motionOk = false, thermoOk = false;
static uint32_t sequence = 0;
static unsigned long lastPeriodicTx = 0;
static unsigned long lastAbnormalTx = 0;
static unsigned long lastBatteryRead = 0;
static uint8_t batteryPct = 100;

struct Snapshot {
  int hr = 0;        // 0 = unavailable
  int spo2 = 0;
  float temp = 0;    // 0 = unavailable
};
static Snapshot lastSent;

static uint8_t readBatteryPercent() {
  uint32_t mv = 0;
  for (int i = 0; i < 8; i++) mv += analogReadMilliVolts(PIN_BATTERY_ADC);
  float volts = (mv / 8.0f) / 1000.0f * BATTERY_DIVIDER_RATIO;
  float pct = (volts - BATTERY_EMPTY_V) / (BATTERY_FULL_V - BATTERY_EMPTY_V) * 100.0f;
  return (uint8_t)constrain(pct, 0.0f, 100.0f);
}

static Snapshot currentSnapshot() {
  Snapshot s;
  if (oximeterOk && oximeter.hasHeartRate()) s.hr = oximeter.heartRate();
  if (oximeterOk && oximeter.hasSpo2()) s.spo2 = oximeter.spo2();
  if (thermoOk && thermometer.valid()) s.temp = thermometer.celsius();
  return s;
}

static bool isAbnormal(const Snapshot &s) {
  return (s.hr && (s.hr < ABN_HR_LOW || s.hr > ABN_HR_HIGH)) ||
         (s.spo2 && s.spo2 < ABN_SPO2_LOW) ||
         (s.temp > 0 && (s.temp < ABN_TEMP_LOW || s.temp > ABN_TEMP_HIGH));
}

static bool changedSharply(const Snapshot &s) {
  return (s.hr && lastSent.hr && abs(s.hr - lastSent.hr) >= DELTA_HR_BPM) ||
         (s.spo2 && lastSent.spo2 && abs(s.spo2 - lastSent.spo2) >= DELTA_SPO2_PCT) ||
         (s.temp > 0 && lastSent.temp > 0 && fabsf(s.temp - lastSent.temp) >= DELTA_TEMP_C);
}

// Packet format (keys documented in docs/SUMMARY.md):
// {"v":1,"seq":12,"t":"periodic","hr":74,"spo2":98,"temp":36.6,"act":120,"bat":92,"fw":"1.0.0","fall_g":2.8}
static std::string buildPacket(const char *trigger, const Snapshot &s, float fallG) {
  char buf[200];
  int n = snprintf(buf, sizeof(buf), "{\"v\":1,\"seq\":%lu,\"t\":\"%s\"", (unsigned long)++sequence, trigger);
  if (s.hr) n += snprintf(buf + n, sizeof(buf) - n, ",\"hr\":%d", s.hr);
  if (s.spo2) n += snprintf(buf + n, sizeof(buf) - n, ",\"spo2\":%d", s.spo2);
  if (s.temp > 0) n += snprintf(buf + n, sizeof(buf) - n, ",\"temp\":%.1f", s.temp);
  if (motionOk && motion.activityMg() >= 0) n += snprintf(buf + n, sizeof(buf) - n, ",\"act\":%d", motion.activityMg());
  n += snprintf(buf + n, sizeof(buf) - n, ",\"bat\":%u,\"fw\":\"%s\"", batteryPct, FIRMWARE_VERSION);
  if (fallG > 0) n += snprintf(buf + n, sizeof(buf) - n, ",\"fall_g\":%.2f", fallG);
  snprintf(buf + n, sizeof(buf) - n, "}");
  return std::string(buf);
}

static void transmit(const char *trigger, bool urgent, float fallG = 0) {
  Snapshot s = currentSnapshot();
  std::string packet = buildPacket(trigger, s, fallG);
  ble.send(packet, urgent);
  lastSent = s;
  Serial.printf("[TX] %s\n", packet.c_str());
}

void setup() {
  Serial.begin(115200);
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.setClock(400000);

  oximeterOk = oximeter.begin(Wire);
  motionOk = motion.begin(Wire);
  thermoOk = thermometer.begin();
  Serial.printf("Sensors: MAX30102=%d MPU6050=%d DS18B20=%d\n", oximeterOk, motionOk, thermoOk);

  char name[32];
  uint64_t mac = ESP.getEfuseMac();
  snprintf(name, sizeof(name), "%s%04X", DEVICE_NAME_PREFIX, (uint16_t)(mac >> 32));
  ble.begin(name);
  batteryPct = readBatteryPercent();
  ble.updateBattery(batteryPct);
  Serial.printf("Advertising as %s\n", name);
}

void loop() {
  unsigned long now = millis();
  if (oximeterOk) oximeter.update();
  if (motionOk) motion.update();
  if (thermoOk) thermometer.update();

  if (now - lastBatteryRead >= 60000UL) {
    batteryPct = readBatteryPercent();
    ble.updateBattery(batteryPct);
    lastBatteryRead = now;
  }

  // 1. Fall: always immediate, queued if the phone is out of range
  if (motionOk && motion.takeFallEvent()) {
    transmit("fall", true, motion.impactG());
    return;
  }

  // 2. Phone (re)connected or asked for data
  if (ble.takeSyncRequest()) {
    ble.flushQueue();
    transmit("sync", false);
    lastPeriodicTx = now;
    return;
  }

  // 3. Abnormal reading or sharp change, rate-limited
  Snapshot s = currentSnapshot();
  if ((isAbnormal(s) || changedSharply(s)) && now - lastAbnormalTx >= ABNORMAL_COOLDOWN_MS) {
    transmit("abnormal", true);
    lastAbnormalTx = now;
    lastPeriodicTx = now;
    return;
  }

  // 4. Periodic summary
  if (now - lastPeriodicTx >= PERIODIC_TX_MS) {
    transmit("periodic", false);
    lastPeriodicTx = now;
  }

  delay(5);  // yield to the BLE stack and keep the loop light
}
