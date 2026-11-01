#include "ble_link.h"

#include "config.h"

class BleLink::ServerCallbacks : public NimBLEServerCallbacks {
 public:
  explicit ServerCallbacks(BleLink *link) : link_(link) {}
  void onConnect(NimBLEServer *server) override {
    link_->connected_ = true;
    link_->syncRequested_ = true;  // send current values + queued alerts right away
  }
  void onDisconnect(NimBLEServer *server) override {
    link_->connected_ = false;
    NimBLEDevice::startAdvertising();
  }

 private:
  BleLink *link_;
};

class BleLink::ControlCallbacks : public NimBLECharacteristicCallbacks {
 public:
  explicit ControlCallbacks(BleLink *link) : link_(link) {}
  void onWrite(NimBLECharacteristic *characteristic) override {
    std::string cmd = characteristic->getValue();
    if (cmd == "SYNC" || cmd == "PING") link_->syncRequested_ = true;
  }

 private:
  BleLink *link_;
};

void BleLink::begin(const std::string &deviceName) {
  NimBLEDevice::init(deviceName);
  NimBLEDevice::setMTU(BLE_MTU);
  NimBLEDevice::setPower(ESP_PWR_LVL_P3);  // moderate TX power: enough for a room, saves battery

  NimBLEServer *server = NimBLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks(this));

  NimBLEService *service = server->createService(BLE_SERVICE_UUID);
  telemetry_ = service->createCharacteristic(BLE_TELEMETRY_UUID, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  NimBLECharacteristic *control = service->createCharacteristic(BLE_CONTROL_UUID, NIMBLE_PROPERTY::WRITE);
  control->setCallbacks(new ControlCallbacks(this));
  service->start();

  // Standard Battery Service (0x180F / 0x2A19) and Device Information firmware revision
  NimBLEService *batteryService = server->createService("180F");
  battery_ = batteryService->createCharacteristic("2A19", NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  batteryService->start();
  NimBLEService *info = server->createService("180A");
  info->createCharacteristic("2A26", NIMBLE_PROPERTY::READ)->setValue(std::string(FIRMWARE_VERSION));
  info->start();

  NimBLEAdvertising *adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(BLE_SERVICE_UUID);
  adv->setScanResponse(true);
  adv->setMinInterval(800);  // 500 ms advertising interval (units of 0.625 ms): low power
  adv->setMaxInterval(1600);
  adv->start();
}

void BleLink::send(const std::string &json, bool urgent) {
  if (connected_) {
    telemetry_->setValue(json);
    telemetry_->notify();
  } else if (urgent) {
    enqueue(json);  // periodic packets are dropped while offline; a fresh one is sent on reconnect
  }
}

void BleLink::enqueue(const std::string &json) {
  int tail = (queueHead_ + queueCount_) % PENDING_QUEUE_SIZE;
  queue_[tail] = json;
  if (queueCount_ < PENDING_QUEUE_SIZE) {
    queueCount_++;
  } else {
    queueHead_ = (queueHead_ + 1) % PENDING_QUEUE_SIZE;  // overwrite the oldest
  }
}

void BleLink::flushQueue() {
  while (connected_ && queueCount_ > 0) {
    telemetry_->setValue(queue_[queueHead_]);
    telemetry_->notify();
    queueHead_ = (queueHead_ + 1) % PENDING_QUEUE_SIZE;
    queueCount_--;
    delay(30);  // give the phone time to process each notification
  }
}

void BleLink::updateBattery(uint8_t percent) {
  battery_->setValue(&percent, 1);
  if (connected_) battery_->notify();
}

bool BleLink::takeSyncRequest() {
  bool requested = syncRequested_;
  syncRequested_ = false;
  return requested;
}
