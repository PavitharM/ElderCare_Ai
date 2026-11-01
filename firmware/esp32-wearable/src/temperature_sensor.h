#pragma once
#include <Arduino.h>
#include <DallasTemperature.h>
#include <OneWire.h>

#include "config.h"

// Non-blocking DS18B20 reader (requests a conversion, reads it ~800 ms later).
class TemperatureSensor {
 public:
  TemperatureSensor() : oneWire_(PIN_DS18B20), sensors_(&oneWire_) {}
  bool begin();
  void update();
  bool valid() const { return valid_; }
  float celsius() const { return celsius_; }

 private:
  OneWire oneWire_;
  DallasTemperature sensors_;
  unsigned long lastRequest_ = 0;
  bool waiting_ = false;
  bool valid_ = false;
  float celsius_ = 0;
};
