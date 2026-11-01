#include "pulse_oximeter.h"

#include <spo2_algorithm.h>

#include "config.h"

bool PulseOximeter::begin(TwoWire &wire) {
  if (!sensor_.begin(wire, I2C_SPEED_FAST)) return false;
  // LED power 60, average 4, Red+IR mode, 100 Hz, 411 us pulse, 4096 ADC range
  sensor_.setup(60, 4, 2, 100, 411, 4096);
  return true;
}

void PulseOximeter::update() {
  sensor_.check();  // pull new samples from the sensor FIFO
  while (sensor_.available()) {
    uint32_t ir = sensor_.getFIFOIR();
    uint32_t red = sensor_.getFIFORed();
    sensor_.nextSample();

    onSkin_ = ir >= FINGER_IR_THRESHOLD;
    if (!onSkin_) {  // contact lost: drop partial data so stale values are never reported
      filled_ = 0;
      hr_ = 0;
      spo2_ = 0;
      continue;
    }

    ir_[filled_] = ir;
    red_[filled_] = red;
    if (++filled_ == kBufferLen) {
      compute();
      // keep the newest 75 samples, refill the remaining 25
      memmove(ir_, ir_ + kShift, (kBufferLen - kShift) * sizeof(uint32_t));
      memmove(red_, red_ + kShift, (kBufferLen - kShift) * sizeof(uint32_t));
      filled_ = kBufferLen - kShift;
    }
  }
}

void PulseOximeter::compute() {
  int32_t spo2, hr;
  int8_t spo2Valid, hrValid;
  maxim_heart_rate_and_oxygen_saturation(ir_, kBufferLen, red_, &spo2, &spo2Valid, &hr, &hrValid);

  if (hrValid && hr >= 30 && hr <= 220) {
    hrHistory_[hrIndex_++ % 4] = hr;
    int sum = 0, n = 0;
    for (int v : hrHistory_) {
      if (v > 0) { sum += v; n++; }
    }
    hr_ = n ? sum / n : 0;  // short moving average smooths algorithm jitter
  }
  if (spo2Valid && spo2 >= 70 && spo2 <= 100) {
    spo2_ = spo2;
  }
}
