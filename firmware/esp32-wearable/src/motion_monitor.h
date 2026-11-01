#pragma once
#include <Adafruit_MPU6050.h>
#include <Arduino.h>

// MPU6050 fall detection (free fall -> impact -> stillness) and activity index.
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

  Adafruit_MPU6050 mpu_;
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
