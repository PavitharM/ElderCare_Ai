import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Import All Screens for Quick Switcher
import '../onboarding/animated_loading_screen.dart';
import '../onboarding/welcome_registration_screen.dart';
import '../onboarding/elderly_reg_step1_screen.dart';
import '../onboarding/elderly_reg_step2_screen.dart';
import '../onboarding/elderly_reg_step3_screen.dart';
import '../onboarding/caregiver_registration_screen.dart';

import '../wearable/bluetooth_pairing_screen.dart';
import '../wearable/pairing_successful_screen.dart';
import '../wearable/my_wearable_screen.dart';

import '../elderly/health_dashboard_screen.dart';
import '../elderly/my_health_vitals_screen.dart';
import '../elderly/health_trends_screen.dart';
import '../elderly/health_history_screen.dart';
import '../elderly/my_medicines_screen.dart';
import '../elderly/medication_adherence_screen.dart';
import '../elderly/health_menu_screen.dart';
import '../elderly/elderly_profile_screen.dart';
import '../elderly/hospital_qr_code_screen.dart';

import '../emergency/fall_detected_countdown_screen.dart';
import '../emergency/fall_event_details_screen.dart';
import '../emergency/emergency_sos_confirm_screen.dart';
import '../emergency/emergency_alert_sent_screen.dart';
import '../emergency/emergency_alerts_log_screen.dart';

import '../caregiver/caregiver_portal_screen.dart';
import '../caregiver/kamala_overview_screen.dart';
import '../caregiver/linked_elderly_profiles_screen.dart';
import '../caregiver/caregiver_profile_screen.dart';

class ScreenCatalogSheet extends StatelessWidget {
  const ScreenCatalogSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScreenCatalogSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flows = [
      {
        "flow": "Flow A: Onboarding & Registration (6 Screens)",
        "screens": [
          {"name": "1. Animated Loading / Splash", "widget": const AnimatedLoadingScreen()},
          {"name": "2. Welcome & Role Choice", "widget": const WelcomeRegistrationScreen()},
          {"name": "3. Elderly Registration Step 1", "widget": const ElderlyRegStep1Screen()},
          {"name": "4. Elderly Registration Step 2", "widget": const ElderlyRegStep2Screen()},
          {"name": "5. Elderly Registration Step 3", "widget": const ElderlyRegStep3Screen()},
          {"name": "6. Caregiver Registration", "widget": const CaregiverRegistrationScreen()},
        ],
      },
      {
        "flow": "Flow B: Wearable & Device Pairing (3 Screens)",
        "screens": [
          {"name": "7. Bluetooth Wearable Pairing", "widget": const BluetoothPairingScreen()},
          {"name": "8. Pairing Successful", "widget": const PairingSuccessfulScreen()},
          {"name": "9. My Wearable Management", "widget": const MyWearableScreen()},
        ],
      },
      {
        "flow": "Flow C: Elderly Patient Experience (9 Screens)",
        "screens": [
          {"name": "10. Health Dashboard (Senior Home)", "widget": const HealthDashboardScreen()},
          {"name": "11. My Health Vitals (Continuous)", "widget": const MyHealthVitalsScreen()},
          {"name": "12. Health Trends (7-Day Charts)", "widget": const HealthTrendsScreen()},
          {"name": "13. Health History (Timeline & PDF)", "widget": const HealthHistoryScreen()},
          {"name": "14. My Medicines (Dose Schedule)", "widget": const MyMedicinesScreen()},
          {"name": "15. Medication Adherence (Score)", "widget": const MedicationAdherenceScreen()},
          {"name": "16. Health Menu & Profile (More)", "widget": const HealthMenuScreen()},
          {"name": "17. My Profile (Kamala Perera)", "widget": const ElderlyProfileScreen()},
          {"name": "18. Hospital QR Code (ER Triage)", "widget": const HospitalQrCodeScreen()},
        ],
      },
      {
        "flow": "Flow D: Emergency & Fall System (5 Screens)",
        "screens": [
          {"name": "19. Fall Detected Countdown (15s)", "widget": const FallDetectedCountdownScreen()},
          {"name": "20. Fall Detected Event Details (2.8G)", "widget": const FallEventDetailsScreen()},
          {"name": "21. Emergency SOS Confirmation (Hold)", "widget": const EmergencySosConfirmScreen()},
          {"name": "22. Emergency Alert Sent (Broadcast)", "widget": const EmergencyAlertSentScreen()},
          {"name": "23. Emergency Alerts (Caregiver Log)", "widget": const EmergencyAlertsLogScreen()},
        ],
      },
      {
        "flow": "Flow E: Caregiver Portal & Monitoring (4 Screens)",
        "screens": [
          {"name": "24. Caregiver Portal Home", "widget": const CaregiverPortalScreen()},
          {"name": "25. Kamala Perera Overview", "widget": const KamalaOverviewScreen()},
          {"name": "26. Linked Elderly Profiles", "widget": const LinkedElderlyProfilesScreen()},
          {"name": "27. Caregiver Profile (Nimal)", "widget": const CaregiverProfileScreen()},
        ],
      },
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ElderGuard AI Screens Catalog",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "All 26 Stitch designs with interactive flows",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderLight),

              // Screen List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: flows.length,
                  itemBuilder: (context, fIndex) {
                    final flow = flows[fIndex];
                    final screens = flow["screens"] as List<Map<String, dynamic>>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Text(
                            flow["flow"] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...screens.map((s) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                s["name"] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => s["widget"] as Widget),
                                );
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
