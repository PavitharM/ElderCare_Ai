#pragma once
#include <Arduino.h>
#include <NimBLEDevice.h>

#include <string>

#include "config.h"

// BLE GATT server: notifies JSON telemetry packets and accepts control commands from the phone.
class BleLink {
 public:
  void begin(const std::string &deviceName);
  bool connected() const { return connected_; }

  // Sends now if connected; otherwise urgent packets are queued for delivery on reconnect.
  void send(const std::string &json, bool urgent);
  void updateBattery(uint8_t percent);

  // True once after the phone connects or writes "SYNC" (firmware then sends a fresh packet).
  bool takeSyncRequest();
  void flushQueue();

 private:
  class ServerCallbacks;
  class ControlCallbacks;

  NimBLECharacteristic *telemetry_ = nullptr;
  NimBLECharacteristic *battery_ = nullptr;
  volatile bool connected_ = false;
  volatile bool syncRequested_ = false;
  std::string queue_[PENDING_QUEUE_SIZE];
  int queueHead_ = 0;
  int queueCount_ = 0;

  void enqueue(const std::string &json);
};
