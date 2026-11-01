import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_protocol.dart';

/// Scans for, connects to and streams data from the ElderGuard ESP32 wearable.
/// Real BLE runs on Android/iOS only; on web/desktop [isSupported] is false and callers
/// keep their simulated behaviour.
class WearableBleService {
  static final WearableBleService _instance = WearableBleService._internal();
  factory WearableBleService() => _instance;
  WearableBleService._internal();

  final _packets = StreamController<WearablePacket>.broadcast();
  final _connection = StreamController<bool>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _control;
  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  Timer? _reconnectTimer;
  bool _wantConnected = false;
  bool _connected = false;

  Stream<WearablePacket> get packets => _packets.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;
  String? get deviceId => _device?.remoteId.str;

  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Scan for wearables advertising the ElderGuard service.
  Stream<List<ScanResult>> scan({Duration timeout = const Duration(seconds: 12)}) async* {
    if (!isSupported) return;
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await FlutterBluePlus.turnOn(); // asks the user to enable Bluetooth
      }
    }
    await FlutterBluePlus.startScan(withServices: [BleProtocol.serviceUuid], timeout: timeout);
    yield* FlutterBluePlus.onScanResults;
  }

  Future<void> stopScan() async {
    if (isSupported) await FlutterBluePlus.stopScan();
  }

  /// Connects, subscribes to telemetry notifications and keeps reconnecting until [disconnect].
  Future<void> connect(String remoteId) async {
    if (!isSupported) throw UnsupportedError("BLE is only available on Android/iOS");
    await stopScan();
    if (_device?.remoteId.str != remoteId) await disconnect();
    _wantConnected = true;
    _device = BluetoothDevice.fromId(remoteId);

    _stateSub ??= _device!.connectionState.listen((state) {
      final nowConnected = state == BluetoothConnectionState.connected;
      if (nowConnected != _connected) {
        _connected = nowConnected;
        _connection.add(nowConnected);
      }
      if (!nowConnected && _wantConnected) _scheduleReconnect();
    });

    await _open();
  }

  Future<void> _open() async {
    final device = _device!;
    // License.nonprofit: educational use (SE5104 university project). Commercial use needs a paid license.
    await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 15));
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == BleProtocol.serviceUuid,
      orElse: () => throw StateError("Not an ElderGuard wearable"),
    );
    final telemetry = service.characteristics.firstWhere((c) => c.uuid == BleProtocol.telemetryUuid);
    _control = service.characteristics.where((c) => c.uuid == BleProtocol.controlUuid).firstOrNull;

    await _valueSub?.cancel();
    _valueSub = telemetry.onValueReceived.listen((bytes) {
      final packet = WearablePacket.tryParse(bytes);
      if (packet != null) _packets.add(packet);
    });
    device.cancelWhenDisconnected(_valueSub!);
    await telemetry.setNotifyValue(true);
    await requestSync();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () async {
      if (!_wantConnected || _connected || _device == null) return;
      try {
        await _open();
      } catch (e) {
        debugPrint("Wearable reconnect failed: $e");
        _scheduleReconnect();
      }
    });
  }

  /// Ask the wearable for an immediate packet (also flushes alerts it queued while offline).
  Future<void> requestSync() async {
    try {
      await _control?.write(utf8.encode("SYNC"), withoutResponse: false);
    } catch (e) {
      debugPrint("Wearable sync request failed: $e");
    }
  }

  Future<void> disconnect() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    await _valueSub?.cancel();
    await _stateSub?.cancel();
    _valueSub = null;
    _stateSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _control = null;
    if (_connected) {
      _connected = false;
      _connection.add(false);
    }
  }
}
