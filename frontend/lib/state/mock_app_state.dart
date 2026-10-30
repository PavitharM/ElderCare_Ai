import 'package:flutter/material.dart';
import '../models/vital_metric.dart';
import '../models/medication.dart';
import '../models/emergency_event.dart';
import '../models/user_profile.dart';
import '../core/constants/app_assets.dart';
import '../services/elderguard_api_service.dart';

enum AppUserRole { elderly, caregiver }

class MockAppState extends ChangeNotifier {
  static final MockAppState _instance = MockAppState._internal();
  factory MockAppState() => _instance;
  MockAppState._internal() {
    initBackendSync();
  }

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

  void setWearableConnection(bool connected) {
    isWearableConnected = connected;
    notifyListeners();
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

  Future<void> triggerFall(double gForce, String location) async {
    try {
      final res = await _apiService.reportFall(impactG: gForce, location: location);
      if (res != null) {
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
