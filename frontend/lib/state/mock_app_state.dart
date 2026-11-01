import 'dart:async';

import 'package:flutter/material.dart';
import '../models/vital_metric.dart';
import '../models/medication.dart';
import '../models/emergency_event.dart';
import '../models/user_profile.dart';
import '../core/constants/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import '../screens/emergency/fall_detected_countdown_screen.dart';
import '../services/ble/ble_protocol.dart';
import '../services/ble/wearable_ble_service.dart';
import '../services/elderguard_api_service.dart';
import '../services/emergency_sms_service.dart';

enum AppUserRole { elderly, caregiver }

class MockAppState extends ChangeNotifier {
  static final MockAppState _instance = MockAppState._internal();
  factory MockAppState() => _instance;
  MockAppState._internal() {
    _sms.ensurePermission(); // ask up front so SMS works when an emergency happens
    initBackendSync();
  }

  final EmergencySmsService _sms = EmergencySmsService();

  // Direct SMS recipients (caregivers + emergency contacts). Refreshed from the backend
  // after login; the profile's emergency contact is the offline fallback.
  late List<String> alertPhones = [elderlyProfile.emergencyContactPhone.replaceAll(" ", "")];
  DateTime? _lastEmergencySmsAt;
  static const Duration _criticalSmsCooldown = Duration(minutes: 10);

  /// Sends the emergency SMS from the patient's phone (works without internet).
  Future<void> _sendEmergencySms(String reason) async {
    _lastEmergencySmsAt = DateTime.now();
    final time = TimeOfDay.fromDateTime(DateTime.now());
    final hh = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final mm = time.minute.toString().padLeft(2, "0");
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    final message = "ElderGuard EMERGENCY: ${elderlyProfile.name} - $reason at $hh:$mm $period. "
        "Last vitals: HR ${heartRate.value} ${heartRate.unit}, SpO2 ${spO2.value}%, Temp ${temperature.value}°C. "
        "Please check on them immediately.";
    final sent = await _sms.sendToAll(alertPhones, message);
    debugPrint("Emergency SMS sent to $sent contact(s): $reason");
  }

  // Hard critical limits mirrored from the backend (core/constants.py) so the phone can
  // alert even when the backend is unreachable.
  bool _isLocallyCritical(WearablePacket p) =>
      (p.heartRate != null && (p.heartRate! < 40 || p.heartRate! > 130)) ||
      (p.spo2 != null && p.spo2! < 90) ||
      (p.temperature != null && (p.temperature! < 35 || p.temperature! >= 39));

  final ElderGuardApiService _apiService = ElderGuardApiService();

  AppUserRole currentRole = AppUserRole.elderly;
  bool isBackendConnected = false;
  bool isLoading = false;
  String? activeQrToken;

  void setRole(AppUserRole role) {
    currentRole = role;
    notifyListeners();
  }

  // Initialize and sync with FastAPI backend in background
  Future<void> initBackendSync() async {
    try {
      final loginData = await _apiService.login("+94771234567", "password123");
      if (loginData != null) {
        isBackendConnected = true;
        await syncDataFromBackend();
        final phones = await _apiService.getAlertContactPhones();
        if (phones != null && phones.isNotEmpty) alertPhones = phones;
        await _restorePairedWearable();
      }
    } catch (e) {
      debugPrint("Live backend offline. Falling back to local clinical mock state: $e");
    }
  }

