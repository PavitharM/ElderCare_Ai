#pragma once
#include <Arduino.h>
#include <Wire.h>

// MPU6050-compatible fall detection (free fall -> impact -> stillness) and activity index.
// Talks to the chip directly: many GY-521 boards carry clones that report a WHO_AM_I other
// than 0x68, which the Adafruit driver rejects even though their readings are fine.
class MotionMonitor {
 public:
  bool begin(TwoWire &wire);
  void update();

  // Returns true once per confirmed fall; impactG() holds the peak acceleration.
  bool takeFallEvent();
  float impactG() const { return impactG_; }

  // Mean dynamic acceleration in milli-g over the last completed window (-1 until ready).
  int activityMg() const { return activityMg_; }

 private:
  enum class Phase { Idle, FreeFall, Impact };

  void writeRegister(uint8_t reg, uint8_t value);
  int readRegister(uint8_t reg);
  bool readAccelMagnitudeG(float &magG);

  TwoWire *wire_ = nullptr;
  Phase phase_ = Phase::Idle;
  unsigned long lastSample_ = 0;
  unsigned long phaseStart_ = 0;
  unsigned long stillSince_ = 0;
  float impactG_ = 0;
  float peakG_ = 0;
  bool fallPending_ = false;

  double activitySum_ = 0;
  unsigned long activitySamples_ = 0;
  unsigned long windowStart_ = 0;
  int activityMg_ = -1;
};
