#pragma once
#include <Arduino.h>
#include <MAX30105.h>

// Non-blocking MAX30102 heart-rate / SpO2 reader using the Maxim reference algorithm.
class PulseOximeter {
 public:
  bool begin(TwoWire &wire);
  void update();

  bool onSkin() const { return onSkin_; }
  bool hasHeartRate() const { return onSkin_ && hr_ > 0; }
  bool hasSpo2() const { return onSkin_ && spo2_ > 0; }
  int heartRate() const { return hr_; }
  int spo2() const { return spo2_; }

 private:
  static const int kBufferLen = 100;  // 4 s at 25 effective samples/s
  static const int kShift = 25;       // recompute every second

  MAX30105 sensor_;
  uint32_t ir_[kBufferLen];
  uint32_t red_[kBufferLen];
  int filled_ = 0;
  bool onSkin_ = false;
  int hr_ = 0;
  int spo2_ = 0;
  int hrHistory_[4] = {0, 0, 0, 0};
  int hrIndex_ = 0;

  void compute();
};
