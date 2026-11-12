#include "temperature_sensor.h"

bool TemperatureSensor::begin() {
  sensors_.begin();
  sensors_.setResolution(12);
  sensors_.setWaitForConversion(false);
  return sensors_.getDeviceCount() > 0;
}

void TemperatureSensor::update() {
  unsigned long now = millis();
  if (!waiting_ && now - lastRequest_ >= TEMP_READ_INTERVAL_MS) {
    sensors_.requestTemperatures();
    lastRequest_ = now;
    waiting_ = true;
  } else if (waiting_ && now - lastRequest_ >= 800) {  // 12-bit conversion takes 750 ms
    float c = sensors_.getTempCByIndex(0);
    waiting_ = false;
    valid_ = c != DEVICE_DISCONNECTED_C && c > 20.0f && c < 45.0f;
    if (valid_) celsius_ = c + TEMP_OFFSET_C;
  }
}
