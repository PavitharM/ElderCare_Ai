#include "pulse_oximeter.h"

#include <spo2_algorithm.h>

#include <algorithm>

static const float kSampleRate = 25.0f;  // effective samples/s (100 Hz, average 4)

template <typename T>
static T medianOf(T *values, int count) {
  std::sort(values, values + count);
  return count % 2 ? values[count / 2] : (values[count / 2 - 1] + values[count / 2]) / 2;
}

// Median of the readings that agree with each other, or 0 when fewer than PPG_MIN_AGREE do.
static int consensus(const int *history, float tolerance) {
  int valid[PPG_WINDOW];
  int count = 0;
  for (int i = 0; i < PPG_WINDOW; i++) {
    if (history[i] > 0) valid[count++] = history[i];
  }
  if (count < PPG_MIN_AGREE) return 0;

  int median = medianOf(valid, count);
  int agreeing[PPG_WINDOW];
  int agreeCount = 0;
  for (int i = 0; i < count; i++) {
    if (fabsf(valid[i] - median) <= tolerance) agreeing[agreeCount++] = valid[i];
  }
  return agreeCount >= PPG_MIN_AGREE ? medianOf(agreeing, agreeCount) : 0;
}

int heartRateFromBeats(const uint32_t *ir, int count) {
  static const int kMaxSamples = 256;
  static const int kPeakHalfWidth = 6;  // a beat is the highest point within +/- 0.24 s
  static const int kMinBeatGap = 8;     // samples, i.e. at most ~187 BPM
  if (count > kMaxSamples) count = kMaxSamples;
  static float pulse[kMaxSamples];
  static float smooth[kMaxSamples];

  // Remove the slow baseline (1 s centred mean) and invert: each heartbeat is a dip in reflected IR
  for (int i = 0; i < count; i++) {
    int from = max(0, i - 12), to = min(count - 1, i + 12);
    float sum = 0;
    for (int j = from; j <= to; j++) sum += ir[j];
    pulse[i] = sum / (to - from + 1) - ir[i];
  }
  float mean = 0;
  for (int i = 0; i < count; i++) {
    int from = max(0, i - 1), to = min(count - 1, i + 1);
    float sum = 0;
    for (int j = from; j <= to; j++) sum += pulse[j];
    smooth[i] = sum / (to - from + 1);
    mean += smooth[i];
  }
  mean /= count;
  float variance = 0;
  for (int i = 0; i < count; i++) variance += (smooth[i] - mean) * (smooth[i] - mean);
  float threshold = 0.5f * sqrtf(variance / count);

  static float intervals[kMaxSamples];
  int intervalCount = 0;
  int lastPeak = -1;
  for (int i = kPeakHalfWidth; i < count - kPeakHalfWidth; i++) {
    if (smooth[i] <= threshold) continue;
    bool isPeak = true;
    for (int j = i - kPeakHalfWidth; j <= i + kPeakHalfWidth && isPeak; j++) isPeak = smooth[j] <= smooth[i];
    if (!isPeak || (lastPeak >= 0 && i - lastPeak < kMinBeatGap)) continue;
    if (lastPeak >= 0) {
      float seconds = (i - lastPeak) / kSampleRate;
      if (seconds >= 0.33f && seconds <= 2.0f) intervals[intervalCount++] = seconds;
    }
    lastPeak = i;
  }
  if (intervalCount < 4) return 0;

  float median = medianOf(intervals, intervalCount);
  static float regular[kMaxSamples];
  int regularCount = 0;
  for (int i = 0; i < intervalCount; i++) {
    if (fabsf(intervals[i] - median) <= PPG_BEAT_REGULARITY * median) regular[regularCount++] = intervals[i];
  }
  if (regularCount < PPG_MIN_REGULAR_SHARE * intervalCount) return 0;  // uneven spacing = movement
  return (int)lroundf(60.0f / medianOf(regular, regularCount));
}

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

    bool onSkin = ir >= FINGER_IR_THRESHOLD;
    if (onSkin && !onSkin_) contactSince_ = millis();
    onSkin_ = onSkin;
    if (!onSkin_) {  // contact lost: drop partial data so stale values are never reported
      resetReadings();
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

    beatIr_[beatFilled_] = ir;
    if (++beatFilled_ == kBeatWindowLen) {
      hr_ = heartRateFromBeats(beatIr_, kBeatWindowLen);  // 8 s of contact before the first value
      memmove(beatIr_, beatIr_ + kShift, (kBeatWindowLen - kShift) * sizeof(uint32_t));
      beatFilled_ = kBeatWindowLen - kShift;
    }
  }
}

void PulseOximeter::compute() {
  int32_t spo2, hr;
  int8_t spo2Valid, hrValid;
  maxim_heart_rate_and_oxygen_saturation(ir_, kBufferLen, red_, &spo2, &spo2Valid, &hr, &hrValid);
  if (millis() - contactSince_ < PPG_SETTLE_MS) return;  // finger still settling: results are noise

  spo2History_[historyIndex_] = (spo2Valid && spo2 >= 70 && spo2 <= 100) ? spo2 : 0;
  historyIndex_ = (historyIndex_ + 1) % PPG_WINDOW;
  spo2_ = consensus(spo2History_, PPG_SPO2_AGREE_ABS);
}

void PulseOximeter::resetReadings() {
  filled_ = 0;
  beatFilled_ = 0;
  hr_ = 0;
  spo2_ = 0;
  for (int i = 0; i < PPG_WINDOW; i++) spo2History_[i] = 0;
  historyIndex_ = 0;
}
