#include "motion_monitor.h"

#include "config.h"

static const uint8_t kAddress = 0x68;  // AD0 low
static const uint8_t kRegAccelConfig2 = 0x1D;  // accelerometer filter on MPU6500-family clones
static const uint8_t kRegConfig = 0x1A;
static const uint8_t kRegGyroConfig = 0x1B;
static const uint8_t kRegAccelConfig = 0x1C;
static const uint8_t kRegAccelData = 0x3B;
static const uint8_t kRegPowerMgmt = 0x6B;
static const uint8_t kRegWhoAmI = 0x75;
static const uint8_t kWhoAmIGenuine = 0x68;
static const uint8_t kAccelRange8G = 0x10;
static const uint8_t kGyroRange500Deg = 0x08;
static const uint8_t kFilter21Hz = 0x04;
static const float kAccelLsbPerG = 4096.0f;  // at +/-8 G

void MotionMonitor::writeRegister(uint8_t reg, uint8_t value) {
  wire_->beginTransmission(kAddress);
  wire_->write(reg);
  wire_->write(value);
  wire_->endTransmission();
}

int MotionMonitor::readRegister(uint8_t reg) {
  wire_->beginTransmission(kAddress);
  wire_->write(reg);
  if (wire_->endTransmission(false) != 0) return -1;
  if (wire_->requestFrom(kAddress, (uint8_t)1) != 1) return -1;
  return wire_->read();
}

bool MotionMonitor::readAccelMagnitudeG(float &magG) {
  wire_->beginTransmission(kAddress);
  wire_->write(kRegAccelData);
  if (wire_->endTransmission(false) != 0) return false;
  if (wire_->requestFrom(kAddress, (uint8_t)6) != 6) return false;
  float sumSquares = 0;
  for (int axis = 0; axis < 3; axis++) {
    int high = wire_->read();
    int low = wire_->read();
    float g = (int16_t)((high << 8) | low) / kAccelLsbPerG;
    sumSquares += g * g;
  }
  magG = sqrtf(sumSquares);
  return true;
}

bool MotionMonitor::begin(TwoWire &wire) {
  wire_ = &wire;
  int whoAmI = readRegister(kRegWhoAmI);
  if (whoAmI < 0) return false;
  writeRegister(kRegPowerMgmt, 0x80);  // reset
  delay(100);
  writeRegister(kRegPowerMgmt, 0x01);  // wake, gyro clock
  delay(50);
  writeRegister(kRegAccelConfig, kAccelRange8G);
  writeRegister(kRegGyroConfig, kGyroRange500Deg);
  writeRegister(kRegConfig, kFilter21Hz);
  if (whoAmI != kWhoAmIGenuine) writeRegister(kRegAccelConfig2, kFilter21Hz);
  if (readRegister(kRegAccelConfig) != kAccelRange8G) return false;
  windowStart_ = millis();
  return true;
}

void MotionMonitor::update() {
  unsigned long now = millis();
  if (now - lastSample_ < MOTION_SAMPLE_MS) return;
  lastSample_ = now;

  float magG;
  if (!readAccelMagnitudeG(magG)) return;  // a failed read must not look like free fall
  float dynamicG = fabsf(magG - 1.0f);

  // Activity index
  activitySum_ += dynamicG;
  activitySamples_++;
  if (now - windowStart_ >= ACTIVITY_WINDOW_MS) {
    activityMg_ = (int)(activitySum_ / activitySamples_ * 1000.0);
    activitySum_ = 0;
    activitySamples_ = 0;
    windowStart_ = now;
  }

  // Three-phase fall detector
  switch (phase_) {
    case Phase::Idle:
      if (magG < FALL_FREEFALL_G) {
        phase_ = Phase::FreeFall;
        phaseStart_ = now;
        peakG_ = 0;
      }
      break;

    case Phase::FreeFall:
      if (magG > FALL_IMPACT_G) {
        peakG_ = magG;
        phase_ = Phase::Impact;
        phaseStart_ = now;
      } else if (now - phaseStart_ > FALL_IMPACT_WINDOW_MS) {
        phase_ = Phase::Idle;  // dropped arm, not a fall
      }
      break;

    case Phase::Impact:
      // phaseStart_ = impact time, stillSince_ = start of the current still period
      if (magG > peakG_) peakG_ = magG;
      if (now - phaseStart_ < 300) {
        stillSince_ = now;  // ignore the bounce right after impact
      } else if (dynamicG > FALL_STILL_DYNAMIC_G) {
        stillSince_ = now;  // still moving
      }
      if (now - stillSince_ >= FALL_STILLNESS_MS) {
        impactG_ = peakG_;
        fallPending_ = true;  // impact followed by lying still = confirmed fall
        phase_ = Phase::Idle;
      } else if (now - phaseStart_ > FALL_STILLNESS_MS + 3000UL) {
        phase_ = Phase::Idle;  // kept moving after impact: person got up / sat down hard
      }
      break;
  }
}

bool MotionMonitor::takeFallEvent() {
  bool pending = fallPending_;
  fallPending_ = false;
  return pending;
}