  Future<void> syncDataFromBackend() async {
    try {
      // 1. Sync vitals
      final vitalsMap = await _apiService.getLatestVitals();
      if (vitalsMap != null) {
        if (vitalsMap.containsKey("heartRate")) heartRate = vitalsMap["heartRate"]!;
        if (vitalsMap.containsKey("spO2")) spO2 = vitalsMap["spO2"]!;
        if (vitalsMap.containsKey("temperature")) temperature = vitalsMap["temperature"]!;
      }

      // 2. Sync medications
      final liveMeds = await _apiService.getMedications();
      if (liveMeds != null && liveMeds.isNotEmpty) {
        medications = liveMeds;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  // Wearable Device State
  bool isWearableConnected = true;
  int wearableBattery = 92;
  String wearableName = "ElderGuard Band V2 #8492";

  String? pairedWearableId;
  final WearableBleService _ble = WearableBleService();
  StreamSubscription<WearablePacket>? _packetSub;
  StreamSubscription<bool>? _connectionSub;

  void setWearableConnection(bool connected) {
    isWearableConnected = connected;
    notifyListeners();
  }

  /// Connect to a scanned ESP32 and register it with the backend (FR-05, FR-07).
  Future<bool> pairWearable(String deviceId, String name) async {
    try {
      await _ble.connect(deviceId);
      _listenToWearable();
      final ok = await _apiService.pairDevice(name: name, deviceId: deviceId, battery: wearableBattery);
      pairedWearableId = deviceId;
      wearableName = name;
      isWearableConnected = true;
      notifyListeners();
      return ok;
    } catch (e) {
      debugPrint("Wearable pairing failed: $e");
      return false;
    }
  }

  Future<void> reconnectWearable() async {
    if (!WearableBleService.isSupported || pairedWearableId == null) return;
    try {
      await _ble.connect(pairedWearableId!);
      _listenToWearable();
    } catch (e) {
      debugPrint("Wearable reconnect failed: $e");
    }
  }

  // Re-connect to the wearable stored on the backend after an app restart.
  Future<void> _restorePairedWearable() async {
    final device = await _apiService.getMyDevice();
    if (device == null) return;
    wearableName = device["device_name"] ?? wearableName;
    wearableBattery = device["battery_level"] ?? wearableBattery;
    final id = device["mac_address"] as String?;
    if (id != null && device["is_simulated"] != true) {
      pairedWearableId = id;
      await reconnectWearable();
    }
    notifyListeners();
  }

  void _listenToWearable() {
    _packetSub ??= _ble.packets.listen(_onWearablePacket);
    _connectionSub ??= _ble.connectionChanges.listen((connected) {
      isWearableConnected = connected;
      notifyListeners();
      _apiService.updateDeviceStatus(connected, battery: wearableBattery);
    });
  }

  Future<void> _onWearablePacket(WearablePacket packet) async {
    final deviceId = pairedWearableId ?? _ble.deviceId;
    if (deviceId == null) return;
    if (packet.battery != null) wearableBattery = packet.battery!;

    final result = await _apiService.sendTelemetry(packet.toTelemetryJson(deviceId));
    if (packet.isFall) {
      activeFallIncidentId = result?["incident_id"] as String?;
      _openFallCountdown();
    }
    await syncDataFromBackend();

    // Critical vitals: backend verdict, or local hard limits when offline. Rate-limited so a
    // persisting condition (or an SOS/fall that was just texted) doesn't flood caregivers.
    final critical = result?["risk_level"] == "critical" || _isLocallyCritical(packet);
    final recentlyAlerted = _lastEmergencySmsAt != null &&
        DateTime.now().difference(_lastEmergencySmsAt!) < _criticalSmsCooldown;
    if (critical && !packet.isFall && !recentlyAlerted) {
      await _sendEmergencySms("CRITICAL health readings detected by the wearable");
    }
  }

  void _openFallCountdown() {
    final nav = appNavigatorKey.currentState;
    if (nav == null || FallDetectedCountdownScreen.isOpen) return;
    nav.push(MaterialPageRoute(builder: (_) => FallDetectedCountdownScreen(incidentId: activeFallIncidentId)));
  }

  // Elderly Profile
  ElderlyProfile elderlyProfile = const ElderlyProfile(
    id: "ELD-001",
    name: "Kamala Perera",
    age: 72,
    gender: "Female",
    bloodGroup: "O+",
    address: "No. 42, Temple Road, Colombo 03",
    phone: "+94 77 123 4567",
    linkingCode: "EG-8829-KP",
    chronicConditions: ["Hypertension", "Type 2 Diabetes", "Mild Arthritis"],
    allergies: ["Penicillin", "Sulfa Drugs"],
    primaryDoctor: "Dr. Anura Wijesinghe (General Hospital)",
    emergencyContactName: "Nimal Perera",
    emergencyContactPhone: "+94 71 987 6543",
    emergencyContactRelation: "Son",
    avatarAsset: AppAssets.avatarKamala,
  );

  // Caregiver Profile
  CaregiverProfileData caregiverProfile = const CaregiverProfileData(
    id: "CG-001",
    name: "Nimal Perera",
    relation: "Son & Primary Caregiver",
    email: "nimal.perera@gmail.com",
    phone: "+94 71 987 6543",
    avatarAsset: AppAssets.avatarNimal,
    linkedElderlyCodes: ["EG-8829-KP"],
  );

  // Vitals
  VitalReading heartRate = const VitalReading(
    label: "Heart Rate",
    value: "74",
    unit: "BPM",
    statusText: "Normal & Regular",
    status: MetricStatus.normal,
    icon: Icons.favorite_rounded,
    tintColor: Color(0xFFE53935),
    normalRange: "60 - 100 BPM",
    history7Days: [72, 75, 78, 71, 74, 76, 74],
  );

  VitalReading spO2 = const VitalReading(
    label: "Blood Oxygen",
    value: "98",
    unit: "%",
    statusText: "Optimal Saturation",
    status: MetricStatus.optimal,
    icon: Icons.air_rounded,
    tintColor: Color(0xFF00838F),
    normalRange: "95% - 100%",
    history7Days: [98, 97, 98, 99, 98, 98, 98],
  );

  VitalReading temperature = const VitalReading(
    label: "Body Temp",
    value: "36.6",
    unit: "°C",
    statusText: "Healthy Range",
    status: MetricStatus.optimal,
    icon: Icons.thermostat_rounded,
    tintColor: Color(0xFFF59E0B),
    normalRange: "36.1°C - 37.2°C",
    history7Days: [36.5, 36.6, 36.7, 36.6, 36.4, 36.6, 36.6],
  );

  // Medications
  List<MedicationItem> medications = [
    MedicationItem(
      id: "MED-1",
      name: "Metformin 500mg",
      dosage: "1 Tablet",
      time: "08:00 AM",
      schedulePeriod: "Morning",
      instruction: "After Breakfast",
      isTaken: true,
    ),
    MedicationItem(
      id: "MED-2",
      name: "Amlodipine 5mg",
      dosage: "1 Tablet",
      time: "08:30 AM",
      schedulePeriod: "Morning",
      instruction: "With Water",
      isTaken: true,
    ),
    MedicationItem(
      id: "MED-3",
      name: "Calcium & Vit D3",
      dosage: "1 Capsule",
      time: "01:00 PM",
      schedulePeriod: "Afternoon",
      instruction: "After Lunch",
      isTaken: false,
    ),
    MedicationItem(
      id: "MED-4",
      name: "Atorvastatin 10mg",
      dosage: "1 Tablet",
      time: "08:30 PM",
      schedulePeriod: "Evening",
      instruction: "Before Sleep",
      isTaken: false,
    ),
  ];

  void toggleMedication(String id) {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      medications[idx].isTaken = !medications[idx].isTaken;
      notifyListeners();

      // Dispatch to live backend
      _apiService.confirmDose(id, medications[idx].isTaken);
    }
  }

  // Emergency Events
  List<EmergencyEvent> emergencyEvents = [
    EmergencyEvent(
      id: "EVT-101",
      title: "Potential Fall Detected",
      description: "Sudden deceleration 2.8G registered by wearable in Living Room.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      severity: EventSeverity.critical,
      location: "Living Room (Ground Floor)",
      impactForceG: 2.8,
      resolved: true,
    ),
    EmergencyEvent(
      id: "EVT-102",
      title: "Elevated Heart Rate",
      description: "Pulse reached 108 BPM while resting.",
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      severity: EventSeverity.warning,
      location: "Bedroom",
      impactForceG: null,
      resolved: true,
    ),
    EmergencyEvent(
      id: "EVT-103",
      title: "Wearable Recharged",
      description: "Battery reached 95% and reconnected to monitoring hub.",
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: EventSeverity.info,
      location: "Charging Cradle",
      impactForceG: null,
      resolved: true,
    ),
  ];

  String? activeFallIncidentId;

  /// Called when the countdown screen opens. Wearable falls already have an incident;
  /// the manual demo button records one here.
  Future<void> beginFallCountdown(String? incidentId) async {
    if (incidentId != null) {
      activeFallIncidentId = incidentId;
      return;
    }
    await triggerFall(2.8, "Living Room");
  }

  /// Countdown expired or user pressed "send now": alert caregivers (FR-14, FR-21).
  Future<void> escalateActiveFall() async {
    final id = activeFallIncidentId;
    await Future.wait([
      _sendEmergencySms("a FALL was detected and they did not respond"),
      if (id != null) _apiService.escalateEmergency(id),
    ]);
  }

  Future<void> cancelActiveFall() async {
    final id = activeFallIncidentId;
    activeFallIncidentId = null;
    if (id != null) await cancelAlarm(id);
  }

  Future<void> triggerSos() async {
    // SMS first (no internet needed), backend push in parallel
    final smsFuture = _sendEmergencySms("SOS button pressed - they need help");
    final res = await _apiService.triggerSos();
    await smsFuture;
    if (res != null) {
      emergencyEvents.insert(
        0,
        EmergencyEvent(
          id: res["id"] ?? "EVT-${DateTime.now().millisecondsSinceEpoch}",
          title: res["title"] ?? "Manual SOS Triggered",
          description: res["description"] ?? "Emergency help requested.",
          timestamp: DateTime.now(),
          severity: EventSeverity.critical,
          location: res["location_text"] ?? "Home",
          impactForceG: null,
          resolved: false,
        ),
      );
      notifyListeners();
    }
  }

  /// URL encoded in the hospital QR code (FR-04). Generated once per app session.
  Future<String?> ensureHospitalQrUrl() async {
    if (activeQrToken != null || !isBackendConnected) return activeQrToken;
    activeQrToken = await _apiService.generateHospitalQRToken();
    if (activeQrToken != null) notifyListeners();
    return activeQrToken;
  }

  Future<void> triggerFall(double gForce, String location) async {
    try {
      final res = await _apiService.reportFall(impactG: gForce, location: location);
      if (res != null) {
        activeFallIncidentId = res["id"] as String?;
        emergencyEvents.insert(
          0,
          EmergencyEvent(
            id: res["id"] ?? "EVT-${DateTime.now().millisecondsSinceEpoch}",
            title: res["title"] ?? "Potential Fall Detected",
            description: res["description"] ?? "Deceleration registered.",
            timestamp: DateTime.now(),
            severity: EventSeverity.critical,
            location: location,
            impactForceG: gForce,
            resolved: false,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Trigger fall error: $e");
    }
  }

  Future<void> cancelAlarm(String eventId) async {
    try {
      await _apiService.cancelEmergency(eventId);
      final idx = emergencyEvents.indexWhere((e) => e.id == eventId);
      if (idx != -1) {
        emergencyEvents[idx] = EmergencyEvent(
          id: emergencyEvents[idx].id,
          title: emergencyEvents[idx].title,
          description: "${emergencyEvents[idx].description} (False alarm canceled)",
          timestamp: emergencyEvents[idx].timestamp,
          severity: EventSeverity.info,
          location: emergencyEvents[idx].location,
          impactForceG: emergencyEvents[idx].impactForceG,
          resolved: true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Cancel alarm error: $e");
    }
  }
}
