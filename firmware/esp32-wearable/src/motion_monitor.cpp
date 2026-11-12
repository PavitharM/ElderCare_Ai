#include "motion_monitor.h"

#include "config.h"

static const float kGravity = 9.80665f;

bool MotionMonitor::begin(TwoWire &wire) {
  if (!mpu_.begin(MPU6050_I2CADDR_DEFAULT, &wire)) return false;
  mpu_.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu_.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu_.setFilterBandwidth(MPU6050_BAND_21_HZ);
  windowStart_ = millis();
  return true;
}

void MotionMonitor::update() {
  unsigned long now = millis();
  if (now - lastSample_ < MOTION_SAMPLE_MS) return;
  lastSample_ = now;

  sensors_event_t a, g, temp;
  mpu_.getEvent(&a, &g, &temp);
  float magG = sqrtf(a.acceleration.x * a.acceleration.x + a.acceleration.y * a.acceleration.y +
                     a.acceleration.z * a.acceleration.z) / kGravity;
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
