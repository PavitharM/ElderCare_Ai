#pragma once
#include <Arduino.h>
#include <MAX30105.h>

#include "config.h"

// Heart rate (BPM) from the spacing of pulse peaks in IR samples taken at 25 per second.
// Returns 0 when the beats are too few or too irregular (movement). Free function so it can be
// replayed against recorded finger data.
int heartRateFromBeats(const uint32_t *ir, int count);

// Non-blocking MAX30102 heart-rate / SpO2 reader. Heart rate counts beats over the last 8 s;
// SpO2 uses the Maxim reference algorithm and is reported only while its results agree.
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
  static const int kBeatWindowLen = 200;  // 8 s of IR samples for beat counting

  MAX30105 sensor_;
  uint32_t ir_[kBufferLen];
  uint32_t red_[kBufferLen];
  int filled_ = 0;
  uint32_t beatIr_[kBeatWindowLen];
  int beatFilled_ = 0;
  bool onSkin_ = false;
  unsigned long contactSince_ = 0;
  int hr_ = 0;
  int spo2_ = 0;
  int spo2History_[PPG_WINDOW] = {};  // per-second results, 0 = invalid
  int historyIndex_ = 0;

  void compute();
  void resetReadings();
};
