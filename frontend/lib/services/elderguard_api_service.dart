import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';
import '../models/vital_metric.dart';
import '../models/medication.dart';

class ElderGuardApiService {
  final ApiClient _client = ApiClient();

  // Authentication
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final res = await _client.post("/auth/login", body: {
        "username": username,
        "password": password,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _client.setToken(data["access_token"]);
        return data;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
    return null;
  }

  // Fetch Dashboard
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final res = await _client.get("/elderly/me/dashboard");
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Get dashboard error: $e");
    }
    return null;
  }

  // Fetch Latest Vitals
  Future<Map<String, VitalReading>?> getLatestVitals() async {
    try {
      final res = await _client.get("/vitals/latest");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final hrData = data["heart_rate"];
        final spo2Data = data["spo2"];
        final tempData = data["temperature"];

        MetricStatus parseStatus(String s) {
          switch (s) {
            case "optimal":
              return MetricStatus.optimal;
            case "warning":
              return MetricStatus.warning;
            case "critical":
              return MetricStatus.critical;
            default:
              return MetricStatus.normal;
          }
        }

        List<double> parseHistory(List<dynamic>? list) {
          if (list == null) return [];
          return list.map((e) => (e as num).toDouble()).toList();
        }

        return {
          "heartRate": VitalReading(
            label: hrData["label"] ?? "Heart Rate",
            value: hrData["value"] ?? "74",
            unit: hrData["unit"] ?? "BPM",
            statusText: hrData["status_text"] ?? "Normal",
            status: parseStatus(hrData["status"]),
            icon: Icons.favorite_rounded,
            tintColor: const Color(0xFFE53935),
            normalRange: hrData["normal_range"] ?? "60 - 100 BPM",
            history7Days: parseHistory(hrData["history_7_days"]),
          ),
          "spO2": VitalReading(
            label: spo2Data["label"] ?? "Blood Oxygen",
            value: spo2Data["value"] ?? "98",
            unit: spo2Data["unit"] ?? "%",
            statusText: spo2Data["status_text"] ?? "Optimal",
            status: parseStatus(spo2Data["status"]),
            icon: Icons.air_rounded,
            tintColor: const Color(0xFF00838F),
            normalRange: spo2Data["normal_range"] ?? "95% - 100%",
            history7Days: parseHistory(spo2Data["history_7_days"]),
          ),
          "temperature": VitalReading(
            label: tempData["label"] ?? "Body Temp",
            value: tempData["value"] ?? "36.6",
            unit: tempData["unit"] ?? "°C",
            statusText: tempData["status_text"] ?? "Healthy",
            status: parseStatus(tempData["status"]),
            icon: Icons.thermostat_rounded,
            tintColor: const Color(0xFFF59E0B),
            normalRange: tempData["normal_range"] ?? "36.1°C - 37.2°C",
            history7Days: parseHistory(tempData["history_7_days"]),
          ),
        };
      }
    } catch (e) {
      debugPrint("Get vitals error: $e");
    }
    return null;
  }

  // Fetch Medication Schedule
  Future<List<MedicationItem>?> getMedications() async {
    try {
      final res = await _client.get("/medications/my-schedule");
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) {
          return MedicationItem(
            id: item["id"],
            name: item["name"],
            dosage: item["dosage"],
            time: item["time"],
            schedulePeriod: item["schedule_period"],
            instruction: item["instruction"] ?? "As directed",
            isTaken: item["is_taken"] ?? false,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Get medications error: $e");
    }
    return null;
  }

  // Confirm Medication Dose
  Future<bool> confirmDose(String medicationId, bool taken) async {
    try {
      final res = await _client.post("/medications/$medicationId/confirm-dose?taken=$taken");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Confirm dose error: $e");
      return false;
    }
  }

  // Trigger Fall Incident
  Future<Map<String, dynamic>?> reportFall({double impactG = 2.8, String location = "Living Room"}) async {
    try {
      final res = await _client.post("/emergencies/fall-detected", body: {
        "title": "Deceleration ${impactG}G registered",
        "impact_force_g": impactG,
        "location_text": location,
      });
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Report fall error: $e");
    }
    return null;
  }

  // Cancel False Alarm
  Future<bool> cancelEmergency(String incidentId) async {
    try {
      final res = await _client.post("/emergencies/$incidentId/cancel");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Cancel emergency error: $e");
      return false;
    }
  }

  // Generate Emergency QR Token. Returns the zero-login hospital URL encoded in the QR code.
  Future<String?> generateHospitalQRToken() async {
    try {
      final res = await _client.post("/triage/generate-token");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["qr_url"] ?? data["qr_token"];
      }
    } catch (e) {
      debugPrint("Generate QR token error: $e");
    }
    return null;
  }

  // Numbers the phone texts directly in an emergency
  Future<List<String>?> getAlertContactPhones() async {
    try {
      final res = await _client.get("/elderly/me/alert-contacts");
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((c) => c["phone"] as String).toList();
      }
    } catch (e) {
      debugPrint("Get alert contacts error: $e");
    }
    return null;
  }

  // Manual SOS
  Future<Map<String, dynamic>?> triggerSos({String location = "Home"}) async {
    try {
      final res = await _client.post("/emergencies/sos", body: {"location_text": location});
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      debugPrint("SOS error: $e");
    }
    return null;
  }

  // Fall countdown expired / user asked to send now
  Future<bool> escalateEmergency(String incidentId) async {
    try {
      final res = await _client.post("/emergencies/$incidentId/escalate");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Escalate emergency error: $e");
      return false;
    }
  }

  // Wearable
  Future<Map<String, dynamic>?> getMyDevice() async {
    try {
      final res = await _client.get("/devices/my-device");
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      debugPrint("Get device error: $e");
    }
    return null;
  }

  Future<bool> pairDevice({required String name, required String deviceId, String? firmware, int? battery}) async {
    try {
      final res = await _client.post("/devices/pair", body: {
        "device_name": name,
        "mac_address": deviceId,
        "firmware_version": ?firmware,
        "battery_level": ?battery,
      });
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Pair device error: $e");
      return false;
    }
  }

  Future<void> updateDeviceStatus(bool connected, {int? battery}) async {
    try {
      await _client.put("/devices/my-device/status", body: {
        "connection_status": connected ? "connected" : "disconnected",
        "battery_level": ?battery,
      });
    } catch (e) {
      debugPrint("Device status error: $e");
    }
  }

  // Relay one wearable packet; returns the server result (risk level, incident id)
  Future<Map<String, dynamic>?> sendTelemetry(Map<String, dynamic> body) async {
    try {
      final res = await _client.post("/vitals/telemetry", body: body);
      if (res.statusCode == 200) return jsonDecode(res.body);
      debugPrint("Telemetry rejected (${res.statusCode}): ${res.body}");
    } catch (e) {
      debugPrint("Telemetry error: $e");
    }
    return null;
  }
}
