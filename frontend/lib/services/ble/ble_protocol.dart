import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// GATT contract with the ESP32 firmware (firmware/esp32-wearable/include/config.h).
class BleProtocol {
  static final Guid serviceUuid = Guid("6e1f0001-8b3a-4c2e-9d5a-6f1e2d3c4b5a");
  static final Guid telemetryUuid = Guid("6e1f0002-8b3a-4c2e-9d5a-6f1e2d3c4b5a");
  static final Guid controlUuid = Guid("6e1f0003-8b3a-4c2e-9d5a-6f1e2d3c4b5a");
  static const String deviceNamePrefix = "ElderGuard-";
}

/// One JSON notification from the wearable, e.g.
/// {"v":1,"seq":12,"t":"abnormal","hr":118,"spo2":97,"temp":36.4,"act":85,"bat":91,"fw":"1.0.0"}
class WearablePacket {
  final String trigger; // periodic | abnormal | fall | sync
  final int? sequence;
  final double? heartRate;
  final double? spo2;
  final double? temperature;
  final double? activityMg;
  final int? battery;
  final String? firmware;
  final double? fallImpactG;
  final DateTime receivedAt;

  WearablePacket({
    required this.trigger,
    this.sequence,
    this.heartRate,
    this.spo2,
    this.temperature,
    this.activityMg,
    this.battery,
    this.firmware,
    this.fallImpactG,
    required this.receivedAt,
  });

  bool get isFall => trigger == "fall";

  static WearablePacket? tryParse(List<int> bytes) {
    try {
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      double? num_(String k) => (data[k] as num?)?.toDouble();
      return WearablePacket(
        trigger: data["t"] as String? ?? "periodic",
        sequence: data["seq"] as int?,
        heartRate: num_("hr"),
        spo2: num_("spo2"),
        temperature: num_("temp"),
        activityMg: num_("act"),
        battery: data["bat"] as int?,
        firmware: data["fw"] as String?,
        fallImpactG: num_("fall_g"),
        receivedAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      return null; // malformed / truncated notification (FR-07: invalid transmissions are ignored)
    }
  }

  /// Body for POST /vitals/telemetry.
  Map<String, dynamic> toTelemetryJson(String deviceId) {
    final measuredAt = receivedAt.toIso8601String();
    final readings = <Map<String, dynamic>>[
      if (heartRate != null) {"metric_type": "heart_rate", "value": heartRate, "measured_at": measuredAt},
      if (spo2 != null) {"metric_type": "spo2", "value": spo2, "measured_at": measuredAt},
      if (temperature != null) {"metric_type": "temperature", "value": temperature, "measured_at": measuredAt},
      if (activityMg != null) {"metric_type": "activity_level", "value": activityMg, "measured_at": measuredAt},
    ];
    return {
      "device_id": deviceId,
      "trigger": trigger,
      if (sequence != null) "sequence": sequence,
      if (battery != null) "battery_level": battery,
      "readings": readings,
      if (isFall && fallImpactG != null) "fall": {"impact_g": fallImpactG},
    };
  }
}
